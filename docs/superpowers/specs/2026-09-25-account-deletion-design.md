# Hildors Account and Associated-Data Deletion Design

Date: 2026-09-25

Status: proposed for user review

Target: Hildors backend and mobile App, initial `us_free` release

## 1. Purpose and success criteria

Hildors currently lets an authenticated user request account deletion, lets an operator change the request among review states, and exposes a web request page. It does not delete the account or associated data, and its database check constraint rejects a `deleted` status.

The new subsystem must turn an approved request into a verifiable, retryable deletion across the production database, media files, authentication state, and configured service providers. It must satisfy these outcomes:

1. A user can initiate deletion from the App or the public web resource without reinstalling the App.
2. Cancellation is possible until an operator approves execution. Approval is the irreversible boundary.
3. Approval immediately prevents new authenticated activity and revokes all access and refresh sessions.
4. All data associated with the account is deleted or de-identified unless an explicit, approved retention rule applies.
5. User-generated public content becomes unavailable before physical deletion begins.
6. A crash or provider failure can be retried safely without restoring data or duplicating side effects.
7. Completion is based on verified deletion steps, not an operator selecting a status.
8. The system retains only a minimal, non-identifying completion record and any narrowly approved exception record.
9. The final public policy and Google Play Data safety answers match the implemented behavior.

This design covers source changes and tests. Production deployment, irreversible execution against live user data, public policy publication, and Play submission remain separate operations.

## 2. Selected architecture

Use an asynchronous deletion job with an immutable inventory and idempotent steps. The existing request remains the user-facing intake record. Operator approval creates a deletion job and crosses the irreversible boundary. A worker claims the job using a lease, processes its steps, and derives the final status from their verified results.

A single SQL transaction is insufficient because SQLite changes, filesystem deletion, email delivery, backups, and external providers cannot commit atomically. The job therefore uses a saga-style workflow: each step can be retried, deletion operations treat already-absent data as success, and no compensating action recreates deleted personal data.

## 3. Public and internal states

### 3.1 Request states

The request intake state machine is:

```text
received
  -> in_review
  -> needs_information -> received
  -> approved
  -> cancelled         (only before approved)
```

After `approved`, the user cannot cancel. The API returns a stable public request reference and current public state.

### 3.2 Job states

The internal job state machine is:

```text
queued -> locking -> deleting -> verifying -> completed
                         |             |
                         +-> retry_wait+
                         +-> blocked_by_retention
                         +-> failed_terminal
```

- `retry_wait` is used for recoverable filesystem, email, or provider failures.
- `blocked_by_retention` requires a structured approved exception with a policy code and expiry or review date.
- `failed_terminal` means automated retries are exhausted and requires operator remediation. It is never shown as completed.
- `completed` is set only by the worker after every required step is verified complete or covered by a valid retention exception.

The user sees simplified states: received, under review, deletion in progress, more information required, cancelled, completed, or delayed. Internal error details and provider names are not exposed through the public endpoint.

## 4. Storage model

Replace the current request-only schema with three focused records while preserving existing request IDs during migration.

### 4.1 `account_deletion_requests`

Keep the request record for intake and operator review. Extend its allowed state set and add:

- `approved_at`
- `approved_by`
- `job_id`
- `public_receipt_hash`

Before completion it may reference `users(id)` with `ON DELETE SET NULL`. After completion, `user_id`, free-text messages, and any contact address are cleared. The public receipt is a random high-entropy value returned once to the requester; only its hash is stored.

### 4.2 `account_deletion_jobs`

Store:

- job ID and request ID;
- current internal state and version;
- lease token and lease expiry;
- attempt count and next-attempt time;
- timestamps for approval, lock, start, completion, and last update;
- a keyed subject fingerprint used only to reapply deletions after backup restoration;
- non-sensitive counts of planned, completed, retained, and failed items;
- a bounded machine-readable error code.

The subject fingerprint uses a dedicated deletion-ledger secret and cannot be derived with the email-code secret. Raw email, raw user ID, content text, filenames, and provider payloads are not retained in the completed job.

### 4.3 `account_deletion_items`

Each item identifies one deletion unit by type and opaque internal reference, with state, attempts, lease data, last safe error code, retention policy code, retention expiry/review date, and verification time. Item payloads may temporarily include file IDs or provider references needed for deletion. Successful item payloads are cleared. All remaining item payloads are removed when the backup replay window ends.

The database migration must be transactional, preserve existing requests, and be safe to run more than once. Startup must fail closed if the migration or required deletion-ledger secret is missing in production mode.

## 5. Data inventory

Approval creates an immutable inventory from the same consistent database snapshot used to lock the account. The inventory resolver must cover direct columns and user IDs embedded in JSON documents.

Current known scope:

