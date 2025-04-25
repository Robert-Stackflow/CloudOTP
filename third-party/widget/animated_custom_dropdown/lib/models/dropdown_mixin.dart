mixin DropdownMixin {
  String get display;

  String get selection => display;
}

class StringDropdownItem implements DropdownMixin {
  final String value;

  StringDropdownItem(this.value);

  @override
  String get display => value;

  @override
  String get selection => value;

  @override
  bool operator ==(Object other) {
    return other is StringDropdownItem && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

extension StringToSelectionItem on String {
  StringDropdownItem toSelectionItem() {
    return StringDropdownItem(this);
  }
}
