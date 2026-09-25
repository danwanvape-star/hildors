# Hildors Account Deletion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a disabled-by-default, retryable workflow that deletes a Hildors account and its associated database, media, and configured processor data, while preserving only approved de-identified evidence.

**Architecture:** Operator approval atomically locks the account, revokes sessions, hides public content, and creates an immutable deletion inventory. A leased worker then executes idempotent database, filesystem, provider, retention, and verification items; only verified items can produce `completed`. A hashed public receipt provides post-logout status, and a keyed deletion ledger prevents backup restoration from reviving deleted accounts.

**Tech Stack:** Node.js 24 ESM, `node:sqlite` `DatabaseSync`, Node HTTP server, `node:test`, Flutter/Dart, SQLite, local media storage.

**Spec:** `docs/superpowers/specs/2026-09-25-account-deletion-design.md`

## Global Constraints

- Keep `HILDORS_ACCOUNT_DELETION_EXECUTION=0` as the default; no plan step enables it in production.
- Never run deletion tests against production user data or the production database/media directory.
- Approval is irreversible; cancellation is accepted only before `approved`.
- Completion is derived from verified items and cannot be set directly by an operator.
- Raw email, user ID, filenames, tokens, content, and provider payloads must not remain in completed audit or ledger records.
- Missing policy, unknown media namespace, unsafe path, incomplete inventory, or unconfigured processor must fail closed.
- Existing request IDs and pre-approval request behavior must survive schema migration.
- Do not publish Shopify content, change store declarations, build a release AAB, or deploy production services in this plan.
- Exact legal retention periods are inputs in an approved policy file; source code must not invent them.

## Review Focus

- A second request races operator approval: exactly one job is created, cancellation loses after approval, and no session remains valid.
- A worker crashes after deleting a file but before recording success: retry treats the absent file as success and reaches verification.
- A new user-data table or media namespace appears: the inventory coverage test fails until it receives a deletion classification.
- An expired lease is reclaimed while a stale worker reports success: token-guarded updates reject the stale worker.
- A backup containing a completed subject is restored: replay re-locks and deletes the subject before the server becomes ready.

---

## File map

| File | Responsibility |
|---|---|
| `backend/src/account-deletion-schema.mjs` | Idempotent migration for requests, jobs, items, account locks, and deletion ledger |
| `backend/src/account-deletion-policy.mjs` | Parse and validate approved retention rules and processor declarations |
| `backend/src/account-deletion-inventory.mjs` | Enumerate every database, media, and processor deletion item for one user |
| `backend/src/account-deletion-dry-run.mjs` | Count-only sanitized inventory command for staging rehearsal |
| `backend/src/account-deletion-media.mjs` | Allowlisted media-path expansion, deletion, and verification |
| `backend/src/account-deletion-providers.mjs` | Provider adapter contract and required/manual processor items |
| `backend/src/account-deletion-worker.mjs` | Lease jobs/items, execute idempotent steps, verify, retry, and complete |
| `backend/src/account-deletion.mjs` | Request, receipt, review, approval, retry, retention-review, and HTTP routes |
| `backend/src/store.mjs` | Compose deletion operations and enforce the central account lock |
| `backend/src/runtime-config.mjs` | Disabled-by-default execution, secret file, policy file, and worker interval |
| `backend/src/server.mjs` | Inject deletion dependencies, start/stop worker, readiness and restore gate |
| `backend/src/operators.mjs` | Separate review, execute, and retry permissions |
| `backend/public/account-deletion.*` | Public receipt/status flow and truthful deployed wording |
| `backend/public/account-deletions-admin.*` | Operator approval, retry, and retained-item review controls |
| `lib/src/features/profile/account_deletion_service.dart` | Focused App API and local receipt storage for deletion status after logout |
| `lib/src/features/profile/account_deletion_page.dart` | In-App irreversible-boundary copy, receipt status, and cancellation UI |
| `backend/test/account-deletion-*.test.mjs` | Migration, inventory, worker, media, provider, restore, HTTP, and crash tests |
| `test/account_deletion_page_test.dart` | Mobile state and copy tests |

### Task 1: Runtime configuration and idempotent schema migration

**Files:**
- Create: `backend/src/account-deletion-schema.mjs`
- Create: `backend/src/account-deletion-policy.mjs`
- Create: `backend/test/account-deletion-schema.test.mjs`
- Modify: `backend/src/runtime-config.mjs`
- Modify: `backend/test/runtime-config.test.mjs`
- Modify: `backend/src/store.mjs`

**Interfaces:**
- Produces: `migrateAccountDeletion(db): void`
- Produces: `loadDeletionPolicy(path): DeletionPolicy`
- Produces: `runtimeConfig(...).accountDeletion = { executionEnabled, ledgerSecret, policy, intervalMs }`
- Consumes: existing `createStore(path, options)` and `runtimeConfig(env, defaultDirectory)`

- [ ] **Step 1: Write failing migration and configuration tests**

