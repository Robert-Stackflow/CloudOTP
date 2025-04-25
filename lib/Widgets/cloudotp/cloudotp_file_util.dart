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

import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';

class CloudOTPFileUtil {
  static Future<void> deleteDirectory(Directory directory) async {
    if (!await directory.exists()) {
      return;
    }
    List<FileSystemEntity> files = directory.listSync();
    if (files.isNotEmpty) {
      for (var file in files) {
        if (file is File) {
          await file.delete();
        } else if (file is Directory) {
          await deleteDirectory(file);
        }
      }
    }
    await directory.delete();
  }

  static Future<void> migrationDataToSupportDirectory() async {
    try {
      Hive.defaultDirectory = await FileUtil.getHiveDir();
      bool haveMigratedToSupportDirectoryFromHive = ChewieHiveUtil.getBool(
          CloudOTPHiveUtil.haveMigratedToSupportDirectoryKey,
          defaultValue: false);
      if (haveMigratedToSupportDirectoryFromHive) {
        ILogger.info("CloudOTP", "Have migrated data to support directory");
        return;
      }
      Hive.closeAllBoxes();
    } catch (e, t) {
      ILogger.error("Failed to close all hive boxes", e, t);
    }
    Directory oldDir = Directory(await getOldApplicationDir());
    Directory newDir = Directory(await FileUtil.getApplicationDir());
    try {
      if (oldDir.path == newDir.path || await isDirectoryEmpty(oldDir)) {
        return;
      }
      await createBakDir(oldDir, Directory("${newDir.path}-old-bak"));
      bool isNewDirEmpty = await isDirectoryEmpty(newDir);
      if (!isNewDirEmpty) {
        await createBakDir(newDir);
      }
      ILogger.info("CloudOTP",
          "Start to migrate data from old application directory $oldDir to new application directory $newDir");
      await copyDirectoryTo(oldDir, newDir);
      haveMigratedToSupportDirectory = true;
    } catch (e, t) {
      ILogger.error(
          "Failed to migrate data from old application directory", e, t);
    }
    try {
      await deleteDirectory(oldDir);
    } catch (e, t) {
      ILogger.error("Failed to delete old application directory", e, t);
    }
    ILogger.info("CloudOTP",
        "Finish to migrate data from old application directory $oldDir to new application directory $newDir");
    await Future.delayed(const Duration(milliseconds: 200));
  }

  static void showMigrationDialog(BuildContext context) {
    //TODO
  }

  static Future<String> getOldApplicationDir() async {
    final dir = await getApplicationDocumentsDirectory();
    var appName = ResponsiveUtil.appName;
    if (kDebugMode) {
      appName += "-Debug";
    }
    String path = join(dir.path, appName);
    Directory directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return path;
  }

  static Future<bool> isDirectoryEmpty(Directory directory) async {
    if (!await directory.exists()) {
      return true;
    }
    return directory.listSync().isEmpty;
  }

  static Future<void> createBakDir(
    Directory sourceDir, [
    Directory? destDir,
  ]) async {
    Directory directory = destDir ?? Directory("${sourceDir.path}-bak");
    if (await directory.exists()) {
      return;
    } else {
      await directory.create(recursive: true);
    }
    await copyDirectoryTo(sourceDir, directory);
  }

  static Future<void> copyDirectoryTo(
      Directory oldDir, Directory newDir) async {
    ILogger.info(
        "CloudOTP", "Copy directory from ${oldDir.path} to ${newDir.path}");
    if (!await oldDir.exists()) {
      return;
    }
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }
    List<FileSystemEntity> files = oldDir.listSync();
    if (files.isNotEmpty) {
      for (var file in files) {
        if (file is File) {
          String fileName = FileUtil.getFileNameWithExtension(file.path);
          await file.copy(join(newDir.path, fileName));
          ILogger.info(
              "CloudOTP", "Copy file from ${file.path} to ${newDir.path}");
        } else if (file is Directory) {
          String dirName = FileUtil.getFileNameWithExtension(file.path);
          Directory newSubDir = Directory(join(newDir.path, dirName));
          await copyDirectoryTo(file, newSubDir);
        }
      }
    }
  }
}
