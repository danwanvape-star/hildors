# Customer support — 2026-09-30

0.1.76+77: Profile / Contact support now shows the user-confirmed address support@marketing.hildors.com. Write email launches a mailto composer with only a generic subject; the user controls sending and attachments. No logs or personal data are attached automatically. Copy email and selectable address remain available if no email application handles mailto. English and Chinese resources included.

Validation: two widget tests cover EN/ZH, exact recipient, subject encoding, unavailable mail-handler fallback and clipboard contents. Static analysis clean. Android ARM64 debug build. Real email-app launch and mailbox delivery are not tested; no email was sent. iOS requires pub get / CocoaPods and a Mac build; no iOS build claimed here.

Uses url_launcher 6.3.2 plus resolved platform dependencies in pubspec.lock. No backend changes or data migration. Rollback by reverting this commit and rebuilding with a higher version code. Keep user downloads unchanged.
