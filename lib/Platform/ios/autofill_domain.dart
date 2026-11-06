/// Domain hints are explicitly supplied by the user, never guessed from brands.
String? normalizeAutoFillDomain(String input) {
  if (input.trim().isEmpty) return null;
  final uri = Uri.tryParse(
      input.contains('://') ? input.trim() : 'https://${input.trim()}');
  if (uri == null ||
      !['https', 'http'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.hasPort) {
    return null;
  }
  final host = uri.host.toLowerCase();
  if (host.length > 253 || !host.contains('.')) return null;
  final label = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');
  if (!host.split('.').every(label.hasMatch)) return null;
  return host;
}