```js
test('migration preserves a legacy request and adds deletion tables idempotently', () => {
  const store = createLegacyDeletionDatabase(file);
  migrateAccountDeletion(store.db); migrateAccountDeletion(store.db);
  assert.equal(store.db.prepare('SELECT id,status FROM account_deletion_requests').get().id, 'request-1');
  for (const name of ['account_deletion_jobs','account_deletion_items','account_deletion_locks','account_deletion_ledger'])
    assert.ok(store.db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?").get(name));
});

test('execution defaults off and enabled staging requires secret and policy files', () => {
  assert.equal(runtimeConfig({}, directory).accountDeletion.executionEnabled, false);
  assert.throws(() => runtimeConfig({...staging,HILDORS_ACCOUNT_DELETION_EXECUTION:'1'}, directory), /deletion ledger secret/i);
  assert.throws(() => runtimeConfig({...staging,HILDORS_ACCOUNT_DELETION_EXECUTION:'1',
    HILDORS_DELETION_LEDGER_SECRET_FILE:secretFile}, directory), /retention policy/i);
});
```

- [ ] **Step 2: Run the focused tests and verify the new interfaces are absent**

Run: `cd backend && node --test test/account-deletion-schema.test.mjs test/runtime-config.test.mjs`

Expected: FAIL because `account-deletion-schema.mjs` and `accountDeletion` runtime configuration do not exist.

- [ ] **Step 3: Implement schema and strict policy parsing**

Use these exact tables and status checks in `migrateAccountDeletion`:

```sql
CREATE TABLE IF NOT EXISTS account_deletion_jobs (
  id TEXT PRIMARY KEY, request_id TEXT NOT NULL UNIQUE,
  state TEXT NOT NULL CHECK(state IN ('queued','locking','deleting','verifying','retry_wait','blocked_by_retention','failed_terminal','completed')),
  version INTEGER NOT NULL, lease_token TEXT, lease_until INTEGER,
  attempts INTEGER NOT NULL DEFAULT 0, next_attempt_at INTEGER NOT NULL,
  subject_fingerprint TEXT NOT NULL, planned_count INTEGER NOT NULL DEFAULT 0,
  completed_count INTEGER NOT NULL DEFAULT 0, retained_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0, error_code TEXT NOT NULL DEFAULT '',
  approved_at TEXT NOT NULL, locked_at TEXT, started_at TEXT, completed_at TEXT, updated_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS account_deletion_items (
  id TEXT PRIMARY KEY, job_id TEXT NOT NULL REFERENCES account_deletion_jobs(id),
  kind TEXT NOT NULL, opaque_reference TEXT NOT NULL, payload TEXT NOT NULL,
  state TEXT NOT NULL CHECK(state IN ('pending','running','retry_wait','retained','failed_terminal','completed')),
  attempts INTEGER NOT NULL DEFAULT 0, lease_token TEXT, lease_until INTEGER,
  next_attempt_at INTEGER NOT NULL, error_code TEXT NOT NULL DEFAULT '',
  policy_code TEXT, retention_until TEXT, verified_at TEXT, updated_at TEXT NOT NULL,
  UNIQUE(job_id,kind,opaque_reference));
CREATE TABLE IF NOT EXISTS account_deletion_locks (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  request_id TEXT NOT NULL UNIQUE, locked_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS account_deletion_ledger (
  request_id TEXT PRIMARY KEY, subject_fingerprint TEXT NOT NULL UNIQUE,
  backup_replay_until TEXT NOT NULL, completed_at TEXT NOT NULL, replayed_at TEXT);
```

Rebuild the legacy request table inside a transaction so `user_id` is nullable with `ON DELETE SET NULL`, and add `approved_at`, `approved_by`, `job_id`, and `public_receipt_hash`. Validate policy JSON as `{version,effectiveAt,backupReplayDays,rules,processors}`; reject unknown keys, non-positive durations, missing processor deletion modes, and duplicate codes.

- [ ] **Step 4: Add exact runtime variables and fail-closed checks**

```js
const deletionEnabled = env.HILDORS_ACCOUNT_DELETION_EXECUTION === '1';
if (!['0','1'].includes(env.HILDORS_ACCOUNT_DELETION_EXECUTION ?? '0')) throw new Error('Invalid account deletion execution flag');
const ledgerSecret = deletionEnabled ? readSecret(env.HILDORS_DELETION_LEDGER_SECRET_FILE, 32, 'deletion ledger secret') : '';
const policy = deletionEnabled ? loadDeletionPolicy(env.HILDORS_RETENTION_POLICY_FILE) : null;
const intervalMs = parseBoundedInteger(env.HILDORS_ACCOUNT_DELETION_INTERVAL_MS ?? '30000', 1000, 300000);
```

Pass `{deletionLedgerSecret}` into `createStore` only when execution is enabled. Call `migrateAccountDeletion(db)` before composing deletion operations.

- [ ] **Step 5: Run focused and full backend tests**

Run: `cd backend && node --test test/account-deletion-schema.test.mjs test/runtime-config.test.mjs`

Expected: PASS.

Run: `cd backend && npm test`

Expected: all backend tests PASS.

- [ ] **Step 6: Commit the migration boundary**

