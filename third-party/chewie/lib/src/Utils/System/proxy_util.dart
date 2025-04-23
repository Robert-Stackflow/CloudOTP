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

import 'package:awesome_chewie/src/Utils/General/string_util.dart';
import 'package:awesome_chewie/src/Utils/System/hive_util.dart';
import 'package:awesome_chewie/src/Utils/ilogger.dart';
import 'package:local_proxy/local_proxy.dart';

import 'package:awesome_chewie/src/Models/selection_item_model.dart';

enum ProxyType {
  FollowSystem('FollowSystem'),
  Custom('Custom'),
  NoProxy('NoProxy');

  final String key;

  const ProxyType(this.key);

  static fromString(String value) {
    switch (value) {
      case 'FollowSystem':
        return ProxyType.FollowSystem;
      case 'Custom':
        return ProxyType.Custom;
      case 'NoProxy':
        return ProxyType.NoProxy;
      default:
        return ProxyType.NoProxy;
    }
  }

  static List<SelectionItemModel<ProxyType>> options() {
    return [
      SelectionItemModel('Follow System', ProxyType.FollowSystem),
      SelectionItemModel('Custom', ProxyType.Custom),
      SelectionItemModel('No Proxy', ProxyType.NoProxy),
    ];
  }
}

class ProxyConfig {
  ProxyType proxyType;
  String? httpProxy;

  ProxyConfig({required this.proxyType, this.httpProxy});

  factory ProxyConfig.fromMap(Map<String, dynamic> map) {
    return ProxyConfig(
      proxyType: ProxyType.fromString(map['proxyType'] ?? ""),
      httpProxy: map['httpProxy'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proxyType': proxyType.key,
      'httpProxy': httpProxy,
    };
  }

  @override
  String toString() {
    return 'ProxyConfig{proxyType: $proxyType, httpProxy: $httpProxy}';
  }
}

class CustomProxyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => ProxyUtil.dioProxy;
    return client;
  }
}

class ProxyUtil {
  static String dioProxy = "DIRECT";

  static refresh() async {
    dioProxy = await getDioProxy();
    ILogger.info("ProxyUtil", "Dio Proxy: $dioProxy");
    HttpOverrides.global = CustomProxyHttpOverrides();
  }

  static Future<String?> getSystemProxy() async {
    ProxySetting? proxySettings = await LocalProxy.getProxySettings();
    ILogger.info("ProxyUtil", "System Proxy: ${proxySettings?.toString()}");
    return proxySettings?.toString();
  }

  static Future<String> getDioProxy() async {
    ProxyConfig proxyConfig = ChewieHiveUtil.getProxyConfig() ??
        ProxyConfig(proxyType: ProxyType.NoProxy);
    String? systemProxy = await getSystemProxy();
    if (proxyConfig.proxyType == ProxyType.FollowSystem) {
      return systemProxy.notNullOrEmpty ? 'PROXY $systemProxy' : 'DIRECT';
    } else if (proxyConfig.proxyType == ProxyType.Custom) {
      return proxyConfig.httpProxy.notNullOrEmpty
          ? 'PROXY ${proxyConfig.httpProxy}'
          : 'DIRECT';
    } else {
      return 'DIRECT';
    }
  }
}
