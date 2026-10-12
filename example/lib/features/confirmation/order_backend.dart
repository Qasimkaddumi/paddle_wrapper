/// Lifecycle of an order as your backend sees it.
enum OrderState { pending, paid, failed }

/// The status of one order, as reported by your backend.
class OrderStatus {
  /// Creates a status.
  const OrderStatus({required this.transactionId, required this.state});

  /// Paddle transaction ID (`txn_...`).
  final String transactionId;

  /// Current state of the order.
  final OrderState state;

  /// Whether polling can stop: the order is either paid or failed.
  bool get isFinal => state != OrderState.pending;

  /// Whether the order is paid and fulfilled.
  bool get isPaid => state == OrderState.paid;
}

/// The API of YOUR backend, as far as this example is concerned.
abstract interface class OrderBackend {
  /// Returns the current status of the order for [transactionId].
  Future<OrderStatus> fetchOrderStatus(String transactionId);
}

/// A fake backend so the example runs without a server.
///
/// In production, implement [OrderBackend] with an HTTP call to YOUR backend.
/// Your backend is the system of record: it marks the order as paid when it
/// receives Paddle's `transaction.completed` webhook (Paddle sends that
/// webhook to your server, not to the browser). The Flutter app only asks
/// "is this order paid yet?" and keeps polling until the answer is final.
///
/// Never grant access based only on the client-side `checkout.completed`
/// event. The browser can be closed, the network can fail, and the event
/// is not proof that the webhook was processed.
///
/// This fake returns "pending" for the first [pendingCalls] requests of each
/// transaction, then "paid", to simulate the webhook arriving a few seconds
/// later.
class FakeOrderBackend implements OrderBackend {
  /// Creates the fake. [pendingCalls] is how many polls answer "pending".
  FakeOrderBackend({this.pendingCalls = 3});

  /// How many times each transaction reports "pending" before "paid".
  final int pendingCalls;

  final Map<String, int> _calls = {};

  @override
  Future<OrderStatus> fetchOrderStatus(String transactionId) async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final count = (_calls[transactionId] ?? 0) + 1;
    _calls[transactionId] = count;

    return OrderStatus(
      transactionId: transactionId,
      state: count > pendingCalls ? OrderState.paid : OrderState.pending,
    );
  }
}
