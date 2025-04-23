class SortableItem {
  String id;
  int index;
  bool hidden;
  bool canBeHidden;
  String lightIcon;
  String lightSelectedIcon;
  String darkIcon;
  String darkSelectedIcon;
  String? label;

  SortableItem({
    required this.id,
    required this.index,
    required this.hidden,
    required this.lightIcon,
    required this.lightSelectedIcon,
    required this.darkIcon,
    required this.darkSelectedIcon,
    this.canBeHidden = true,
  });

  @override
  String toString() {
    return 'SortableItem{id: $id, index: $index, hidden: $hidden, canBeHidden: $canBeHidden, lightIcon: $lightIcon, lightSelectedIcon: $lightSelectedIcon, darkIcon: $darkIcon, darkSelectedIcon: $darkSelectedIcon}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'hidden': hidden,
      'canBeHidden': canBeHidden,
      'lightIcon': lightIcon,
      'lightSelectedIcon': lightSelectedIcon,
      'darkIcon': darkIcon,
      'darkSelectedIcon': darkSelectedIcon,
    };
  }

  factory SortableItem.fromJson(Map<String, dynamic> json) {
    return SortableItem(
      id: json['id'],
      index: json['index'],
      hidden: json['hidden'],
      canBeHidden: json['canBeHidden'],
      lightIcon: json['lightIcon'],
      lightSelectedIcon: json['lightSelectedIcon'],
      darkIcon: json['darkIcon'],
      darkSelectedIcon: json['darkSelectedIcon'],
    );
  }
}
