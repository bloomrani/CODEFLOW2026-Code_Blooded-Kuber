import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Mobile Singleton Instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  // 🌟 FIXED: We completely skip initializing this package on the Web now!
  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized && !kIsWeb) {
      await _googleSignIn.initialize(
        serverClientId: '123998902824-aluq0rka8ln0af1mnp2708n1gpvqip16.apps.googleusercontent.com', 
      );
      _isGoogleInitialized = true;
    }
  }

  // 1. Sign Up (Registration)
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Registration Error: ${e.message}");
      return null;
    }
  }

  // 2. Log In
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.message}");
      return null;
    }
  }

  // 3. Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 🌐 THE ULTIMATE WEB FIX: 
        // Bypass the google_sign_in package entirely and use Firebase's native Web Provider.
        // This natively handles FedCM and popups without throwing errors!
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        
        UserCredential userCredential = await _auth.signInWithPopup(authProvider);
        return userCredential.user;
        
      } else {
        // 📱 THE MOBILE PATH: 
        // Keeps your exact mobile configuration perfectly intact.
        await _ensureGoogleInitialized();

        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  // 4. Log Out
  Future<void> signOut() async {
    // Only attempt to sign out of the Google package on mobile
    if (!kIsWeb) {
      await _googleSignIn.signOut(); 
    }
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getUserToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }
}