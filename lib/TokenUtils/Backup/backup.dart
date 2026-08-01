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

import 'dart:convert';

import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';

class Backup {
  static const int currentSchemaVersion = 2;
  static const int maxTokenEntries = 50000;
  static const int maxCategoryEntries = 10000;
  static const int maxBindingEntries = 500000;

  final List<OtpToken> tokens;
  final List<TokenCategory> categories;
  final int schemaVersion;
  final int createdAt;
  final String appVersion;
  final String sourceDevice;

  String get json => jsonEncode(toJson());

  Backup({
    required this.tokens,
    required this.categories,
    this.schemaVersion = currentSchemaVersion,
    int? createdAt,
    this.appVersion = '',
    this.sourceDevice = '',
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'createdAt': createdAt,
      'appVersion': appVersion,
      'sourceDevice': sourceDevice,
      'tokenCount': tokens.length,
      'categoryCount': categories.length,
      'bindingCount': categories.fold<int>(
        0,
        (count, category) => count + category.bindings.length,
      ),
      'tokens': tokens.map((e) => e.toMap()).toList(),
      'categories': categories.map((e) => e.toMapWithBindings()).toList(),
    };
  }

  static Backup fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] ?? 1;
    if (schemaVersion is! int || schemaVersion < 1) {
      throw const BackupFormatException('Invalid backup schema version');
    }
    if (schemaVersion > currentSchemaVersion) {
      throw BackupSchemaUnsupportedException(schemaVersion);
    }
    final tokenData = json['tokens'] ?? const [];
    final categoryData = json['categories'] ?? const [];
    if (tokenData is! List || categoryData is! List) {
      throw const BackupFormatException(
        'Backup tokens and categories must be lists',
      );
    }
    if (tokenData.length > maxTokenEntries) {
      throw const BackupLimitExceededException('tokens');
    }
    if (categoryData.length > maxCategoryEntries) {
      throw const BackupLimitExceededException('categories');
    }
    final tokens = tokenData.map(_parseToken).toList();
    final categories = categoryData.map(_parseCategory).toList();
    final bindingCount = categories.fold<int>(
      0,
      (count, category) => count + category.bindings.length,
    );
    if (bindingCount > maxBindingEntries) {
      throw const BackupLimitExceededException('bindings');
    }
    _validateCount(json, 'tokenCount', tokens.length);
    _validateCount(json, 'categoryCount', categories.length);
    _validateCount(
      json,
      'bindingCount',
      bindingCount,
    );
    return Backup(
      tokens: tokens,
      categories: categories,
      schemaVersion: schemaVersion,
      createdAt: _optionalInt(json, 'createdAt') ?? 0,
      appVersion: _optionalString(json, 'appVersion'),
      sourceDevice: _optionalString(json, 'sourceDevice'),
    );
  }

  static OtpToken _parseToken(dynamic value) {
    try {
      if (value is String) return OtpToken.fromJson(value);
      if (value is Map) {
        return OtpToken.fromMap(Map<String, dynamic>.from(value));
      }
    } catch (e) {
      throw BackupFormatException('Invalid token entry: $e');
    }
    throw const BackupFormatException('Invalid token entry');
  }

  static TokenCategory _parseCategory(dynamic value) {
    try {
      if (value is String) return TokenCategory.fromJson(value);
      if (value is Map) {
        return TokenCategory.fromMap(Map<String, dynamic>.from(value));
      }
    } catch (e) {
      throw BackupFormatException('Invalid category entry: $e');
    }
    throw const BackupFormatException('Invalid category entry');
  }

  static void _validateCount(
    Map<String, dynamic> json,
    String key,
    int actual,
  ) {
    if (!json.containsKey(key)) return;
    final expected = json[key];
    if (expected is! int || expected < 0 || expected != actual) {
      throw BackupFormatException('Backup $key does not match its content');
    }
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int && value >= 0) return value;
    throw BackupFormatException('Backup $key is invalid');
  }

  static String _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return '';
    if (value is String) return value;
    throw BackupFormatException('Backup $key is invalid');
  }
}

class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => 'BackupFormatException: $message';
}

class BackupSchemaUnsupportedException extends BackupFormatException {
  final int schemaVersion;

  BackupSchemaUnsupportedException(this.schemaVersion)
      : super('Unsupported backup schema version: $schemaVersion');
}

class BackupLimitExceededException extends BackupFormatException {
  final String entryType;

  const BackupLimitExceededException(this.entryType)
      : super('Backup contains too many $entryType');
}
