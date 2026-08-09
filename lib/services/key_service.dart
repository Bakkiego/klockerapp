import 'dart:convert';
import 'dart:math';
import '../supabase/repo/supabase_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KeyService {
  static final _kx = X25519();
  static final _storage = FlutterSecureStorage();
  static const _privateKeyStorageKey = 'chat_private_key';
  static final _kdf = Argon2id(
    parallelism: 1,
    memory: 19456,
    iterations: 3,
    hashLength: 32,
  );
  static final _cipher = Chacha20.poly1305Aead();
  static final _rand = Random.secure();

  /// First-time setup. No key shown to the user — wraps the private
  /// key with their existing login password.
  static Future<void> setupNewIdentity(String userId, String password) async {
    final keyPair = await _kx.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await _storage.write(
      key: _privateKeyStorageKey,
      value: base64Encode(privateBytes),
    );

    final salt = List<int>.generate(16, (_) => _rand.nextInt(256));
    final wrappingKey = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final wrapped = await _cipher.encrypt(privateBytes, secretKey: wrappingKey);

    final supabase = Supabase.instance.client;
    await supabase
        .from('profiles')
        .update({'public_key': base64Encode(publicKey.bytes)})
        .eq('id', userId);
    await supabase.from('user_backup_keys').upsert({
      'profile_id': userId,
      'wrapped_private_key': base64Encode(wrapped.concatenation()),
      'kdf_salt': base64Encode(salt),
    });
  }

  /// Called automatically right after login succeeds — the password
  /// they just typed IS the restore secret, so there's nothing extra
  /// for the user to do.
  static Future<bool> restoreFromPassword(
    String userId,
    String password,
  ) async {
    final supabase = Supabase.instance.client;
    final row = await supabase
        .from('user_backup_keys')
        .select()
        .eq('profile_id', userId)
        .maybeSingle();
    if (row == null) return false;

    final salt = base64Decode(row['kdf_salt']);
    final wrappingKey = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    try {
      final box = SecretBox.fromConcatenation(
        base64Decode(row['wrapped_private_key']),
        nonceLength: _cipher.nonceLength,
        macLength: _cipher.macAlgorithm.macLength,
      );
      final privateBytes = await _cipher.decrypt(box, secretKey: wrappingKey);
      await _storage.write(
        key: _privateKeyStorageKey,
        value: base64Encode(privateBytes),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Call this wherever your app already handles "change password"
  /// (while logged in, old password known) — keeps the backup unlockable.
  static Future<void> rewrapOnPasswordChange(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    final supabase = Supabase.instance.client;
    final row = await supabase
        .from('user_backup_keys')
        .select()
        .eq('profile_id', userId)
        .maybeSingle();
    if (row == null) return;

    final oldSalt = base64Decode(row['kdf_salt']);
    final oldKey = await _kdf.deriveKeyFromPassword(
      password: oldPassword,
      nonce: oldSalt,
    );
    final box = SecretBox.fromConcatenation(
      base64Decode(row['wrapped_private_key']),
      nonceLength: _cipher.nonceLength,
      macLength: _cipher.macAlgorithm.macLength,
    );
    final privateBytes = await _cipher.decrypt(box, secretKey: oldKey);

    final newSalt = List<int>.generate(16, (_) => _rand.nextInt(256));
    final newKey = await _kdf.deriveKeyFromPassword(
      password: newPassword,
      nonce: newSalt,
    );
    final rewrapped = await _cipher.encrypt(privateBytes, secretKey: newKey);

    await supabase
        .from('user_backup_keys')
        .update({
          'wrapped_private_key': base64Encode(rewrapped.concatenation()),
          'kdf_salt': base64Encode(newSalt),
        })
        .eq('profile_id', userId);
  }

  static Future<SimpleKeyPair?> loadKeyPair() async {
    final stored = await _storage.read(key: _privateKeyStorageKey);
    if (stored == null) return null;
    return _kx.newKeyPairFromSeed(base64Decode(stored));
  }

  static Future<bool> hasLocalKey() async =>
      await _storage.read(key: _privateKeyStorageKey) != null;
}