```bash
git add backend/src/account-deletion-schema.mjs backend/src/account-deletion-policy.mjs backend/src/runtime-config.mjs backend/src/store.mjs backend/test/account-deletion-schema.test.mjs backend/test/runtime-config.test.mjs
git commit -m "Add deletion workflow schema and configuration"
```

### Task 2: Approval boundary, public receipt, permissions, and central account lock

**Files:**
- Modify: `backend/src/account-deletion.mjs`
- Modify: `backend/src/store.mjs`
- Modify: `backend/src/email-identity.mjs`
- Modify: `backend/src/operators.mjs`
- Modify: `backend/test/account-deletion.test.mjs`
- Modify: `backend/test/operator-live-permissions.test.mjs`
- Modify: `backend/test/unified-us-permissions.test.mjs`

**Interfaces:**
- Consumes: migrated deletion tables and `deletionLedgerSecret`
- Produces: `approveAccountDeletion(id, value, actor): {request,job}`
- Produces: `accountDeletionStatusByReceipt(receipt): PublicDeletionStatus|null`
- Produces: `assertAccountActive(userId): void`
- Produces: operator permissions `account_deletions.execute` and `account_deletions.retry`

- [ ] **Step 1: Extend tests around the irreversible boundary**

```js
test('approval creates one job, locks account, revokes sessions and defeats racing cancel', () => {
  const request = store.requestAccountDeletion(user,{confirm:true});
  const approved = store.approveAccountDeletion(request.id,{version:request.version,confirm:'DELETE',idempotencyKey:'approval-1'},executor);
  assert.equal(approved.request.status,'approved');
  assert.equal(store.authenticate(accessToken),null);
  assert.equal(store.refreshDeviceSession(refreshToken),null);
  assert.throws(() => store.cancelAccountDeletion(user,{version:approved.request.version}),/DELETION_CONFLICT/);
  assert.equal(store.approveAccountDeletion(request.id,{version:request.version,confirm:'DELETE',idempotencyKey:'approval-1'},executor).job.id,approved.job.id);
});

test('receipt lookup has constant public shape and stores only a hash', () => {
  const {request,receipt}=store.requestAccountDeletion(user,{confirm:true});
  assert.match(receipt,/^[A-Za-z0-9_-]{43}$/);
  assert.deepEqual(Object.keys(store.accountDeletionStatusByReceipt(receipt)).sort(),['reference','status','updatedAt']);
  assert.equal(store.accountDeletionStatusByReceipt('A'.repeat(43)),null);
  const stored=db.prepare('SELECT public_receipt_hash FROM account_deletion_requests WHERE id=?').get(request.id);
  assert.notEqual(stored.public_receipt_hash,receipt);
});
```

Add permission tests that review-only operators receive 403 for approval/retry and execute operators can approve.

- [ ] **Step 2: Run the focused tests and observe approval/receipt failures**

Run: `cd backend && node --test test/account-deletion.test.mjs test/operator-live-permissions.test.mjs test/unified-us-permissions.test.mjs`

Expected: FAIL on missing receipt, approval, lock, and permission interfaces.

- [ ] **Step 3: Implement request receipt and approval transaction**

Generate the receipt with `randomBytes(32).toString('base64url')`, persist `sha256(receipt)`, and return it only from initial request creation. Approval must use one database savepoint to:

```js
assertApprovalInput(value);
const fingerprint = createHmac('sha256', deletionLedgerSecret).update(`user:${row.user_id}`).digest('hex');
insertJobAndInventoryShell({requestId:id,userId:row.user_id,fingerprint,now});
db.prepare('INSERT INTO account_deletion_locks VALUES (?,?,?)').run(row.user_id,id,nowIso);
db.prepare('DELETE FROM refresh_sessions WHERE user_id=?').run(row.user_id);
db.prepare('DELETE FROM sessions WHERE user_id=?').run(row.user_id);
withdrawOwnedPackages(row.user_id, nowIso);
markRequestApproved(id, value.version, actor.id, jobId, nowIso);
```

Store approval idempotency on the job. The same key returns the same job; a different key or stale version returns `DELETION_CONFLICT`.

- [ ] **Step 4: Centralize lock enforcement**

Implement `assertAccountActive(userId)` in the store and call it from `createSession`, `createDeviceSession`, `refreshDeviceSession`, verified-email completion, and the authenticated request gateway in `server.mjs`. Locked accounts return `ACCOUNT_DELETION_IN_PROGRESS`. Read-only deletion-status endpoints bypass this guard.

- [ ] **Step 5: Run focused and full backend tests**

Run: `cd backend && node --test test/account-deletion.test.mjs test/operator-live-permissions.test.mjs test/unified-us-permissions.test.mjs`

Expected: PASS, including the race test in Review Focus.

Run: `cd backend && npm test`

Expected: all backend tests PASS.

- [ ] **Step 6: Commit the approval boundary**

```bash
git add backend/src/account-deletion.mjs backend/src/store.mjs backend/src/email-identity.mjs backend/src/operators.mjs backend/test/account-deletion.test.mjs backend/test/operator-live-permissions.test.mjs backend/test/unified-us-permissions.test.mjs
git commit -m "Lock accounts when deletion is approved"
```