| Area | Current records or files | Required action |
|---|---|---|
| Authentication | `sessions`, `refresh_sessions` | Delete first and reject future session creation |
| Email identity | `verified_emails`, bound `email_auth_challenges` | Delete; consume outstanding challenges for the address |
| User root | `users` | Delete after dependent records are gone |
| Entitlements | `entitlements` | Delete |
| Creator application | `creator_profiles`, application video references | Remove profile and its application media |
| Creator content | `packages` whose JSON `ownerId` is the user | Immediately withdraw; delete package rows, media and derivatives unless a retention exception applies |
| Package audit | `audit` for deleted creator packages | Delete or convert only to approved non-identifying operational counts |
| Reports | `content_reports` submitted by the user or concerning content deleted with the account | Delete user-authored details; retain only a specifically approved safety/legal record after de-identification |
| Blocks | `creator_blocks` where the user is blocker or the deleted creator is blocked | Delete |
| Customization | `customization_orders` and referenced order materials/deliverables | Delete for `us_free`; a future paid release must apply configured financial/legal exceptions |
| Transactions | `customization_transactions` | No new rows are expected in `us_free`; any existing record requires a configured retention decision before execution |
| Email queue | `order_email_outbox` entries for the user's orders or recipient email | Cancel pending sends and delete recipient data |
| General media | original videos, covers, video previews, cover thumbnails, image previews | Delete files identified by owned package records |
| Creator application media | `media/creator-applications` | Delete original and generated variants |
| Order media | `media/order-materials`, `media/private-deliverables` | Delete originals and generated variants |
| External processors | configured email, hosting, object storage, CDN, support, or other processors | Execute provider adapter or require a documented manual completion item |
| Device-local data | App cache/downloads and compatible display-device files | Explain that the user deletes these locally; do not claim remote deletion without a verified capability |

Before implementation is considered complete, an automated schema/inventory test must fail when a newly introduced table or configured media namespace can contain user data but has no deletion classification.

## 6. Workflow

### 6.1 Request and verification

The App and public webpage keep email OTP verification for request initiation. The response includes the public receipt once, and the user can use it to check status after sessions are revoked. Status lookup reveals only the request reference and public state.

Repeated requests before approval return the active request rather than creating competing jobs. A completed account cannot be recovered by submitting a new request.

### 6.2 Operator review and approval

Add a distinct `account_deletions.execute` permission. Review permission may request information or cancel, but execution permission is required to approve deletion. The approval endpoint requires the current version, an explicit confirmation value, and an idempotency key.

The approval transaction:

1. validates that the request is eligible;
2. creates the job and inventory;
3. marks the account as deletion-locked;
4. withdraws user-owned public content from all read paths;
5. deletes access and refresh sessions; and
6. commits the request as approved and job as queued.

All authenticated write paths and email sign-in must reject deletion-locked accounts. This check must be centralized rather than added independently to individual feature routes.

### 6.3 Worker execution

The worker uses bounded leases so another process can resume abandoned work. It processes in this order:

1. re-verify the account lock and session revocation;
2. stop queued communications and invalidate authentication challenges;
3. remove public visibility and access grants;
4. delete or de-identify safety records according to approved rules;
5. delete external-provider data and verify provider acceptance;
6. delete database child records and JSON-owned records;
7. delete source media and every generated derivative;
8. delete verified email and creator identity data;
9. delete the user root record;
10. verify no live database, media, public endpoint, or configured provider reference remains;
11. expose completed status through the public receipt;
12. attempt a completion notification if a contact address is still temporarily available; and
13. clear the temporary contact address, raw item references, and other personal job payloads regardless of notification outcome.

Completion notification failure does not justify retaining the account. The public receipt remains the authoritative status channel.

### 6.4 Retention exceptions

The implementation does not invent retention periods. Deployment configuration must supply an approved policy registry. Each exception requires:

- policy code and human-readable policy title;
- applicable data categories;
- legal, fraud, security, or regulatory purpose;
- start event and expiry or mandatory review date;
- fields that may be retained and required de-identification;
- deletion method after expiry; and
- approving role and policy version.

Production startup and job approval fail closed if a discovered protected record needs a rule and no active rule exists. Free-launch data has no blanket retention exception. Operator convenience, analytics, product improvement, and an unresolved policy decision are not valid exception reasons.

## 7. Backups and restored data

Online deletion does not rewrite immutable historical backups. The production policy must define backup expiry. Until the oldest relevant backup expires, retain the keyed subject fingerprint and completed job reference in a deletion ledger.

Every restore procedure must run a mandatory replay step before restored services accept traffic. Replay identifies restored subjects using the keyed fingerprint, reapplies deletion, and records verification. The ledger and temporary item metadata are removed after the backup replay window and any approved exception periods end.

Backups must be access-controlled and cannot be used for ordinary account recovery after deletion.

