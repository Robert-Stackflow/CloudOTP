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

import 'dart:typed_data';

import 'package:cloudotp/Models/cloud_service_config.dart';

enum CloudServiceStatus {
  success,
  connectionError,
  unauthorized,
  unknownError,
  expired,
}

abstract class CloudService {
  CloudServiceType get type;

  Future<void> init();

  Future<dynamic> listFiles();

  Future<dynamic> listBackups();

  Future<int> getBackupsCount();

  Future<bool> deleteOldBackup([int? maxCount]);

  Future<bool> uploadFile(
    String fileName,
    Uint8List fileData, {
    Function(int, int)? onProgress,
  });

  Future<Uint8List?> downloadFile(
    String path, {
    Function(int, int)? onProgress,
  });

  Future<bool> deleteFile(String path);

  Future<CloudServiceStatus> authenticate();

  Future<bool> isConnected();

  Future<bool> hasConfigured();

  Future<void> signOut();
}
