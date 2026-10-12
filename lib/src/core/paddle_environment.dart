/// The Paddle environment that Paddle.js talks to.
enum PaddleEnvironment {
  /// Paddle sandbox, for testing. Client tokens start with `test_`.
  sandbox('test_'),

  /// Paddle live environment. Client tokens start with `live_`.
  production('live_');

  const PaddleEnvironment(this.tokenPrefix);

  /// Prefix every client-side token for this environment starts with.
  final String tokenPrefix;

  /// Whether this is the sandbox environment.
  bool get isSandbox => this == PaddleEnvironment.sandbox;

  /// Infers the environment from a client-side [token] prefix, or `null`
  /// when the prefix is not recognised.
  static PaddleEnvironment? fromClientToken(String token) {
    for (final environment in values) {
      if (token.startsWith(environment.tokenPrefix)) return environment;
    }
    return null;
  }
}