## 8. API and UI changes

### User endpoints

- Existing request, read, and pre-approval cancel endpoints remain compatible.
- The request response adds a one-time public receipt.
- Add a rate-limited public receipt status endpoint that does not require an active account.
- After approval, authenticated endpoints return an account-deletion status response and never silently create a replacement account for the same active deletion identity.

### Operator endpoints

- Review transitions remain separate from execution approval.
- Add approve/execute, retry, and retention-review actions protected by explicit permissions and optimistic versions.
- Remove the ability to mark a request completed directly.
- Show inventory counts, safe error codes, retry time, retention policy codes, and verification results. Do not show deleted payloads.

### App and web UI

- Explain before confirmation that approval is irreversible, sessions will end, public creator content will be removed, and local device files are managed locally.
- Show cancellation only before approval.
- Persist the public receipt for status checking and allow the user to copy it.
- Replace current wording that describes only a reviewed request once the real workflow is deployed.

## 9. Error handling and operations

- Deleting an absent row, file, or provider object is success.
- Unsafe path construction, an unknown media namespace, or an inventory mismatch is a terminal safety error and never triggers broad directory deletion.
- Retries use bounded exponential backoff and safe error codes.
- Operators can retry failed items but cannot skip them. Only a valid retention rule can satisfy an undeleted item.
- Metrics report queue age, jobs by state, retry counts, terminal failures, retained items by policy, and completion duration without user identifiers.
- Structured logs contain job IDs and item types, not emails, content text, original filenames, tokens, or raw provider payloads.
- A dry-run inventory command is available for staging and reports counts only. It cannot mutate data.
- Live approval and worker execution require an explicit production feature flag. Source deployment may occur with execution disabled until policy configuration, backup replay, and operational review are complete.

## 10. Security controls

- Use high-entropy public receipts and store only hashes.
- Rate-limit receipt lookups and return the same response shape for unknown receipts.
- Store the deletion-ledger secret outside the database and rotate it only with a migration plan for active fingerprints.
- Require fresh operator authorization, execute permission, optimistic version, explicit confirmation, and idempotency key for approval.
- Keep user-request verification separate from operator approval.
- Never expose provider payloads or retention evidence through public endpoints.
- Validate every filesystem target against an allowlisted media root and expected UUID/extension before unlinking.

## 11. Test strategy

### Unit tests

- state transitions, cancellation boundary, permission checks, idempotency, lease expiry, backoff, and terminal errors;
- receipt hashing and constant-shape unknown receipt responses;
- retention rule validation and fail-closed behavior;
- inventory classification for every user-data table and media namespace;
- safe path validation and derivative enumeration.

### Integration tests

Create one user with email authentication, both session types, creator profile and application video, owned package and media derivatives, entitlements, reports, blocks, an order and its media, email-queue records, and a simulated provider object. Approve deletion and verify:

- sessions stop working immediately;
- the account cannot sign in or create new data during deletion;
- public creator content disappears before physical deletion;
- every scoped database row and file is removed;
- provider deletion is called and verified;
- repeated execution is harmless;
- the public receipt reaches completed while revealing no personal data; and
- the remaining audit/ledger records contain no raw user identifier, email, content, token, or filename.

Inject a process crash before and after each step and prove another worker resumes correctly. Add provider timeout, permanent rejection, missing file, corrupt inventory, legal-hold, and notification-failure cases.

### Restore and acceptance tests

- restore a backup containing a previously deleted account, run ledger replay before serving traffic, and verify the subject remains deleted;
- run the public web request flow without the App installed;
- run the in-App request flow on a clean Android installation;
- reconcile the observed data inventory with the privacy policy and Google Play Data safety form;
- preserve evidence consisting of version, test environment, job reference, counts, and timestamps without personal payloads.

No test may execute against production user data.

## 12. Rollout gates

Implementation can be merged with production execution disabled. Enabling live deletion requires all of these gates:

1. approved retention and backup-expiry registry;
2. complete production processor register and working deletion adapters or documented manual completion steps;
3. successful database migration rehearsal on a sanitized copy;
4. full automated suite and crash-recovery tests passing;
5. staging end-to-end deletion and backup-restore replay passing;
6. operator permissions and runbook reviewed;
7. final privacy policy and account-deletion page wording approved;
8. Google Play Data safety answers reconciled with the deployed version; and
9. a separate authorized production deployment and activation action.

## 13. Explicitly excluded from this design

- publishing the privacy policy or other Shopify content;
- changing Google Play or App Store declarations;
- creating the final APK/AAB or submitting a release;
- remotely deleting files from a user's phone or Hildors display device;
- defining legal retention periods without company/legal approval;
- adding payments or paid customization; and
- executing deletion against current production accounts during development or testing.