### Task 3: Complete and testable deletion inventory

**Files:**
- Create: `backend/src/account-deletion-inventory.mjs`
- Create: `backend/src/account-deletion-dry-run.mjs`
- Create: `backend/test/account-deletion-inventory.test.mjs`
- Modify: `backend/src/account-deletion.mjs`
- Modify: `backend/src/store.mjs`

**Interfaces:**
- Consumes: SQLite database and one locked `userId`
- Produces: `buildDeletionInventory(db, userId, policy): DeletionItemInput[]`
- Produces: `assertDeletionCoverage(db): void`
- Produces: `runDeletionDryRun({db,userId,policy}): {itemCounts,retentionCounts,unclassifiedCount}`
- Produces item shape: `{kind,opaqueReference,payload,policyCode:null|string,retentionUntil:null|string}`

- [ ] **Step 1: Write a full user-graph inventory test**

Seed sessions, refresh sessions, verified email, auth challenges, entitlements, creator profile/application video, owned package/cover/clips, package audit, reports, blocks, customization order/materials/deliverable, transaction, and email outbox. Assert exact item kinds and that raw email and user ID do not appear in `opaqueReference`.

```js
const kinds = buildDeletionInventory(db,user,policy).map(x=>x.kind).sort();
assert.deepEqual(kinds, [
  'auth_challenges','creator_application_media','creator_blocks','creator_profile','customization_order',
  'customization_transaction','email_outbox','entitlements','general_media','owned_package','package_audit',
  'private_deliverable','reports','sessions','user_root','verified_email'
].sort());
for (const item of buildDeletionInventory(db,user,policy)) {
  assert.doesNotMatch(item.opaqueReference,new RegExp(user));
  assert.doesNotMatch(item.opaqueReference,/owner@example\.com/);
}
```

Add a coverage test that creates `unclassified_user_data(user_id TEXT)` and expects `assertDeletionCoverage(db)` to throw `DELETION_INVENTORY_UNCLASSIFIED_TABLE`.

- [ ] **Step 2: Run the inventory test and verify it fails**

Run: `cd backend && node --test test/account-deletion-inventory.test.mjs`

Expected: FAIL because the inventory module is missing.

- [ ] **Step 3: Implement explicit classifiers**

Define a frozen classification map for every current table that contains a direct user relation or approved embedded JSON relation. Query JSON ownership with `json_extract(document,'$.ownerId')`, order media fields, creator application videos, cover/media IDs, and generated variants. Use HMAC-based opaque references scoped to job and kind; keep raw deletion coordinates only in the encrypted-at-rest or locally protected temporary `payload` field.

`assertDeletionCoverage` must inspect `PRAGMA foreign_key_list`, table columns ending in `user_id`, and the explicit embedded-JSON allowlist. Its test fixture proves new direct user tables fail the build.

- [ ] **Step 4: Insert inventory during approval and reject empty/unknown results safely**

Call `buildDeletionInventory` inside the approval savepoint, insert items with `INSERT OR IGNORE`, and set `planned_count` from the inserted rows. A valid account may have only authentication items, but an inventory missing `sessions`, `verified_email` when present, or a user-root finalizer is `DELETION_INVENTORY_INCOMPLETE`.

Implement `account-deletion-dry-run.mjs` as a count-only CLI that requires an explicit SQLite path, user ID, and policy path, calls `assertDeletionCoverage`, and prints only JSON counts grouped by item kind and retention code. It must never print payloads, IDs, emails, filenames, or content and must open the database read-only.

- [ ] **Step 5: Run focused and full backend tests**

Run: `cd backend && node --test test/account-deletion-inventory.test.mjs test/account-deletion.test.mjs`

Expected: PASS.

Run: `cd backend && npm test`

Expected: all backend tests PASS.

- [ ] **Step 6: Commit inventory coverage**

```bash
git add backend/src/account-deletion-inventory.mjs backend/src/account-deletion-dry-run.mjs backend/src/account-deletion.mjs backend/src/store.mjs backend/test/account-deletion-inventory.test.mjs backend/test/account-deletion.test.mjs
git commit -m "Inventory all account deletion data"
```

### Task 4: Leased, idempotent database deletion worker

**Files:**
- Create: `backend/src/account-deletion-worker.mjs`
- Create: `backend/test/account-deletion-worker.test.mjs`
- Modify: `backend/src/account-deletion.mjs`
- Modify: `backend/src/store.mjs`

**Interfaces:**
- Consumes: inventory items from Task 3
- Produces: `createDeletionWorker({store,mediaDirectory,providers,policy,now,leaseMs}): DeletionWorker`
- Produces: `DeletionWorker.runOnce(): Promise<{claimed:boolean,jobId?:string,state?:string}>`
- Produces: store methods `claimDeletionJob`, `claimDeletionItem`, `completeDeletionItem`, `failDeletionItem`, `verifyDeletionJob`

- [ ] **Step 1: Write lease, crash, retry, and stale-worker tests**

