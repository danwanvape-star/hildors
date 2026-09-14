/// Display-only projection of repository status values. No order transitions.
class GateOrderProgress {
  const GateOrderProgress._(this.stage, this.hintKey, this.quoteKey,
      {this.complete = false, this.reviewPassed = true});

  /// -1 means no active creation stage (closed, paused, unknown or complete).
  final int stage;
  final String hintKey;
  final String quoteKey;
  final bool complete;
  final bool reviewPassed;

  factory GateOrderProgress.fromStatus(String status) => switch (status) {
        '免费预审中' => const GateOrderProgress._(0, 'stepReview', 'quoteLocked',
            reviewPassed: false),
        '待创作者申请' =>
          const GateOrderProgress._(1, 'stepMatching', 'quoteMatching'),
        '创作者评估中' =>
          const GateOrderProgress._(1, 'stepEstimate', 'quoteEstimating'),
        '平台审核报价' =>
          const GateOrderProgress._(1, 'stepPlatformQuote', 'quotePlatform'),
        '待确认报价' =>
          const GateOrderProgress._(1, 'stepAcceptQuote', 'quoteWaiting'),
        '待支付' => const GateOrderProgress._(1, 'stepPayment', 'quoteAccepted'),
        '制作中' =>
          const GateOrderProgress._(2, 'stepProduction', 'quoteAccepted'),
        '修改中' => const GateOrderProgress._(2, 'stepRevision', 'quoteAccepted'),
        '待平台质检' => const GateOrderProgress._(2, 'stepQuality', 'quoteAccepted'),
        '待用户验收' =>
          const GateOrderProgress._(3, 'stepApproval', 'quoteAccepted'),
        '已交付' => const GateOrderProgress._(-1, 'stepDelivered', 'quoteAccepted',
            complete: true),
        '已撤回' => const GateOrderProgress._(-1, 'stepWithdrawn', 'quoteClosed',
            reviewPassed: false),
        '预审未通过' => const GateOrderProgress._(-1, 'stepRejected', 'quoteLocked',
            reviewPassed: false),
        '已拒绝报价' =>
          const GateOrderProgress._(-1, 'stepDeclined', 'quoteDeclined'),
        '争议处理中' => const GateOrderProgress._(-1, 'stepDispute', 'quoteHistory'),
        '退款处理中' =>
          const GateOrderProgress._(-1, 'stepRefundPending', 'quoteHistory'),
        '已退款' => const GateOrderProgress._(-1, 'stepRefunded', 'quoteHistory'),
        _ => const GateOrderProgress._(-1, 'stepUnknown', 'quoteUnknown',
            reviewPassed: false),
      };
}
