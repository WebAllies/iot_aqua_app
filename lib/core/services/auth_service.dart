import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String superAdminEmail = "superadmin@iot.com";

  Future<UserCredential> signInEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await ensureUserDoc(cred.user);
    return cred;
  }
  Future<UserCredential> registerEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await ensureUserDoc(cred.user);
    return cred;
  }
  Future<UserCredential> signInGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception("Google sign-in canceled");
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    await ensureUserDoc(cred.user);
    return cred;
  }

  Future<void> signOut() async {
    try { await GoogleSignIn().signOut(); } catch (_) {}
    await _auth.signOut();
  }

  Future<void> ensureUserDoc(User? user) async {
    if (user == null) return;

    final ref = _db.collection("users").doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      final role = (user.email?.toLowerCase() == superAdminEmail)
          ? "super_admin"
          : "employee";

      await ref.set({
        "uid": user.uid,
        "email": user.email ?? "",
        "name": user.displayName ?? "",
        "role": role,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      // Optional: keep superadmin enforced even if doc exists
      final data = doc.data() ?? {};
      final currentRole = (data["role"] ?? "employee").toString();
      if (user.email?.toLowerCase() == superAdminEmail && currentRole != "super_admin") {
        await ref.update({"role": "super_admin"});
      }
    }
  }
}
