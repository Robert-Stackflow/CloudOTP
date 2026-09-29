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

class RegexUtil {
  static final RegExp _dnsLabel =
      RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$');

  static bool isUrlOrIp(String text, {bool requireScheme = false}) {
    final value = text.trim();
    if (value.isEmpty || value.contains(RegExp(r'\s'))) return false;
    if (requireScheme && !value.contains('://')) return false;

    final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return false;
    }

    try {
      if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) return false;
    } on FormatException {
      return false;
    }

    final host = uri.host;
    if (host.contains(':')) return true; // URI parsing validates IPv6 literals.
    if (host.length > 253) return false;
    final labels = host.split('.');
    if (labels.every((label) => int.tryParse(label) != null)) {
      return labels.length == 4 &&
          labels.every((label) {
            final octet = int.tryParse(label);
            return octet != null && octet >= 0 && octet <= 255;
          });
    }
    return labels.every(_dnsLabel.hasMatch);
  }
}
