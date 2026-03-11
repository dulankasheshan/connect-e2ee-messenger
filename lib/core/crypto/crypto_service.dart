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

  /// Generates an RSA 2048-bit key pair, stores the private key securely,
  /// and returns the public key as a PEM encoded string.
  Future<String> generateAndStoreKeyPair() async {
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

    // 4. Securely store the Private Key on the device
    await _secureStorage.write(key: _privateKeyStorageKey, value: privateKeyPem);

    // 5. Return the Public Key to be sent to the backend
    return publicKeyPem;
  }

  /// Retrieves the stored private key for decrypting incoming messages.
  Future<String?> getStoredPrivateKey() async {
    return await _secureStorage.read(key: _privateKeyStorageKey);
  }

  /// Deletes the private key (used during logout or account deletion).
  Future<void> deleteStoredPrivateKey() async {
    await _secureStorage.delete(key: _privateKeyStorageKey);
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
      // 1. Convert PEM string back to RSAPublicKey object
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);

      // 2. Encrypt the text (basic_utils handles the conversion and Base64 encoding)
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
      // 1. Get our private key from secure storage
      final privateKeyPem = await getStoredPrivateKey();
      if (privateKeyPem == null) {
        throw Exception('Private key not found in secure storage.');
      }

      // 2. Convert PEM string back to RSAPrivateKey object
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

      // 3. Decrypt the text
      final plainText = CryptoUtils.rsaDecrypt(base64CipherText, privateKey);

      return plainText;
    } catch (e) {
      throw Exception('Failed to decrypt message: $e');
    }
  }
}