# Default-free catalog downloads

User authorized all videos without configured charging to be free. Missing pricing now grants download eligibility after existing publication, approval, visibility, inspected-media and paid-alias checks. Explicit paid and malformed prices remain denied. Authentication and download enablement remain required. Public catalog returns explicit free USD/0 pricing for missing fields, including existing records and future appended clips. No database migration or blanket entitlement grant.

Tests: regression failed before implementation; focused suite 22 passed. Full backend suite after loading FFmpeg environment: 221 passed, 4 skipped, 0 failed (225 total). Initial full run lacked ffprobe; corrected environment and reran. git diff --check passed.

Deployed via two exact replacements in delivery.mjs/server.mjs, retaining other deployed code. Server syntax checks passed, service active, /ready HTTP 200. Read-only validation of deployed authorization function with actual catalog documents confirmed Li Ren and Xing Jie allowed without package entitlement and catalog free pricing. No physical phone download was performed.

Backup: /opt/hildors/backups/default-free-20260929/{delivery,server}.mjs. Rollback only the two changed expressions (or restore these backups after verifying no later server edits), syntax-check then restart hildors-team-staging. No data rollback required. Previous Li Ren explicit-free correction remains valid and audited independently.
