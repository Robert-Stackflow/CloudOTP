import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview binding resolution keeps duplicate token relationships', () {
    final backupDuplicate = OtpToken.init()..uid = 'backup-duplicate';
    final localDuplicate = OtpToken.init()..uid = 'local-duplicate';
    final imported = OtpToken.init()..uid = 'resolved-new';
    final skipped = OtpToken.init()..uid = 'backup-skipped';
    final category = TokenCategory.title(title: 'Work')
      ..bindings = [
        'backup-duplicate',
        'backup-new',
        'backup-skipped',
        'orphan',
      ];

    final items = [
      ImportTokenItem(
        token: backupDuplicate,
        existingToken: localDuplicate,
        status: ImportTokenStatus.duplicate,
        selected: false,
      ),
      ImportTokenItem(
        token: imported,
        status: ImportTokenStatus.ready,
        selected: true,
      ),
      ImportTokenItem(
        token: skipped,
        status: ImportTokenStatus.ready,
        selected: false,
      ),
    ];

    ImportTokenUtil.resolvePreviewCategoryBindings(
      [category],
      items,
      originalTokenUids: [
        'backup-duplicate',
        'backup-new',
        'backup-skipped',
      ],
    );

    expect(category.bindings, containsAll(['local-duplicate', 'resolved-new']));
    expect(category.bindings, hasLength(2));
  });

  test('binding resolution leaves legacy callers unchanged without preview',
      () {
    final category = TokenCategory.title(title: 'Personal')
      ..bindings = ['token-a'];

    ImportTokenUtil.resolvePreviewCategoryBindings([category], []);

    expect(category.bindings, ['token-a']);
  });
}
