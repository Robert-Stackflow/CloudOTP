part of '../../../custom_dropdown.dart';

class _SearchField<T> extends StatefulWidget {
  final List<T> items;
  final ValueChanged<List<T>> onSearchedItems;
  final String searchHintText;
  final _SearchType? searchType;
  final Future<List<T>> Function(String)? futureRequest;
  final Duration? futureRequestDelay;
  final ValueChanged<bool>? onFutureRequestLoading, mayFoundResult;
  final SearchFieldDecoration? decoration;

  const _SearchField.forListData({
    super.key,
    required this.items,
    required this.onSearchedItems,
    required this.searchHintText,
    required this.decoration,
  })  : searchType = _SearchType.onListData,
        futureRequest = null,
        futureRequestDelay = null,
        onFutureRequestLoading = null,
        mayFoundResult = null;

  const _SearchField.forRequestData({
    super.key,
    required this.items,
    required this.onSearchedItems,
    required this.searchHintText,
    required this.futureRequest,
    required this.futureRequestDelay,
    required this.onFutureRequestLoading,
    required this.mayFoundResult,
    required this.decoration,
  }) : searchType = _SearchType.onRequestData;

  @override
  State<_SearchField<T>> createState() => _SearchFieldState<T>();
}

class _SearchFieldState<T> extends State<_SearchField<T>> {
  final searchCtrl = TextEditingController();
  bool isFieldEmpty = false;
  FocusNode focusNode = FocusNode();
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.searchType == _SearchType.onRequestData &&
        widget.items.isEmpty) {
      focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  void onSearch(String query) {
    final result = widget.items.where(
      (item) {
        if (item is CustomDropdownListFilter) {
          return item.filter(query);
        } else {
          return item.toString().toLowerCase().contains(query.toLowerCase());
        }
      },
    ).toList();
    widget.onSearchedItems(result);
  }

  void onClear() {
    if (searchCtrl.text.isNotEmpty) {
      searchCtrl.clear();
      widget.onSearchedItems(widget.items);
    }
  }

  void searchRequest(String val) async {
    List<T> result = [];
    try {
      result = await widget.futureRequest!(val);
      widget.onFutureRequestLoading!(false);
    } catch (_) {
      widget.onFutureRequestLoading!(false);
    }
    widget.onSearchedItems(isFieldEmpty ? widget.items : result);
    widget.mayFoundResult!(result.isNotEmpty);

    if (isFieldEmpty) {
      isFieldEmpty = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        focusNode: focusNode,
        style: widget.decoration?.textStyle,
        cursorColor: Theme.of(context).primaryColor,
        cursorRadius: const Radius.circular(5),
        onChanged: (val) async {
          if (val.isEmpty) {
            isFieldEmpty = true;
          } else if (isFieldEmpty) {
            isFieldEmpty = false;
          }

          if (widget.searchType != null &&
              widget.searchType == _SearchType.onRequestData &&
              val.isNotEmpty) {
            widget.onFutureRequestLoading!(true);

            if (widget.futureRequestDelay != null) {
              _delayTimer?.cancel();
              _delayTimer =
                  Timer(widget.futureRequestDelay ?? Duration.zero, () {
                searchRequest(val);
              });
            } else {
              searchRequest(val);
            }
          } else if (widget.searchType == _SearchType.onListData) {
            onSearch(val);
          } else {
            widget.onSearchedItems(widget.items);
          }
        },
        controller: searchCtrl,
        decoration: InputDecoration(
          filled: true,
          fillColor:
              widget.decoration?.fillColor ?? Theme.of(context).canvasColor,
          constraints: widget.decoration?.constraints ??
              const BoxConstraints.tightFor(height: 40),
          contentPadding:
              widget.decoration?.contentPadding ?? const EdgeInsets.all(8),
          hintText: widget.searchHintText,
          hintStyle: widget.decoration?.hintStyle,
          prefixIcon: widget.decoration?.prefixIcon ??
              const Icon(Icons.search_rounded, size: 20),
          suffixIcon: widget.decoration?.suffixIcon?.call(onClear) ??
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 20),
              ),
          border: widget.decoration?.border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.decoration?.borderColor ??
                      Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
          enabledBorder: widget.decoration?.border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.decoration?.borderColor ??
                      Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
          focusedBorder: widget.decoration?.focusedBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.decoration?.focusedBorderColor ??
                      Theme.of(context).primaryColor,
                  width: 1,
                ),
              ),
        ),
      ),
    );
  }
}
