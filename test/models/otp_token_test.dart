import 'package:cloudotp/Models/opt_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editing clones and copies notes without sharing mutable tags', () {
    final original = OtpToken.init(issuer: 'Example')
      ..description = 'Recovery phone is in the safe'
      ..tags = ['work', 'admin'];

    final editingCopy = original.clone() as OtpToken;
    expect(editingCopy.description, original.description);
    expect(editingCopy.tags, original.tags);

    editingCopy.description = 'Updated note';
    editingCopy.tags.add('updated');
    expect(original.description, 'Recovery phone is in the safe');
    expect(original.tags, ['work', 'admin']);

    original.copyFrom(editingCopy);
    expect(original.description, 'Updated note');
    expect(original.tags, ['work', 'admin', 'updated']);

    editingCopy.tags.add('independent');
    expect(original.tags, isNot(contains('independent')));
  });
}
