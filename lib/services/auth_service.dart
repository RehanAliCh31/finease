import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  User? _user;
  FirestoreService? _firestoreService;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = const [];

  User? get user => _user;
  FirestoreService? get firestoreService => _firestoreService;
  bool get isBiometricEnabled => _isBiometricEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _firestoreService = FirestoreService(uid: user.uid);
        _firestoreService!.ensureSeedData();
      } else {
        _firestoreService = null;
      }
      notifyListeners();
    });
    _loadBiometricState();
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in anonymously: $e');
      }
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in with email: $e');
      }
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestoreService?.saveUserProfile({
        'fullName': email.split('@').first,
        'email': email,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error signing up with email: $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      rethrow;
    }
  }

  Future<void> enableBiometricLogin({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: 'biometric_email', value: email);
    await _secureStorage.write(key: 'biometric_password', value: password);
    await _secureStorage.write(key: 'biometric_enabled', value: 'true');
    _isBiometricEnabled = true;
    notifyListeners();
  }

  Future<void> disableBiometricLogin() async {
    await _secureStorage.delete(key: 'biometric_email');
    await _secureStorage.delete(key: 'biometric_password');
    await _secureStorage.write(key: 'biometric_enabled', value: 'false');
    _isBiometricEnabled = false;
    notifyListeners();
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      notifyListeners();
      return _availableBiometrics;
    } catch (_) {
      _availableBiometrics = const [];
      notifyListeners();
      return _availableBiometrics;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final enabled = await _secureStorage.read(key: 'biometric_enabled');
    if (enabled != 'true') {
      return false;
    }

    final email = await _secureStorage.read(key: 'biometric_email');
    final password = await _secureStorage.read(key: 'biometric_password');
    if (email == null || password == null) {
      return false;
    }

    final isSupported = await canUseBiometrics();
    if (!isSupported) {
      return false;
    }

    final didAuthenticate = await _localAuth.authenticate(
      localizedReason:
          'Authenticate with Touch ID or Face ID to unlock FinEase',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );

    if (!didAuthenticate) {
      return false;
    }

    await signInWithEmail(email, password);
    return true;
  }

  Future<void> _loadBiometricState() async {
    _isBiometricEnabled =
        (await _secureStorage.read(key: 'biometric_enabled')) == 'true';
    _availableBiometrics = await getAvailableBiometrics();
    notifyListeners();
  }
}
