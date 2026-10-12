import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_wrapper/src/core/paddle_exception.dart';
import 'package:paddle_wrapper/src/features/retain/data/paddle_retain_service.dart';
import 'package:paddle_wrapper/src/features/retain/domain/entities/cancellation_flow_result.dart';
import 'package:paddle_wrapper/src/features/retain/domain/entities/retain_demo_feature.dart';

import '../../support/fake_paddle_platform.dart';

void main() {
  group('CancellationFlowResult.fromJson', () {
    test('parses a full cancellation payload', () {
      final result = CancellationFlowResult.fromJson({
        'status': 'chose_to_cancel',
        'salvageAttemptResult': {
          'decision': 'rejected',
          'resolution': 'accepted',
          'hasErrors': false,
        },
        'salvageOfferResult': {'decision': 'accepted', 'hasErrors': true},
        'additionalFeedback': 'Too expensive',
        'cancelReason': 'price',
        'satisfactionInsight': 'low',
        'salvageAttemptIntended': 'pause_subscription',
        'salvageAttemptUsed': 'plan_switch',
      });

      expect(result.status, CancellationFlowStatus.choseToCancel);
      expect(result.wantsToCancel, isTrue);
      expect(result.wasRetained, isFalse);
      expect(result.salvageAttemptResult?.decision, RetainDecision.rejected);
      expect(result.salvageAttemptResult?.resolution, RetainDecision.accepted);
      expect(result.salvageAttemptResult?.hasErrors, isFalse);
      expect(result.salvageOfferResult?.decision, RetainDecision.accepted);
      expect(result.salvageOfferResult?.hasErrors, isTrue);
      expect(result.additionalFeedback, 'Too expensive');
      expect(result.cancelReason, 'price');
      expect(result.satisfactionInsight, 'low');
      expect(result.salvageAttemptIntended, SalvageAttempt.pauseSubscription);
      expect(result.salvageAttemptUsed, SalvageAttempt.planSwitch);
      expect(result.raw['status'], 'chose_to_cancel');
    });

    test('parses a retained payload', () {
      final result = CancellationFlowResult.fromJson({
        'status': 'retained',
        'salvageAttemptResult': null,
        'salvageOfferResult': null,
      });

      expect(result.status, CancellationFlowStatus.retained);
      expect(result.wasRetained, isTrue);
      expect(result.wantsToCancel, isFalse);
      expect(result.salvageAttemptResult, isNull);
      expect(result.salvageOfferResult, isNull);
      expect(result.salvageAttemptIntended, isNull);
    });

    test('maps unknown status and salvage values to unknown', () {
      final result = CancellationFlowResult.fromJson({
        'status': 'future_status',
        'salvageAttemptUsed': 'future_attempt',
        'salvageAttemptResult': {'decision': 'maybe'},
      });

      expect(result.status, CancellationFlowStatus.unknown);
      expect(result.salvageAttemptUsed, SalvageAttempt.unknown);
      expect(result.salvageAttemptResult?.decision, RetainDecision.unknown);
      expect(result.salvageAttemptResult?.hasErrors, isFalse);
    });

    test('never throws on an empty payload', () {
      final result = CancellationFlowResult.fromJson(const {});

      expect(result.status, CancellationFlowStatus.unknown);
      expect(result.wantsToCancel, isFalse);
      expect(result.wasRetained, isFalse);
      expect(result.additionalFeedback, isNull);
      expect(result.raw, isEmpty);
    });

    test('keeps the raw payload', () {
      const payload = {'status': 'aborted', 'extra': 1};

      expect(CancellationFlowResult.fromJson(payload).raw, payload);
    });
  });

  group('RetainDemoFeature', () {
    test('uses the Paddle.js feature names', () {
      expect(RetainDemoFeature.paymentRecovery.value, 'paymentRecovery');
      expect(RetainDemoFeature.cancellationFlow.value, 'cancellationFlow');
      expect(RetainDemoFeature.termsAcceptance.value, 'termsAcceptance');
    });
  });

  group('PaddleRetainService', () {
    late FakePaddlePlatform fake;
    late PaddleRetainService service;

    setUp(() {
      fake = FakePaddlePlatform();
      service = PaddleRetainService(fake);
    });

    test('sends an empty object when no subscriptionId is given', () async {
      fake.results['initCancellationFlow'] = {'status': 'aborted'};

      final result = await service.initCancellationFlow();

      expect(fake.argsOf('initCancellationFlow').single, <String, dynamic>{});
      expect(result.status, CancellationFlowStatus.aborted);
    });

    test('sends the subscriptionId when provided', () async {
      await service.initCancellationFlow(subscriptionId: 'sub_01');

      expect(fake.argsOf('initCancellationFlow').single, {
        'subscriptionId': 'sub_01',
      });
    });

    test('rejects a subscriptionId that is not a sub_ ID', () async {
      await expectLater(
        service.initCancellationFlow(subscriptionId: 'ctm_01'),
        throwsA(isA<PaddleValidationException>()),
      );
      expect(fake.argsOf('initCancellationFlow'), isEmpty);
    });

    test('propagates platform errors', () async {
      fake.errors['initCancellationFlow'] = const PaddleJsException('nope');

      await expectLater(
        service.initCancellationFlow(),
        throwsA(isA<PaddleJsException>()),
      );
    });

    test('demo sends the feature name to Paddle.Retain.demo', () {
      service.demo(RetainDemoFeature.paymentRecovery);

      expect(fake.argsOf('retainDemo').single, {'feature': 'paymentRecovery'});
    });
  });
}
