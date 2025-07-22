import 'package:awesome_chewie/awesome_chewie.dart';

class SelectionItemModel<T> with DropdownMixin {
  String key;
  T value;

  SelectionItemModel(this.key, this.value);

  @override
  String toString() {
    return key;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SelectionItemModel<T> &&
        other.key == key &&
        other.value == value;
  }

  @override
  int get hashCode => super.hashCode + key.hashCode + value.hashCode;

  @override
  String get display => key;
}