```js
test('expired work resumes and stale lease cannot complete an item', async () => {
  const first=store.claimDeletionItem(job,1000,now);
  clock.advance(1001);
  const second=store.claimDeletionItem(job,1000,clock.now());
  assert.notEqual(second.leaseToken,first.leaseToken);
  assert.equal(store.completeDeletionItem(first.id,first.leaseToken,clock.now()),false);
  assert.equal(store.completeDeletionItem(second.id,second.leaseToken,clock.now()),true);
});

test('database deletion is idempotent after crash before success record', async () => {
  await executor.execute(item);
  await assert.rejects(()=>executor.simulateCrashBeforeRecord(item),/SIMULATED_CRASH/);
  assert.equal((await executor.execute(item)).status,'completed');
});
```

- [ ] **Step 2: Run the worker test and verify missing worker failures**

Run: `cd backend && node --test test/account-deletion-worker.test.mjs`

Expected: FAIL because worker and lease methods do not exist.

- [ ] **Step 3: Implement lease-guarded claims and retry schedule**

Use `UPDATE ... RETURNING` inside `BEGIN IMMEDIATE` for job and item claims. Every mutation includes `WHERE lease_token=? AND state='running'`. Use delays `[60000,300000,1800000,3600000]`; after the fifth failure mark `failed_terminal`. Error codes are from an allowlist: `TRANSIENT_IO`, `PROVIDER_UNAVAILABLE`, `POLICY_BLOCKED`, `INVENTORY_MISMATCH`, `UNSAFE_PATH`, `UNCLASSIFIED_DATA`.

- [ ] **Step 4: Implement FK-safe database executors**

Delete in this order: queued email, challenges, blocks, reports, entitlements, transactions, order rows, package audits, owned packages, creator profile, verified email, sessions, refresh sessions, then `users`. Each executor verifies absence using the same selector that built the item. `SQLITE_CONSTRAINT` becomes `INVENTORY_MISMATCH`, not a broad retry.

When all non-media items are complete or validly retained, set the job to `verifying`; `verifyDeletionJob` reruns all selectors and refuses completion while any live reference remains.

- [ ] **Step 5: Run crash-boundary and full backend tests**

Run: `cd backend && node --test test/account-deletion-worker.test.mjs`

Expected: PASS, including stale-lease and crash tests from Review Focus.

Run: `cd backend && npm test`

Expected: all backend tests PASS.

- [ ] **Step 6: Commit the database worker**

```bash
git add backend/src/account-deletion-worker.mjs backend/src/account-deletion.mjs backend/src/store.mjs backend/test/account-deletion-worker.test.mjs
git commit -m "Execute account deletion jobs safely"
```

### Task 5: Allowlisted media deletion and derivative verification

**Files:**
- Create: `backend/src/account-deletion-media.mjs`
- Create: `backend/test/account-deletion-media.test.mjs`
- Modify: `backend/src/account-deletion-worker.mjs`

**Interfaces:**
- Consumes: `{namespace,id,extension}` media payloads and `mediaDirectory`
- Produces: `mediaTargets(mediaDirectory,payload): string[]`
- Produces: `deleteMediaItem(mediaDirectory,payload): Promise<{deleted:number,absent:number}>`
- Produces: `verifyMediaItem(mediaDirectory,payload): Promise<boolean>`

- [ ] **Step 1: Write namespace and traversal tests**

```js
for (const payload of [
  {namespace:'general',id:'../escape',extension:'mp4'},
  {namespace:'unknown',id:uuid,extension:'mp4'},
  {namespace:'order-materials',id:uuid,extension:'../../db'}
]) assert.throws(()=>mediaTargets(root,payload),/UNSAFE_PATH|UNKNOWN_MEDIA_NAMESPACE/);

test('retry after file removal treats absence as success and removes derivatives', async () => {
  await seedGeneralVideoAndPreviews(root,uuid);
  await deleteMediaItem(root,{namespace:'general',id:uuid,extension:'mp4'});
  const again=await deleteMediaItem(root,{namespace:'general',id:uuid,extension:'mp4'});
  assert.equal(again.deleted,0); assert.equal(await verifyMediaItem(root,payload),true);
});
```

- [ ] **Step 2: Run the media test and verify it fails**

Run: `cd backend && node --test test/account-deletion-media.test.mjs`

Expected: FAIL because the media module is missing.

- [ ] **Step 3: Implement exact namespace expansion**

Allow only:

```js
const namespaces = Object.freeze({
  general: ['', 'video-previews-v1', 'cover-thumbnails', 'image-previews'],
  'creator-applications': ['creator-applications'],
  'order-materials': ['order-materials'],
  'private-deliverables': ['private-deliverables'],
});
```

Require UUID IDs, an extension allowlist `mp4,jpg,png,webp,heic,heif`, and `relative(root,target)` that neither starts with `..` nor is absolute. Use `lstat` and refuse symlinks. Delete explicit filenames only; never recursively delete a directory.

- [ ] **Step 4: Connect media items to the worker**

Map `general_media`, `creator_application_media`, `order_material`, and `private_deliverable` item kinds to `deleteMediaItem`. A missing file completes the item. Unsafe or unknown targets become terminal safety errors.

- [ ] **Step 5: Run media, worker, and full backend tests**

