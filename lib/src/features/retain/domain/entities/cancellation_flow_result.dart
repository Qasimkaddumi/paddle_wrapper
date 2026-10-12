import '../../../../core/json.dart';

/// How a Retain cancellation flow ended.
enum CancellationFlowStatus with PaddleEnum {
  /// The customer closed the flow without deciding.
  aborted('aborted'),

  /// The customer chose to cancel.
  choseToCancel('chose_to_cancel'),

  /// The customer was retained by a salvage attempt or offer.
  retained('retained'),

  /// The flow failed.
  error('error'),

  /// A status this version of the package does not know about.
  unknown('unknown');

  const CancellationFlowStatus(this.value);

  @override
  final String value;
}

/// Whether a salvage attempt or offer was accepted or rejected.
enum RetainDecision with PaddleEnum {
  /// The customer accepted.
  accepted('accepted'),

  /// The customer rejected.
  rejected('rejected'),

  /// A decision this version of the package does not know about.
  unknown('unknown');

  const RetainDecision(this.value);

  @override
  final String value;
}

/// The retention action offered to a customer who wants to cancel.
enum SalvageAttempt with PaddleEnum {
  /// Contact support by email.
  contactSupportEmailNotification('contact_support_email_notification'),

  /// Book a meeting with support.
  contactSupportMeetingScheduler('contact_support_meeting_scheduler'),

  /// Pause the subscription.
  pauseSubscription('pause_subscription'),

  /// Switch to another plan.
  planSwitch('plan_switch'),

  /// An attempt this version of the package does not know about.
  unknown('unknown');

  const SalvageAttempt(this.value);

  @override
  final String value;
}

/// Outcome of a salvage attempt.
class SalvageAttemptResult {
  /// Creates a salvage attempt result.
  const SalvageAttemptResult({
    required this.decision,
    required this.resolution,
    required this.hasErrors,
    this.raw = const <String, dynamic>{},
  });

  /// Parses a salvage attempt result returned by Paddle.js.
  factory SalvageAttemptResult.fromJson(JsonMap json) => SalvageAttemptResult(
    decision: parsePaddleEnum(
      RetainDecision.values,
      json['decision'],
      fallback: RetainDecision.unknown,
    ),
    resolution: parsePaddleEnum(
      RetainDecision.values,
      json['resolution'],
      fallback: RetainDecision.unknown,
    ),
    hasErrors: json.boolOrNull('hasErrors') ?? false,
    raw: json,
  );

  /// The customer's decision.
  final RetainDecision decision;

  /// How the attempt was resolved.
  final RetainDecision resolution;

  /// Whether the attempt reported errors.
  final bool hasErrors;

  /// The payload as returned by Paddle.js.
  final JsonMap raw;
}

/// Outcome of a salvage offer.
class SalvageOfferResult {
  /// Creates a salvage offer result.
  const SalvageOfferResult({
    required this.decision,
    required this.hasErrors,
    this.raw = const <String, dynamic>{},
  });

  /// Parses a salvage offer result returned by Paddle.js.
  factory SalvageOfferResult.fromJson(JsonMap json) => SalvageOfferResult(
    decision: parsePaddleEnum(
      RetainDecision.values,
      json['decision'],
      fallback: RetainDecision.unknown,
    ),
    hasErrors: json.boolOrNull('hasErrors') ?? false,
    raw: json,
  );

  /// The customer's decision.
  final RetainDecision decision;

  /// Whether the offer reported errors.
  final bool hasErrors;

  /// The payload as returned by Paddle.js.
  final JsonMap raw;
}

/// Result of `Paddle.Retain.initCancellationFlow`.
class CancellationFlowResult {
  /// Creates a result.
  const CancellationFlowResult({
    required this.status,
    this.salvageAttemptResult,
    this.salvageOfferResult,
    this.additionalFeedback,
    this.cancelReason,
    this.satisfactionInsight,
    this.salvageAttemptIntended,
    this.salvageAttemptUsed,
    this.raw = const <String, dynamic>{},
  });

  /// Parses a result returned by Paddle.js. Missing fields are tolerated.
  factory CancellationFlowResult.fromJson(JsonMap json) {
    final attemptJson = json.mapOrNull('salvageAttemptResult');
    final offerJson = json.mapOrNull('salvageOfferResult');
    return CancellationFlowResult(
      status: parsePaddleEnum(
        CancellationFlowStatus.values,
        json['status'],
        fallback: CancellationFlowStatus.unknown,
      ),
      salvageAttemptResult: attemptJson == null
          ? null
          : SalvageAttemptResult.fromJson(attemptJson),
      salvageOfferResult: offerJson == null
          ? null
          : SalvageOfferResult.fromJson(offerJson),
      additionalFeedback: json.stringOrNull('additionalFeedback'),
      cancelReason: json.stringOrNull('cancelReason'),
      satisfactionInsight: json.stringOrNull('satisfactionInsight'),
      salvageAttemptIntended: parsePaddleEnumOrNull(
        SalvageAttempt.values,
        json['salvageAttemptIntended'],
        fallback: SalvageAttempt.unknown,
      ),
      salvageAttemptUsed: parsePaddleEnumOrNull(
        SalvageAttempt.values,
        json['salvageAttemptUsed'],
        fallback: SalvageAttempt.unknown,
      ),
      raw: json,
    );
  }

  /// How the flow ended.
  final CancellationFlowStatus status;

  /// Result of the salvage attempt, when one was shown.
  final SalvageAttemptResult? salvageAttemptResult;

  /// Result of the salvage offer, when one was shown.
  final SalvageOfferResult? salvageOfferResult;

  /// Free text the customer added.
  final String? additionalFeedback;

  /// Survey answer the customer gave for cancelling.
  final String? cancelReason;

  /// Satisfaction insight reported by Paddle.
  final String? satisfactionInsight;

  /// The salvage attempt Paddle intended to show.
  final SalvageAttempt? salvageAttemptIntended;

  /// The salvage attempt Paddle actually used.
  final SalvageAttempt? salvageAttemptUsed;

  /// The payload as returned by Paddle.js.
  final JsonMap raw;

  /// Whether the customer chose to cancel.
  bool get wantsToCancel => status == CancellationFlowStatus.choseToCancel;

  /// Whether the customer was retained.
  bool get wasRetained => status == CancellationFlowStatus.retained;
}
