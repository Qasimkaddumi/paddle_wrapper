import 'entities/price_preview.dart';
import 'entities/transaction_preview.dart';

/// Localized pricing for pricing pages and carts, via Paddle.js.
abstract interface class PricingService {
  /// Previews localized prices (`Paddle.PricePreview`).
  Future<PricePreviewResult> previewPrices(PricePreviewRequest request);

  /// Previews a full transaction with totals (`Paddle.TransactionPreview`).
  Future<TransactionPreviewResult> previewTransaction(
    TransactionPreviewRequest request,
  );
}