Run: `cd backend && node --test test/account-deletion-media.test.mjs test/account-deletion-worker.test.mjs`

Expected: PASS.

Run: `cd backend && npm test`

Expected: all backend tests PASS.

- [ ] **Step 6: Commit media deletion**

```bash
git add backend/src/account-deletion-media.mjs backend/src/account-deletion-worker.mjs backend/test/account-deletion-media.test.mjs backend/test/account-deletion-worker.test.mjs
git commit -m "Delete account media with safe paths"
```

### Task 6: Processor deletion, retention exceptions, and backup replay

**Files:**
- Create: `backend/src/account-deletion-providers.mjs`
- Create: `backend/src/account-deletion-replay.mjs`
- Create: `backend/test/account-deletion-providers.test.mjs`
- Create: `backend/test/account-deletion-replay.test.mjs`
- Modify: `backend/src/account-deletion-worker.mjs`
- Modify: `backend/src/account-deletion-policy.mjs`
- Modify: `backend/src/server.mjs`

**Interfaces:**
- Produces: provider adapter `{id,deleteSubject(reference),verifySubjectAbsent(reference)}`
- Produces: `sendDeletionCompletion({to,reference}): Promise<void>` injected from the configured mail transport
- Produces: `createProviderRegistry(policy, adapters): ProviderRegistry`
- Produces: `replayDeletionLedger({store,policy}): {checked,redeleted,failed}`
- Consumes: policy rules and subject fingerprints from Tasks 1 and 2

- [ ] **Step 1: Write provider, exception-expiry, and restore tests**

```js
test('declared processor without adapter blocks completion', async () => {
  const registry=createProviderRegistry(policyWithRequiredEmailProcessor,[]);
  await assert.rejects(()=>registry.delete('email',reference),/PROCESSOR_NOT_CONFIGURED/);
});

test('retained item needs active matching rule and is deleted after expiry', async () => {
  assert.throws(()=>store.retainDeletionItem(item,{policyCode:'missing'}),/POLICY_BLOCKED/);
  store.retainDeletionItem(item,{policyCode:'security-30d'});
  clock.advance(days(31));
  assert.equal(store.claimExpiredRetentionItem(clock.now()).id,item.id);
});

test('restore replay deletes a completed subject before readiness', async () => {
  restoreFixtureWithCompletedUser();
  const result=await replayDeletionLedger({store,policy});
  assert.equal(result.failed,0); assert.equal(result.redeleted,1); assert.equal(findRestoredSubject(),null);
});
```

- [ ] **Step 2: Run provider and replay tests and verify they fail**

Run: `cd backend && node --test test/account-deletion-providers.test.mjs test/account-deletion-replay.test.mjs`

Expected: FAIL because provider and replay modules are missing.

- [ ] **Step 3: Implement provider registry and manual completion evidence**

Every processor entry in policy has `mode: 'adapter'|'manual'`. Adapter mode requires both deletion and verification methods. Manual mode creates an operator item that requires `processorRequestReference`, `confirmedAt`, `confirmedBy`, and a non-empty `evidenceHash`; it never accepts a raw screenshot or personal payload in SQLite.

Create one `completion_notification` item when a verified email exists. Attempt it after local account/media deletion verifies but before deleting the email-processor subject. A permanent or exhausted notification failure records the safe outcome `notification_failed` and does not retain or recreate the account; the receipt remains authoritative. After the attempt, process the email-provider deletion item and clear the temporary contact address whether delivery succeeded or failed.

- [ ] **Step 4: Implement strict retention transitions**

Match an item only when policy code, item kind, purpose, fields, and effective date agree. Compute expiry from the rule's start event and duration. Expired items return to `pending`; they cannot remain `retained`. Completion may include retained items only while every rule is active and carries a future expiry or review date.

- [ ] **Step 5: Implement ledger completion and restore gate**

On verified completion, insert `{request_id,subject_fingerprint,backup_replay_until,completed_at}` and clear user ID, contact, free text, and item payloads. `server.mjs` must call `replayDeletionLedger` before `/ready` returns 200 whenever execution is enabled. Any replay failure keeps readiness at 503 and prevents traffic startup.

- [ ] **Step 6: Run focused and full backend tests**

Run: `cd backend && node --test test/account-deletion-providers.test.mjs test/account-deletion-replay.test.mjs test/account-deletion-worker.test.mjs`

Expected: PASS.

Run: `cd backend && npm test`

Expected: all backend tests PASS.

- [ ] **Step 7: Commit provider, retention, and replay behavior**

```bash
git add backend/src/account-deletion-providers.mjs backend/src/account-deletion-replay.mjs backend/src/account-deletion-policy.mjs backend/src/account-deletion-worker.mjs backend/src/server.mjs backend/test/account-deletion-providers.test.mjs backend/test/account-deletion-replay.test.mjs backend/test/account-deletion-worker.test.mjs
git commit -m "Verify processor deletion and backup replay"
```

### Task 7: HTTP routes, background worker, and web/operator UI

