import 'package:flutter/material.dart';
import '../../localization/localization.dart';
import 'remote_catalog_repository.dart';
import '../../config/launch_config.dart';

String catalogCredit(BuildContext context, RemoteCatalogPackage item) => item.source == 'hildors'
    ? context.l10n.catalogOfficial : item.hasPublicCreator ? item.creatorName! : context.l10n.catalogAnonymous;
String downloadLabel(BuildContext context, RemoteCatalogClip? clip) => clip?.pricing?.isPaid == true
    ? LaunchConfig.usFree ? context.l10n.downloadUnavailable
      : context.l10n.downloadPrice((clip!.pricing!.amountMinor / 100).toStringAsFixed(2))
    : clip?.pricing != null ? context.l10n.downloadFree : context.l10n.downloadTitle;

/// Bridge legacy controller states without rendering arbitrary exception strings.
String downloadMessage(BuildContext context, String state) => switch(state) {
  '下载暂未开放，请稍后重试' => context.l10n.downloadDisabled,
  '请重新确认账号后下载' => context.l10n.downloadSignIn,
  '当前视频暂不可下载，请刷新权限后重试' => context.l10n.downloadDenied,
  '暂未开放购买' => context.l10n.downloadUnavailable,
  '暂时无法确认下载权限，请检查网络和账号后重试' => context.l10n.downloadAccessFailed,
  '下载完成，已加入我的角色' => context.l10n.downloadFinished,
  '下载已取消，已完成的视频保留在我的角色' => context.l10n.downloadCancelled,
  '下载未完成，请检查网络、存储空间和账号权限后重试' => context.l10n.downloadFailed,
  '' => '',
  _ => context.l10n.errorGeneric,
};
