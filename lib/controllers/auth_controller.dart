import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// État d'authentification + profil Firestore (`users/{uid}`).
class AuthController extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final UserService _users = UserService();
  StreamSubscription<User?>? _sub;

  User? firebaseUser;
  AppUser? appUser;
  bool isLoading = true;
  bool isBusy = false; // pendant login/register
  String? error;

  AuthController() {
    _sub = _auth.authState.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    firebaseUser = user;
    if (user == null) {
      appUser = null;
    } else {
      try {
        appUser = await _users.getUser(user.uid);
      } catch (e) {
        error = 'Impossible de charger le profil — vérifiez la connexion.';
      }
    }
    isLoading = false;
    notifyListeners();
  }

  bool get isAuthenticated => firebaseUser != null;
  bool get isSeller => appUser?.role == UserRole.seller;

  Future<bool> signIn(String email, String password) => _run(() async {
        await _auth.signIn(email, password);
      });

  /// Inscription (§4) — crée le compte Auth PUIS le doc Firestore
  /// avec le rôle. Le numéro WhatsApp est exigé pour un vendeur.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String whatsappNumber = '',
  }) =>
      _run(() async {
        if (role == UserRole.seller && whatsappNumber.trim().isEmpty) {
          throw Exception('Le numéro WhatsApp est requis pour un vendeur');
        }
        final cred = await _auth.register(email, password);
        await _users.createUser(AppUser(
          uid: cred.user!.uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          role: role,
          whatsappNumber: _sanitize(whatsappNumber),
        ));
        appUser = await _users.getUser(cred.user!.uid);
      });

  /// Complétion de profil (comptes créés depuis la console Firebase).
  Future<bool> completeProfile({
    required String name,
    required String phone,
    required UserRole role,
    String whatsappNumber = '',
  }) =>
      _run(() async {
        final user = firebaseUser;
        if (user == null) throw Exception('Aucun compte connecté');
        await _users.createUser(AppUser(
          uid: user.uid,
          name: name.trim(),
          email: user.email ?? '',
          phone: phone.trim(),
          role: role,
          whatsappNumber: _sanitize(whatsappNumber),
        ));
        appUser = await _users.getUser(user.uid);
      });

  /// Mise à jour du profil (ex. numéro WhatsApp du vendeur — §3).
  Future<bool> updateProfile({String? name, String? phone, String? whatsapp}) =>
      _run(() async {
        final uid = firebaseUser?.uid;
        if (uid == null) throw Exception('Aucun compte connecté');
        await _users.updateUser(uid, {
          if (name != null) 'name': name.trim(),
          if (phone != null) 'phone': phone.trim(),
          if (whatsapp != null) 'whatsappNumber': _sanitize(whatsapp),
        });
        appUser = await _users.getUser(uid);
      });

  Future<void> logout() => _auth.signOut();

  String _sanitize(String phone) => phone.replaceAll(RegExp(r'[^\d]'), '');

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      error = AuthService.messageOf(e);
    } on FirebaseException catch (e) {
      error = e.code == 'permission-denied'
          ? 'Accès refusé par les règles de sécurité'
          : 'Erreur Firebase — réessayez (${e.code})';
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isBusy = false;
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