**Files:**
- Modify: `backend/src/account-deletion.mjs`
- Modify: `backend/src/server.mjs`
- Modify: `backend/public/account-deletion.html`
- Modify: `backend/public/account-deletion.js`
- Modify: `backend/public/account-deletion.css`
- Modify: `backend/public/account-deletions-admin.html`
- Modify: `backend/public/account-deletions-admin.js`
- Modify: `backend/test/account-deletion.test.mjs`
- Create: `backend/test/account-deletion-http.test.mjs`

**Interfaces:**
- Adds: `GET /account-deletion/status?receipt=...`
- Adds: `POST /admin/account-deletions/:id/approve`
- Adds: `POST /admin/account-deletions/:id/retry`
- Adds: `POST /admin/account-deletions/:id/retention`
- Consumes: worker, receipt, permission, and policy interfaces from Tasks 1–6

- [ ] **Step 1: Write HTTP security and behavior tests**

Test rate limiting, constant-shaped unknown receipt responses, review-only 403, execute permission, stale versions, idempotency keys, cancellation boundary, CSP, truthful wording, and worker shutdown.

```js
const unknown=await fetch(base+'/account-deletion/status?receipt='+unknownReceipt);
const known=await fetch(base+'/account-deletion/status?receipt='+receipt);
assert.deepEqual(Object.keys(await unknown.json()),Object.keys(await known.json()));
assert.equal((await approveAs(reviewOnly)).status,403);
assert.equal((await approveAs(executor)).status,200);
assert.equal((await cancelAsUser()).status,409);
```

- [ ] **Step 2: Run HTTP tests and verify missing-route failures**

Run: `cd backend && node --test test/account-deletion.test.mjs test/account-deletion-http.test.mjs`

Expected: FAIL on missing receipt/approval/retry/retention routes.

- [ ] **Step 3: Implement endpoints and rate limits**

Use the existing JSON body limit and post-read authorization recheck. Receipt lookup accepts exactly 43 base64url characters, hashes before lookup, and returns `{reference:null,status:'not_found',updatedAt:null}` for unknown values. Rate-limit by bounded proxy-resolved IP and receipt hash without logging either raw value.

- [ ] **Step 4: Run the worker only behind the feature flag**

Create one non-overlapping `runOnce` loop using the configured interval. Catch errors as `ACCOUNT_DELETION_WORKER_FAILED` without payloads. On SIGINT/SIGTERM, stop the timer, await active deletion work, await email work, close the server, then close the store.

- [ ] **Step 5: Update web and operator pages**

Public copy must state that approval is irreversible, active sessions end, associated cloud data is deleted subject to disclosed exceptions, and phone/display-device files remain local. Store the public receipt in the page's session storage, provide a copy button, and show cancellation only before approval.

The operator page separates review from execute, requires typing `DELETE`, supplies an idempotency key, and shows safe counts, policy codes, retry times, and verification state. It has no direct `completed` control.

- [ ] **Step 6: Run focused and full backend tests**

Run: `cd backend && node --test test/account-deletion.test.mjs test/account-deletion-http.test.mjs`

Expected: PASS.

Run: `cd backend && npm test`

Expected: all backend tests PASS.

- [ ] **Step 7: Commit HTTP and web flows**

```bash
git add backend/src/account-deletion.mjs backend/src/server.mjs backend/public/account-deletion.html backend/public/account-deletion.js backend/public/account-deletion.css backend/public/account-deletions-admin.html backend/public/account-deletions-admin.js backend/test/account-deletion.test.mjs backend/test/account-deletion-http.test.mjs
git commit -m "Expose verifiable account deletion status"
```

### Task 8: Mobile deletion receipt and post-lock experience

