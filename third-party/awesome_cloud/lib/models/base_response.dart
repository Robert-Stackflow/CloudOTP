/*
 * Copyright (c) 2025 Robert-Stackflow.
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

import 'dart:typed_data';

import 'package:awesome_cloud/awesome_cloud.dart';
import 'package:http/http.dart' as http;

class BaseCloudUserInfo {}

class BaseCloudFileInfo {}

class BaseCloudResponse<U extends BaseCloudUserInfo,
    F extends BaseCloudFileInfo> {
  final ResponseStatus status;
  final int? statusCode;
  final String? body;
  final Uint8List? bodyBytes;
  final String? message;
  final bool isSuccess;
  final U? userInfo;
  final List<F> files;
  final String? parentId;

  BaseCloudResponse({
    required this.status,
    this.statusCode,
    this.body,
    this.bodyBytes,
    this.message,
    required this.isSuccess,
    this.userInfo,
    this.parentId,
    this.files = const [],
  });

  BaseCloudResponse.success({
    this.status = ResponseStatus.success,
    this.statusCode,
    this.body,
    this.bodyBytes,
    this.message,
    this.userInfo,
    this.parentId,
    this.files = const [],
  }) : isSuccess = true;

  BaseCloudResponse.error({
    this.status = ResponseStatus.connectionError,
    this.statusCode,
    this.body,
    this.bodyBytes,
    this.message,
    this.userInfo,
    this.parentId,
    this.files = const [],
  }) : isSuccess = false;

  BaseCloudResponse.fromResponse({
    required http.Response response,
    this.userInfo,
    this.parentId,
    this.message,
    this.files = const [],
  })  : body = response.body,
        statusCode = response.statusCode,
        bodyBytes = response.bodyBytes,
        isSuccess = response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204,
        status = ResponseStatus.values.firstWhere(
            (element) => element.code == response.statusCode,
            orElse: () => ResponseStatus.success);

  @override
  String toString() {
    return "BaseResponse("
        "statusCode: $statusCode, "
        "body: $body, "
        "bodyBytes: $bodyBytes, "
        "message: $message, "
        "isSuccess: $isSuccess"
        ")";
  }
}
