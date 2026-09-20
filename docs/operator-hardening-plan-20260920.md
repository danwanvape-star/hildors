# Compatible operator hardening

Approved baseline: live snapshot 2026-09-20. Supersedes alternate operator_accounts schema and four-module policy. Preserve operators, operator_audit and every granular permission.

1. Add backwards-compatible password-change state and atomic account/audit changes. Existing accounts default false; new/reset accounts true. Self change verifies current password, revokes all sessions and preserves permissions.
2. Gate business APIs while password change is required; bound per-account/source authentication attempts and session memory. Preserve root and bearer workflows.
3. Add self-service password dialog independent of account-management permission and clear sensitive form fields.
4. Run existing permission/media/UI tests and full backend suite, review diff, then fresh online hash preflight before any deployment. Manual deployment backup only, no automatic backup or real test accounts.

Ruling: isolated live-source repository used because main contains concurrent uncommitted changes and earlier isolated implementation uses incompatible schema. No shared main files are overwritten.
Baseline verification: 23 permission/media/UI tests passed.
