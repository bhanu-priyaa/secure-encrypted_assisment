enum FailureKind { network, badCredentials, sessionExpired, server, storage }

class Failure implements Exception {
  const Failure(this.kind, this.message);

  const Failure.network()
    : kind = FailureKind.network,
      message = 'No internet connection. Check your network and try again.';

  const Failure.sessionExpired()
    : kind = FailureKind.sessionExpired,
      message = 'Your session has expired. Please sign in again.';

  final FailureKind kind;
  final String message;

  @override
  String toString() => message;
}
