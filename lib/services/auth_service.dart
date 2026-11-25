import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static bool _googleInicializado = false;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _firestore.collection('users');

  User? get usuarioAtual => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _inicializarGoogle() async {
    if (_googleInicializado) return;
    await _googleSignIn.initialize();
    _googleInicializado = true;
  }

  Future<UserCredential> entrar({
    required String email,
    required String senha,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<UserCredential> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'usuario-nulo',
        message: 'Não foi possível criar a conta.',
      );
    }

    await user.updateDisplayName(nome.trim());
    await _usuarios.doc(user.uid).set({
      'uid': user.uid,
      'displayName': nome.trim(),
      'email': user.email ?? email.trim(),
      'photoUrl': user.photoURL ?? '',
    });

    return credential;
  }

  Future<UserCredential> entrarComGoogle() async {
    final UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await _inicializarGoogle();
      final conta = await _googleSignIn.authenticate();
      final idToken = conta.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-sem-token',
          message: 'Não foi possível obter o token do Google.',
        );
      }
      credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }

    await _garantirPerfil(credential.user);
    return credential;
  }

  Future<void> _garantirPerfil(User? user) async {
    if (user == null) return;
    final doc = _usuarios.doc(user.uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set({
      'uid': user.uid,
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
    });
  }

  Future<UserModel?> perfil() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _usuarios.doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() ?? <String, dynamic>{}, id: doc.id);
  }

  Future<void> atualizarNome(String nome) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final nomeLimpo = nome.trim();
    if (nomeLimpo.isEmpty) return;

    await user.updateDisplayName(nomeLimpo);
    await _usuarios.doc(user.uid).update({'displayName': nomeLimpo});
  }

  Future<void> recuperarSenha(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sair() => _auth.signOut();
}
