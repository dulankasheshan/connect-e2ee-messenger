import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

class CryptoService {
  final FlutterSecureStorage _secureStorage;

  CryptoService({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  static const String _privateKeyStorageKey = 'e2ee_private_key';
  static const String _publicKeyStorageKey = 'e2ee_public_key'; // Added to store public key locally

  /// Checks if keys exist. If they do, returns the existing public key.
  /// If they don't (e.g., new install), generates a new pair, stores them,
  /// and returns the new public key.
  Future<String> getOrGeneratePublicKey() async {
    final existingPublicKey = await _secureStorage.read(key: _publicKeyStorageKey);
    final existingPrivateKey = await _secureStorage.read(key: _privateKeyStorageKey);

    // If both keys exist, the user simply logged out and logged back in on the same device.
    // We reuse the existing keys so old offline messages can still be decrypted.
    if (existingPublicKey != null && existingPrivateKey != null) {
      return existingPublicKey;
    }

    // Otherwise, generate a new key pair
    return await _generateAndStoreKeyPair();
  }

  /// Generates an RSA 2048-bit key pair, stores BOTH keys securely,
  /// and returns the public key as a PEM encoded string.
  Future<String> _generateAndStoreKeyPair() async {
    // 1. Initialize the RSA Key Generator
    final secureRandom = _getSecureRandom();
    final keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
    final rngParams = ParametersWithRandom(keyParams, secureRandom);

    final generator = RSAKeyGenerator()..init(rngParams);

    // 2. Generate the Key Pair
    final pair = generator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    // 3. Convert keys to PEM format (Base64 Strings)
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

    // 4. Securely store BOTH keys on the device
    await _secureStorage.write(key: _privateKeyStorageKey, value: privateKeyPem);
    await _secureStorage.write(key: _publicKeyStorageKey, value: publicKeyPem);

    // 5. Return the Public Key to be sent to the backend
    return publicKeyPem;
  }

  /// Retrieves the stored private key for decrypting incoming messages.
  Future<String?> getStoredPrivateKey() async {
    return await _secureStorage.read(key: _privateKeyStorageKey);
  }

  /// WARNING: Only call this if the user explicitly requests to delete their account
  /// or reset their encryption keys. Do NOT call this on normal logout.
  Future<void> deleteStoredKeys() async {
    await _secureStorage.delete(key: _privateKeyStorageKey);
    await _secureStorage.delete(key: _publicKeyStorageKey);
  }

  /// Generates a cryptographically secure random number generator (Fortuna).
  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = <int>[];

    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }

    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  // ==========================================
  // MESSAGE ENCRYPTION & DECRYPTION
  // ==========================================

  /// Encrypts a plaintext message using the receiver's Public Key.
  /// Returns a Base64 encoded ciphertext string.
  Future<String> encryptMessage(String plainText, String publicKeyPem) async {
    try {
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
      final encryptedText = CryptoUtils.rsaEncrypt(plainText, publicKey);
      return encryptedText;
    } catch (e) {
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Decrypts a Base64 encoded ciphertext message using our own stored Private Key.
  /// Returns the original plaintext string.
  Future<String> decryptMessage(String base64CipherText) async {
    try {
      final privateKeyPem = await getStoredPrivateKey();
      if (privateKeyPem == null) {
        throw Exception('Private key not found in secure storage.');
      }
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
      final plainText = CryptoUtils.rsaDecrypt(base64CipherText, privateKey);
      return plainText;
    } catch (e) {
      throw Exception('Failed to decrypt message: $e');
    }
  }
}