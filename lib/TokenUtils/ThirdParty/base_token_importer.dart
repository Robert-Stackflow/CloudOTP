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

import 'package:cloudotp/Models/token_category_binding.dart';

import '../../Models/opt_token.dart';
import '../../Models/token_category.dart';
import '../../l10n/l10n.dart';
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
    analysis.showToast(appLocalizations.fileDoesNotContainToken);
  }
}

class ImporterResult {
  final List<OtpToken> tokens;
  final List<TokenCategory> categories;
  final List<TokenCategoryBinding> bindings;

  ImporterResult(this.tokens, this.categories, this.bindings);
}
