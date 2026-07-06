import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the Secure Vault',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Vault Authentication required',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
          ),
        ],
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      return didAuthenticate;
    } catch (e) {
      print('Auth error: $e');
      return false;
    }
  }
}
