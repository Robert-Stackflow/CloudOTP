import 'dart:typed_data';

import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';

abstract class BaseTokenImporter {
  ImporterResult importFromData(Uint8List data);

  Future<ImporterResult> importerFromPath(
    String path, {
    bool showLoading = true,
  });
}

class ImporterResult {
  final List<OtpToken> tokens;
  final List<TokenCategory> categories;

  ImporterResult(this.tokens, this.categories);
}
