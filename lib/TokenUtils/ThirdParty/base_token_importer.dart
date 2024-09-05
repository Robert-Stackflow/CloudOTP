import 'package:cloudotp/Models/token_category_binding.dart';

import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';
import '../../generated/l10n.dart';
import '../import_token_util.dart';

enum DecryptResult {
  success,
  noFileInZip,
  invalidPasswordOrDataCorrupted,
}

abstract class BaseTokenImporter {
  Future<void> importFromPath(
    String path, {
    bool showLoading = true,
  });

  static importResult(ImporterResult res) async {
    ImportAnalysis analysis = ImportAnalysis();
    analysis.parseSuccess = res.tokens.length;
    analysis.parseCategorySuccess = res.categories.length;
    for (TokenCategoryBinding binding in res.bindings) {
      res.categories
          .where((element) => element.uid == binding.categoryUid)
          .forEach((element) {
        element.bindings.add(binding.tokenUid);
      });
    }
    ImportAnalysis tmpAnalysis = await ImportTokenUtil.mergeTokensAndCategories(
      res.tokens,
      res.categories,
    );
    analysis.importSuccess = tmpAnalysis.importSuccess;
    analysis.importCategorySuccess = tmpAnalysis.importCategorySuccess;
    analysis.showToast(S.current.fileDoesNotContainToken);
  }
}

class ImporterResult {
  final List<OtpToken> tokens;
  final List<TokenCategory> categories;
  final List<TokenCategoryBinding> bindings;

  ImporterResult(this.tokens, this.categories, this.bindings);
}
