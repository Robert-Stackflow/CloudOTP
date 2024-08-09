import 'dart:convert';

import 'package:cloudotp/Models/cloud_service_config.dart';

import '../../Models/category.dart';
import '../../Models/config.dart';
import '../../Models/opt_token.dart';

class Backup {
  final List<OtpToken> tokens;
  final List<TokenCategory> categories;
  final Config config;
  final List<CloudServiceConfig> cloudServiceConfigs;

  String get json => jsonEncode(toJson());

  Backup({
    required this.tokens,
    required this.categories,
    required this.cloudServiceConfigs,
    required this.config,
  });

  Map<String, dynamic> toJson() {
    return {
      'tokens': tokens.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'cloudServiceConfigs':
          cloudServiceConfigs.map((e) => e.toJson()).toList(),
      'config': config.toJson(),
    };
  }

  static Backup fromJson(Map<String, dynamic> json) {
    return Backup(
        tokens: json['tokens'] != null
            ? (json['tokens'] as List).map((e) => OtpToken.fromJson(e)).toList()
            : [],
        categories: json['categories'] != null
            ? (json['categories'] as List)
                .map((e) => TokenCategory.fromJson(e))
                .toList()
            : [],
        cloudServiceConfigs: json['cloudServiceConfigs'] != null
            ? (json['cloudServiceConfigs'] as List)
                .map((e) => CloudServiceConfig.fromJson(e))
                .toList()
            : [],
        config: json['config']!=null?Config.fromJson(json['config']):Config()
    );
  }
}