**Files:**
- Create: `lib/src/features/profile/account_deletion_service.dart`
- Modify: `lib/src/features/profile/account_deletion_page.dart`
- Modify: `lib/src/features/customization/cloud_business_intake.dart`
- Create: `lib/l10n/fragments/account_deletion_en.json`
- Create: `lib/l10n/fragments/account_deletion_zh.json`
- Regenerate: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_zh.arb`
- Regenerate: `lib/l10n/generated/app_localizations.dart`
- Regenerate: `lib/l10n/generated/app_localizations_en.dart`
- Regenerate: `lib/l10n/generated/app_localizations_zh.dart`
- Create: `test/account_deletion_page_test.dart`

**Interfaces:**
- Consumes: request response `{request,receipt?}` and receipt status endpoint
- Produces: `AccountDeletionService` and `CloudAccountDeletionService`
- Produces: locally persisted `deletionReceipt` and status polling independent of authenticated session
- Preserves: cancellation only for received/in-review/needs-information states

- [ ] **Step 1: Write widget tests for receipt and irreversible states**

```dart
testWidgets('approval state hides cancel and continues status by receipt after logout',(tester) async {
  final service=FakeAccountDeletionService(status:'deleting',receipt:List.filled(43,'A').join());
  await tester.pumpWidget(testApp(AccountDeletionPage(service:service)));
  expect(find.text('Deletion in progress'),findOneWidget);
  expect(find.text('Cancel request'),findNothing);
  expect(service.authenticatedStatusCalls,0);
  expect(service.receiptStatusCalls,1);
});
```

Add tests for copy, local-file warning, cancellation before approval, unknown/expired receipt, network retry, and `ACCOUNT_DELETION_IN_PROGRESS` from unrelated authenticated calls.

- [ ] **Step 2: Run the widget test and verify missing UI behavior**

Run: `flutter test --no-pub test/account_deletion_page_test.dart`

Expected: FAIL because receipt persistence and deleting/completed states are absent.

- [ ] **Step 3: Implement the focused service, receipt persistence, and public-status polling**

Define `AccountDeletionService` with `load()`, `submit()`, `cancel(version)`, `refreshByReceipt()`, and `clearAuthenticatedSessionKeepingReceipt()` methods. `CloudAccountDeletionService` delegates authenticated calls to `CloudBusinessIntake`, stores the 43-character receipt in `account_deletion_receipt.json` under application support, and calls a new `CloudBusinessIntake.clearSessionForApprovedDeletion()` method that removes access/refresh credentials without deleting the receipt. Never log the receipt. Prefer receipt status whenever present, bound automatic polling to one request on page load, and expose manual refresh.

- [ ] **Step 4: Replace provisional copy and regenerate localization**

English and Chinese copy must cover the irreversible boundary, cloud deletion, disclosed exceptions, local phone/display files, receipt recovery, delayed state, and support contact. Run `python3 tool/merge_l10n.py` followed by `flutter gen-l10n` so generated files match the reviewed fragments.

- [ ] **Step 5: Run focused analysis and tests**

Run: `flutter analyze --no-pub`

Expected: `No issues found!`

Run: `flutter test --no-pub test/account_deletion_page_test.dart test/widget_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit the mobile flow**

```bash
git add lib/src/features/profile/account_deletion_service.dart lib/src/features/profile/account_deletion_page.dart lib/src/features/customization/cloud_business_intake.dart lib/l10n/fragments/account_deletion_en.json lib/l10n/fragments/account_deletion_zh.json lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_en.dart lib/l10n/generated/app_localizations_zh.dart test/account_deletion_page_test.dart
git commit -m "Track account deletion after logout"
```

### Task 9: Full deletion acceptance, documentation, and release gate

**Files:**
- Create: `backend/test/account-deletion-e2e.test.mjs`
- Create: `backend/docs/account-deletion-runbook.md`
- Modify: `backend/UNIFIED-RELEASE.md`
- Modify: `docs/customization_data_map_and_retention.md`
- Modify: `docs/superpowers/specs/2026-09-25-account-deletion-design.md` only if implementation details expose a verified contradiction

**Interfaces:**
- Consumes: all Tasks 1–8
- Produces: a repeatable sanitized acceptance fixture and operator runbook

- [ ] **Step 1: Build the end-to-end sanitized fixture**

Create an isolated temporary database/media tree with one complete user graph and a fake required processor. Exercise web request, operator review/approval, immediate session revocation, public withdrawal, worker crashes before and after every item class, retries, provider verification, database/media absence, completion receipt, and backup replay.

- [ ] **Step 2: Run the end-to-end test and fix only integration defects**

Run: `cd backend && node --test test/account-deletion-e2e.test.mjs`

Expected: PASS. Any failure must be fixed in the owning module with a focused regression test before rerunning E2E.

- [ ] **Step 3: Write the disabled-by-default operations runbook**

Document exact environment variables, sanitized migration rehearsal, policy validation, processor adapter verification, dry-run inventory, feature-flag activation, queue/failed-item monitoring, manual evidence hashing, retention review, backup replay, emergency disablement, and the rule that operators cannot mark completion directly.

- [ ] **Step 4: Run the complete verification set**

Run: `cd backend && npm test`

Expected: all backend tests PASS.

Run: `flutter analyze --no-pub`

Expected: `No issues found!`

Run: `HILDORS_RELEASE_PROFILE=us_free flutter test --no-pub --concurrency=1`

Expected: all applicable Flutter tests PASS; environment-gated skips must be listed with their names and reasons.

Run: `git diff --check HEAD~9..HEAD`

Expected: no whitespace errors.

- [ ] **Step 5: Reconcile—but do not publish—compliance drafts**

Compare observed E2E data categories, processor actions, exception rules, and completion timing with `../launch-preparation-2026-09-22/hildors-app-privacy-policy-draft.md` and `../launch-preparation-2026-09-22/google-play-submission-worksheet.md`. Update internal drafts only. Keep all publication and Play submission actions outside this implementation.

- [ ] **Step 6: Commit acceptance evidence and documentation**

```bash
git add backend/test/account-deletion-e2e.test.mjs backend/docs/account-deletion-runbook.md backend/UNIFIED-RELEASE.md docs/customization_data_map_and_retention.md
git commit -m "Document verified account deletion operations"
```

- [ ] **Step 7: Request whole-branch review**

Review the branch against `docs/superpowers/specs/2026-09-25-account-deletion-design.md`, with special attention to undeleted JSON references, media derivatives, stale leases, receipt enumeration, retention-policy bypass, provider verification, and restore-before-ready behavior. Resolve every blocking finding and repeat Step 4 before presenting the branch for deployment approval.
