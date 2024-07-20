import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithPhone(String phoneNumber, Function(PhoneAuthCredential) codeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print(e.message);
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(PhoneAuthProvider.credential(verificationId: verificationId, smsCode: ''));
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }
}
