import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import '../database/app_db.dart';

class AuthRepository {
  final AppDb db;
  AuthRepository(this.db);

  String _hash(String pw) => sha256.convert(utf8.encode(pw)).toString();

  Future<User?> login(String username, String password) =>
      (db.select(db.users)
            ..where((u) =>
                u.username.equals(username) &
                u.passwordHash.equals(_hash(password))))
          .getSingleOrNull();

  Future<int> register(String username, String password,
          {String role = 'cashier'}) =>
      db.into(db.users).insert(UsersCompanion.insert(
          username: username,
          passwordHash: _hash(password),
          role: Value(role)));
}
