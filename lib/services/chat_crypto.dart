import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class ChatCrypto {
  static final _kx = X25519();
  static final _cipher = Chacha20.poly1305Aead();

  static Future<SecretKey> _sharedKey({
    required SimpleKeyPair myKeyPair,
    required String theirPublicKeyBase64,
  }) async {
    final theirKey = SimplePublicKey(
      base64Decode(theirPublicKeyBase64),
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _kx.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: theirKey,
    );
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: sharedSecret,
      info: utf8.encode('klocker-chat-v1'),
    );
  }

  static Future<String> encryptMessage({
    required String plaintext,
    required SimpleKeyPair myKeyPair,
    required String theirPublicKeyBase64,
  }) async {
    final key = await _sharedKey(
      myKeyPair: myKeyPair,
      theirPublicKeyBase64: theirPublicKeyBase64,
    );
    final box = await _cipher.encrypt(utf8.encode(plaintext), secretKey: key);
    return base64Encode(box.concatenation());
  }

  static Future<String> decryptMessage({
    required String encryptedBase64,
    required SimpleKeyPair myKeyPair,
    required String theirPublicKeyBase64,
  }) async {
    final key = await _sharedKey(
      myKeyPair: myKeyPair,
      theirPublicKeyBase64: theirPublicKeyBase64,
    );
    final box = SecretBox.fromConcatenation(
      base64Decode(encryptedBase64),
      nonceLength: _cipher.nonceLength,
      macLength: _cipher.macAlgorithm.macLength,
    );
    return utf8.decode(await _cipher.decrypt(box, secretKey: key));
  }
}
