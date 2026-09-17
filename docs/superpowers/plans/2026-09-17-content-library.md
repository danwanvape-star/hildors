# Content library refinement implementation plan

User approved the four-part design in conversation on 2026-09-17.

Goal: per-item attribution, usable framing entry, compact character detail, creator works navigation.
Architecture: backward-compatible optional catalog fields description and creator {id,name,anonymous}; anonymous public data redacts identity. Existing media/upload and device protocol remain unchanged. Frontend uses stable creator IDs across loaded published catalog pages, never matching by display name.
Constraints: no secrets/media/database in Git; no live deployment; automatic backups deferred until release preparation per user. Preserve existing data. Manufacturer transcoding is not implemented and must not be presented as available.

1. Backend: failing HTTP tests for attribution persistence, validation, old content fallback and anonymous redaction. Implement metadata create/update endpoint with version checks and safe public projection; add admin editing fields. Run backend tests.
2. Flutter catalog: failing widget/model tests for per-card credit, creator ID filtering/anonymous exclusion and two-column detail. Extend model, add focused detail/creator pages, retain clip actions and lazy video playback. Remove source-based display headings, retain source filters and operator-defined non-source headings.
3. Framing: make pending-row adjustment explicit, cover original-source limitations for existing device items, test navigation and persistence using existing framing tests. Preserve distinct startup/Bluetooth pending lists.
4. Integrate: run analyze/full Flutter and backend media tests, inspect responsive layout, increment app patch/build version, build release APK with existing debug signing and public API target. Review diff, commit and push feature branch; do not deploy backend without approval.

Ruling: work on a dedicated feature branch in the existing clean checkout to reuse installed SDK/build caches and avoid disturbing files. Backend and framing tasks own disjoint files; coordinator owns Flutter catalog and integration. No production data or server changes.
