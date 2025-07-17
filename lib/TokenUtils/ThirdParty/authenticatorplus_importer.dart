/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:cloudotp/Database/database_manager.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Models/token_category_binding.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../Utils/Base32/base32.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import '../../l10n/l10n.dart';

enum AuthenticatorType {
  Totp,
  Hotp,
  Blizzard;

  OtpTokenType get tokenType {
    switch (this) {
      case AuthenticatorType.Totp:
        return OtpTokenType.TOTP;
      case AuthenticatorType.Hotp:
        return OtpTokenType.HOTP;
      case AuthenticatorType.Blizzard:
        return OtpTokenType.TOTP;
    }
  }
}

class AuthenticatorPlusToken {
  static const String _blizzardIssuer = "Blizzard";
  static const OtpDigits _blizzardDigits = OtpDigits.D8;

  final String uid;
  final String email;
  final String secret;
  final int counter;
  final AuthenticatorType type;
  final String issuer;
  final String originalName;
  final String categoryName;

  AuthenticatorPlusToken({
    required this.email,
    required this.secret,
    required this.counter,
    required this.type,
    required this.issuer,
    required this.originalName,
    required this.categoryName,
  }) : uid = StringUtil.generateUid();

  factory AuthenticatorPlusToken.fromMap(Map<String, dynamic> map) {
    return AuthenticatorPlusToken(
      email: map['email'] as String,
      secret: map['secret'] as String,
      counter: map['counter'] as int,
      type: AuthenticatorType.values[map['type'] as int],
      issuer: map['issuer'] as String,
      originalName: map['original_name'] as String,
      categoryName: map['category'] as String,
    );
  }

  String _convertSecret(AuthenticatorType type) {
    if (this.type == AuthenticatorType.Blizzard) {
      final bytes = hex.decode(secret);
      final base32Secret = base32.encode(Uint8List.fromList(bytes));
      return base32Secret;
    }
    return secret;
  }

  OtpToken toOtpToken() {
    String issuer = "";
    String? username;
    if (issuer.isNotEmpty) {
      issuer =
          type == AuthenticatorType.Blizzard ? _blizzardIssuer : this.issuer;
      if (email.isNotEmpty) {
        username = email;
      }
    } else {
      final originalNameParts = originalName.split(':');
      if (originalNameParts.length == 2) {
        issuer = originalNameParts[0];
        if (issuer.isEmpty) {
          issuer = email;
        } else {
          username = email;
        }
      } else {
        issuer = email;
      }
    }
    final secret = _convertSecret(type);
    OtpToken token = OtpToken.init();
    token.uid = uid;
    token.issuer = issuer;
    token.account = username ?? "";
    token.secret = secret;
    token.tokenType = type.tokenType;
    token.counterString = counter > 0
        ? counter.toString()
        : token.tokenType.defaultDigits.toString();
    token.digits = type == AuthenticatorType.Blizzard
        ? _blizzardDigits
        : token.tokenType.defaultDigits;
    token.algorithm = OtpAlgorithm.fromString("SHA1");
    token.periodString = token.tokenType.defaultPeriod.toString();
    return token;
  }
}

class AuthenticatorPlusGroup {
  String id;
  String name;

  AuthenticatorPlusGroup({
    required this.id,
    required this.name,
  });

  TokenCategory toTokenCategory() {
    return TokenCategory.title(
      tUid: id,
      title: name,
    );
  }

  factory AuthenticatorPlusGroup.fromJson(Map<String, dynamic> json) {
    return AuthenticatorPlusGroup(
      id: StringUtil.generateUid(),
      name: json['name'],
    );
  }
}

class AuthenticatorPlusTokenImporter implements BaseTokenImporter {
  static const String baseAlgorithm = 'AES';
  static const String mode = 'GCM';
  static const String padding = 'NoPadding';
  static const String algorithmDescription = '$baseAlgorithm/$mode/$padding';

  static const int iterations = 10000;
  static const int keyLength = 32;

  Future<ImporterResult> _convertFromConnectionAsync(Database database) async {
    final sourceAccounts = await database.query('accounts');
    final sourceCategories = await database.query('category');

    final authenticators = <AuthenticatorPlusToken>[];
    final categories = sourceCategories
        .map((row) => AuthenticatorPlusGroup.fromJson(row))
        .toList();
    final bindings = <TokenCategoryBinding>[];

    for (final accountRow in sourceAccounts) {
      try {
        final account = AuthenticatorPlusToken.fromMap(accountRow);

        if (account.categoryName != "All Accounts") {
          late final AuthenticatorPlusGroup? category;
          try {
            categories.firstWhere((c) => c.name == account.categoryName);
          } catch (e) {
            category = null;
          }
          if (category == null) continue;

          final binding = TokenCategoryBinding(
            tokenUid: account.uid,
            categoryUid: category.id,
          );

          bindings.add(binding);
        }
      } catch (e, t) {
        debugPrint("Failed to convert account: $e\n$t");
      }
    }

    final backup = ImporterResult(
      authenticators.map((e) => e.toOtpToken()).toList(),
      categories.map((e) => e.toTokenCategory()).toList(),
      bindings,
    );

    return backup;
  }

  @override
  Future<void> importFromPath(
    String path, {
    bool showLoading = true,
  }) async {
    late ProgressDialog dialog;
    if (showLoading) {
      dialog = showProgressDialog(appLocalizations.importing, showProgress: false);
    }
    try {
      File file = File(path);
      if (!file.existsSync()) {
        IToast.showTop(appLocalizations.fileNotExist);
      } else {
        try {
          final path = join(await FileUtil.getDatabaseDir(),
              '${DateTime.now().millisecondsSinceEpoch}.db');
          await file.copy(path);
          String password = "";
          final database = await DatabaseManager.cipherDbFactory.openDatabase(
            path,
            options: OpenDatabaseOptions(
              version: 1,
              singleInstance: true,
              onConfigure: (db) async {
                await db.execute('PRAGMA cipher_compatibility = 3');
                await db.rawQuery("PRAGMA KEY='$password'");
              },
            ),
          );
          try {
            ImporterResult result = await _convertFromConnectionAsync(database);
            await BaseTokenImporter.importResult(result);
          } catch (e) {
            IToast.showTop(appLocalizations.importFailed);
          } finally {
            await database.close();
          }
        } finally {
          File(path).deleteSync();
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to import from 2FAS", e, t);
      IToast.showTop(appLocalizations.importFailed);
    } finally {
      if (showLoading) {
        dialog.dismiss();
      }
    }
  }
}
