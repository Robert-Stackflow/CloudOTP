part of model;

class ControllerState<ItemsLayerState extends State<StatefulWidget>,
    OverlayedItemsLayerState extends State<StatefulWidget>> {
  ControllerState({this.itemCount});

  GlobalKey<ItemsLayerState> _itemsLayerKey = GlobalKey<ItemsLayerState>();
  GlobalKey<OverlayedItemsLayerState> _overlayedItemsLayerKey =
      GlobalKey<OverlayedItemsLayerState>();

  final _itemByKey = <Key, Item>{};
  final _itemKeyByIndex = SplayTreeMap<int, Key>();
  final _overlayedItemByKey = <Key, OverlayedItem>{};
  final _renderedItemByKey = <Key, RenderedItem>{};
  OverlayedItem? draggedItem;
  OverlayedItem? swipedItem;
  Key? itemUnderThePointerKey;
  int? itemCount;
  BoxConstraints? constraints;
  SliverGridLayout? gridLayout;
  Offset scrollOffset = Offset.zero;
  bool shiftItemsOnScroll = true;

  GlobalKey<ItemsLayerState> get itemsLayerKey => _itemsLayerKey;

  ItemsLayerState? get itemsLayerState => itemsLayerKey.currentState;

  GlobalKey<OverlayedItemsLayerState> get overlayedItemsLayerKey =>
      _overlayedItemsLayerKey;

  OverlayedItemsLayerState? get overlayedItemsLayerState =>
      overlayedItemsLayerKey.currentState;

  Iterable<Item> get items => _itemByKey.values;

  Iterable<OverlayedItem> get overlayedItems => _overlayedItemByKey.values;

  Iterable<RenderedItem> get renderedItems => _renderedItemByKey.values;

  bool isDragged({required Key key}) => key == draggedItem?.key;

  bool isSwiped({required Key key}) => key == swipedItem?.key;

  Iterable<(int, Item)> iterator() => _itemKeyByIndex.entries.map(
        (e) => (e.key, itemBy(key: e.value)!),
      );

  Item? itemAt({required int index}) =>
      itemBy(key: _itemKeyByIndex[index] ?? UniqueKey());

  Item? itemBy({required Key key}) => _itemByKey[key];

  Item putItem(Item x) => _itemByKey[x.key] = x;

  RenderedItem putRenderedItem(RenderedItem x) => _renderedItemByKey[x.key] = x;

  RenderedItem? renderedItemBy({required Key key}) => _renderedItemByKey[key];

  RenderedItem? removeRenderedItemBy({required Key key}) =>
      _renderedItemByKey.remove(key);

  bool isRendered({required Key key}) => _renderedItemByKey.containsKey(key);

  void setIndex({required Key itemKey, required int index}) =>
      _itemKeyByIndex[index] = itemKey;

  bool isOverlayed({required Key key}) => _overlayedItemByKey.containsKey(key);

  bool isOverlayedAt({required int index}) =>
      _overlayedItemByKey.containsKey(_itemKeyByIndex[index] ?? -1);

  OverlayedItem? overlayedItemBy({required Key key}) =>
      _overlayedItemByKey[key];

  OverlayedItem putOverlayedItem(OverlayedItem x) {
    _overlayedItemByKey.remove(x.key);
    return _overlayedItemByKey[x.key] = x;
  }

  OverlayedItem putOverlayedItemIfAbsent(
          {required Key key, required OverlayedItem Function() ifAbsent}) =>
      putOverlayedItem(overlayedItemBy(key: key) ?? ifAbsent());

  OverlayedItem? removeOverlayedItem({required Key key}) =>
      _overlayedItemByKey.remove(key);

  RenderedItem? renderedItemAt({required Offset position}) =>
      renderedItems.where((x) => x.contains(position)).firstOrNull;

  Item insertItem({
    required int index,
    required Item Function(int index) itemFactory,
  }) {
    for (var i in _itemKeyByIndex.keys.toList().reversed) {
      if (i < index) break;
      _itemKeyByIndex[i + 1] = _itemKeyByIndex[i]!;
    }

    for (var overlayedItem in overlayedItems) {
      if (overlayedItem.index >= index) {
        overlayedItem.index++;
      }
    }

    final item = itemFactory.call(index);

    _itemByKey[item.key] = item;
    _itemKeyByIndex[index] = item.key;

    itemCount = itemCount! + 1;

    return item;
  }

  Item? removeItem({required int index}) {
    final key = _itemKeyByIndex.remove(index);

    itemCount = itemCount! - 1;

    int? lastIndex;
    for (var i in _itemKeyByIndex.keys.toList()) {
      if (i > index) {
        _itemKeyByIndex[i - 1] = _itemKeyByIndex[i]!;
        lastIndex = i;
      }
    }
    _itemKeyByIndex.remove(lastIndex);

    for (var overlayedItem in overlayedItems) {
      if (overlayedItem.index > index) {
        overlayedItem.index--;
      }
    }

    return _itemByKey.remove(key);
  }

  Permutations moveItem({
    required int index,
    required int destIndex,
    required bool Function(int index) reorderableGetter,
    required Item Function(int index) itemFactory,
  }) {
    final permutations = Permutations();
    if (index == destIndex) return permutations;

    increment(int i) => i + 1;
    decrement(int i) => i - 1;
    final nextIndex = index > destIndex ? increment : decrement;
    var curItem = itemAt(index: index) ?? putItem(itemFactory(index));
    Key unorderedItemKey = curItem.key;
    int unorderedItemIndex = index;

    for (var curIndex = destIndex;; curIndex = nextIndex(curIndex)) {
      curItem = itemAt(index: curIndex) ?? putItem(itemFactory(curIndex));

      if (reorderableGetter(curIndex)) {
        _itemKeyByIndex[curIndex] = unorderedItemKey;

        permutations.addPermutation(
          itemKey: unorderedItemKey,
          srcIndex: unorderedItemIndex,
          destIndex: curIndex,
        );

        unorderedItemKey = curItem.key;
        unorderedItemIndex = curIndex;
      }

      if (curIndex == index) break;
    }

    for (var overlayedItem in overlayedItems) {
      overlayedItem.index =
          permutations.indexOf(overlayedItem.key) ?? overlayedItem.index;
    }

    return permutations;
  }

  void reset() {
    _itemsLayerKey = GlobalKey<ItemsLayerState>();
    _overlayedItemsLayerKey = GlobalKey<OverlayedItemsLayerState>();
    _itemByKey.clear();
    _overlayedItemByKey.clear();
    _itemKeyByIndex.clear();
    _renderedItemByKey.clear();
    draggedItem = null;
    swipedItem = null;
    itemUnderThePointerKey = null;
    itemCount = null;
    constraints = null;
    scrollOffset = Offset.zero;
    shiftItemsOnScroll = true;
    gridLayout = null;
  }

  void dispose() {
    for (var x in items) {
      x.dispose();
    }
    for (var x in overlayedItems) {
      x.dispose();
    }
    reset();
  }
}
