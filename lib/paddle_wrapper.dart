/// Paddle Billing for Flutter web: overlay and inline checkout, checkout
/// events, localized pricing, Paddle Retain and backend confirmation polling.
library;

// Core
export 'src/core/json.dart' show JsonMap, PaddleEnum;
export 'src/core/paddle_environment.dart';
export 'src/core/paddle_exception.dart';
export 'src/core/platform/paddle_platform.dart'
    show PaddleEventHandler, PaddlePlatform;
export 'src/paddle.dart';
export 'src/paddle_config.dart';

// Checkout
export 'src/features/checkout/domain/checkout_service.dart';
export 'src/features/checkout/domain/entities/checkout_customer.dart';
export 'src/features/checkout/domain/entities/checkout_data.dart';
export 'src/features/checkout/domain/entities/checkout_discount.dart';
export 'src/features/checkout/domain/entities/checkout_enums.dart';
export 'src/features/checkout/domain/entities/checkout_error.dart';
export 'src/features/checkout/domain/entities/checkout_event.dart';
export 'src/features/checkout/domain/entities/checkout_item.dart';
export 'src/features/checkout/domain/entities/checkout_options.dart';
export 'src/features/checkout/domain/entities/checkout_settings.dart';
export 'src/features/checkout/domain/entities/checkout_state.dart';
export 'src/features/checkout/domain/entities/checkout_update.dart';
export 'src/features/checkout/domain/entities/checkout_upsell.dart';
export 'src/features/checkout/presentation/paddle_checkout_builder.dart';
export 'src/features/checkout/presentation/paddle_checkout_frame.dart';

// Confirmation
export 'src/features/confirmation/domain/payment_confirmation.dart';
export 'src/features/confirmation/domain/payment_confirmation_exception.dart';
export 'src/features/confirmation/domain/polling_policy.dart';

// Pricing
export 'src/features/pricing/domain/entities/price_preview.dart';
export 'src/features/pricing/domain/entities/pricing_shared.dart'
    hide stringListOf, unwrapPreviewData, validatePreviewCommon;
export 'src/features/pricing/domain/entities/transaction_preview.dart';
export 'src/features/pricing/domain/pricing_service.dart';

// Retain
export 'src/features/retain/domain/entities/cancellation_flow_result.dart';
export 'src/features/retain/domain/entities/retain_demo_feature.dart';
export 'src/features/retain/domain/retain_service.dart';
