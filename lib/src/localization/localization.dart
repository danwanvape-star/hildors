import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';
export '../../l10n/generated/app_localizations.dart';
extension HildorsLocalization on BuildContext {
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations)
      ?? lookupAppLocalizations(const Locale('zh'));
}
String localizedFileSize(AppLocalizations strings, int bytes) {
  final number = NumberFormat('#,##0.#', strings.localeName);
  if (bytes >= 1000000) return strings.fileMegabytes(number.format(bytes / 1000000));
  if (bytes >= 1000) return strings.fileKilobytes(number.format(bytes / 1000));
  return strings.fileBytes(number.format(bytes));
}
String localizedDate(AppLocalizations strings, DateTime date) => DateFormat.yMMMd(strings.localeName).add_jm().format(date.toLocal());
String localizedError(AppLocalizations strings, String? code) => switch (code) {
  'USER_AUTH_REQUIRED' || 'UNAUTHORIZED' || 'SESSION_EXPIRED' => strings.errorSession,
  'FORBIDDEN' || 'DOWNLOAD_FORBIDDEN' || 'ENTITLEMENT_REQUIRED' => strings.errorPermission,
  'CONFLICT' || 'VERSION_OR_STATE_CONFLICT' => strings.errorConflict,
  'UPLOAD_TOO_LARGE' => strings.errorTooLarge,
  'RATE_LIMITED' || 'TOO_MANY_REQUESTS' => strings.errorRateLimit,
  'EMAIL_CODE_INVALID' || 'EMAIL_CODE_EXPIRED' => strings.errorEmailCode,
  'EMAIL_DISABLED' || 'SERVICE_UNAVAILABLE' => strings.errorServiceUnavailable,
  'NETWORK_ERROR' || 'TIMEOUT' => strings.errorNetwork,
  _ => strings.errorGeneric,
};
