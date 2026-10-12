import '../../../core/platform/paddle_platform.dart';
import '../domain/entities/price_preview.dart';
import '../domain/entities/transaction_preview.dart';
import '../domain/pricing_service.dart';

/// [PricingService] backed by the Paddle.js price and transaction previews.
class PaddlePricingService implements PricingService {
  /// Creates the service on top of [_platform].
  const PaddlePricingService(this._platform);

  final PaddlePlatform _platform;

  @override
  Future<PricePreviewResult> previewPrices(PricePreviewRequest request) async {
    request.validate();
    final json = await _platform.pricePreview(request.toJson());
    return PricePreviewResult.fromJson(json);
  }

  @override
  Future<TransactionPreviewResult> previewTransaction(
    TransactionPreviewRequest request,
  ) async {
    request.validate();
    final json = await _platform.transactionPreview(request.toJson());
    return TransactionPreviewResult.fromJson(json);
  }
}
