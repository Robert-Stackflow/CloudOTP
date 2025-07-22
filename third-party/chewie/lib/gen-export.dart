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

void main() {
  const exportFileName = 'index.dart';
  final currentDir = Directory.current;

  final buffer = StringBuffer();

  // 添加文件头版权注释
  buffer.writeln('/*');
  buffer.writeln(' * Copyright (c) 2025 Robert-Stackflow.');
  buffer.writeln(' *');
  buffer.writeln(
      ' * This program is free software: you can redistribute it and/or modify it under the terms of the');
  buffer.writeln(
      ' * GNU General Public License as published by the Free Software Foundation, either version 3 of the');
  buffer.writeln(' * License, or (at your option) any later version.');
  buffer.writeln(' *');
  buffer.writeln(
      ' * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without');
  buffer.writeln(
      ' * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the');
  buffer.writeln(' * GNU General Public License for more details.');
  buffer.writeln(' *');
  buffer.writeln(
      ' * You should have received a copy of the GNU General Public License along with this program.');
  buffer.writeln(' * If not, see <https://www.gnu.org/licenses/>.');
  buffer.writeln(' */\n');

  for (final entity in currentDir.listSync(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith(exportFileName) &&
        !entity.path.endsWith('gen-export.dart')) {
      final relativePath = entity.path
          .replaceFirst('${currentDir.path}${Platform.pathSeparator}', '');
      buffer.writeln("export '${relativePath.replaceAll('\\', '/')}';");
    }
  }

  final exportFile =
      File('${currentDir.path}${Platform.pathSeparator}$exportFileName');
  exportFile.writeAsStringSync(buffer.toString());

  print('✅ Export statements written to $exportFileName');
}
