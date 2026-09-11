import '../constants/app_constants.dart';
import '../storage/secure_store.dart';
import 'auth_tokens.dart';

class TokenStore {
  TokenStore(this._secure);

  final SecureStore _secure;

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  Future<void> load() async {
    _accessToken = await _secure.read(SecureKeys.accessToken);
    _refreshToken = await _secure.read(SecureKeys.refreshToken);
  }

  Future<bool> hasSession() async {
    if (_accessToken != null) return true;
    await load();
    return _accessToken != null;
  }

  Future<void> save(AuthTokens tokens) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    await _secure.write(SecureKeys.accessToken, tokens.accessToken);
    await _secure.write(SecureKeys.refreshToken, tokens.refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _secure.delete(SecureKeys.accessToken);
    await _secure.delete(SecureKeys.refreshToken);
  }
}
