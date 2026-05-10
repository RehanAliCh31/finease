import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAppLocked = false;
  bool _isBiometricEnabled = false;
  
  bool get isAppLocked => _isAppLocked;
  bool get isBiometricEnabled => _isBiometricEnabled;

  SecurityService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  void lockApp() {
    if (_isBiometricEnabled) {
      _isAppLocked = true;
      notifyListeners();
    }
  }

  Future<bool> unlockApp() async {
    if (!_isBiometricEnabled) {
      _isAppLocked = false;
      notifyListeners();
      return true;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access FinEase',
      );
      if (didAuthenticate) {
        _isAppLocked = false;
        notifyListeners();
        return true;
      }
    } on PlatformException catch (e) {
      if (kDebugMode) print('Security unlock error: $e');
    }
    return false;
  }

  Future<bool> canUseBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }
}
