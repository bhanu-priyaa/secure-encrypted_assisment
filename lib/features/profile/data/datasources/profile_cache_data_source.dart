import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/crypto/crypto_service.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart';

class CachedProfile {
  const CachedProfile({required this.user, required this.cachedAt});

  final User user;
  final DateTime cachedAt;
}

class ProfileCacheDataSource {
  ProfileCacheDataSource({
    required SecureStore secureStore,
    required CryptoService crypto,
  }) : _secure = secureStore,
       _crypto = crypto;

  static const fileName = 'profile.enc';

  final SecureStore _secure;
  final CryptoService _crypto;

  File? _file;

  String get cipherName => CryptoService.cipherName;

  Future<File> _resolveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return _file ??= File('${dir.path}/$fileName');
  }

  Future<Uint8List> _dataKey() async {
    final existing = await _secure.readBytes(SecureKeys.cacheKey);
    if (existing != null && existing.length == CryptoService.keyLengthBytes) {
      return existing;
    }
    final fresh = _crypto.generateDataKey();
    await _secure.writeBytes(SecureKeys.cacheKey, fresh);
    return fresh;
  }

  Future<void> write(User user) async {
    final payload = jsonEncode({
      'user': UserModel.toJson(user),
      'cachedAt': DateTime.now().toIso8601String(),
    });

    final blob = await _crypto.encrypt(
      Uint8List.fromList(utf8.encode(payload)),
      await _dataKey(),
    );

    final file = await _resolveFile();
    await file.writeAsBytes(blob, flush: true);
  }

  Future<CachedProfile?> read() async {
    try {
      final file = await _resolveFile();
      if (!file.existsSync()) return null;

      final key = await _secure.readBytes(SecureKeys.cacheKey);
      if (key == null || key.length != CryptoService.keyLengthBytes) return null;

      final clear = await _crypto.decrypt(await file.readAsBytes(), key);
      if (clear == null) return null;

      final map = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '');
      if (cachedAt == null) return null;

      return CachedProfile(
        user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
        cachedAt: cachedAt,
      );
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final file = await _resolveFile();
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      return;
    } finally {
      await _secure.delete(SecureKeys.cacheKey);
    }
  }
}
