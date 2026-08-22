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

import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/TokenUtils/ThirdParty/base_token_importer.dart';
import 'package:cloudotp/TokenUtils/import_token_util.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Widgets/cloudotp/cloudotp_item_builder.dart';
import '../../l10n/l10n.dart';

class ImportPreviewScreen extends StatefulWidget {
  final List<OtpToken> tokens;
  final List<TokenCategory> categories;
  final List<ImportTokenError> errors;

  const ImportPreviewScreen({
    super.key,
    required this.tokens,
    required this.categories,
    this.errors = const [],
  });

  static void show({
    required List<OtpToken> tokens,
    required List<TokenCategory> categories,
    List<ImportTokenError> errors = const [],
  }) {
    if (tokens.isEmpty && errors.isEmpty && categories.isEmpty) {
      IToast.showTop(appLocalizations.importNoTokens);
      return;
    }
    RouteUtil.pushDialogRoute(
      chewieProvider.rootContext,
      ImportPreviewScreen(
        tokens: tokens,
        categories: categories,
        errors: errors,
      ),
    );
  }

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends BaseDynamicState<ImportPreviewScreen> {
  List<ImportTokenItem> _tokenItems = [];
  List<ImportCategoryItem> _categoryItems = [];
  bool _loading = true;
  bool _overwriteExisting = false;
  late SelectionItemModel<bool> _keepLocalOption;
  late SelectionItemModel<bool> _overwriteLocalOption;
  SelectionItemModel<bool>? _currentMergeOption;

  bool get _hasCategories => widget.categories.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _keepLocalOption =
        SelectionItemModel(appLocalizations.importKeepLocal, false);
    _overwriteLocalOption =
        SelectionItemModel(appLocalizations.importOverwriteLocal, true);
    _currentMergeOption = _keepLocalOption;
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final tokenItems = await ImportTokenUtil.previewImport(
      widget.tokens,
      errors: widget.errors,
    );
    List<ImportCategoryItem> categoryItems = [];
    if (_hasCategories) {
      categoryItems =
          await ImportTokenUtil.previewCategories(widget.categories);
    }
    tokenItems.sort((a, b) => a.status.index.compareTo(b.status.index));
    setState(() {
      _tokenItems = tokenItems;
      _categoryItems = categoryItems;
      _loading = false;
    });
  }

  int get _selectedTokenCount => _tokenItems.where((e) => e.selected).length;

  int get _selectedCategoryCount =>
      _categoryItems.where((e) => e.selected).length;

  int get _totalSelectedCount => _selectedTokenCount + _selectedCategoryCount;

  List<OtpToken> get _selectedTokens =>
      _tokenItems.where((e) => e.selected).map((e) => e.token).toList();

  List<TokenCategory> get _selectedCategories =>
      _categoryItems.where((e) => e.selected).map((e) => e.category).toList();

  bool get _allTokensSelectableSelected => _tokenItems
      .where((e) => e.status != ImportTokenStatus.error)
      .every((e) => e.selected);

  bool get _allCategoriesSelected =>
      _categoryItems.isEmpty || _categoryItems.every((e) => e.selected);

  bool get _allSelected =>
      _allTokensSelectableSelected && _allCategoriesSelected;

  String get _buttonText {
    if (_selectedTokenCount > 0 && _selectedCategoryCount > 0) {
      return appLocalizations.importSelectedBothCount(
          _selectedTokenCount, _selectedCategoryCount);
    } else if (_selectedCategoryCount > 0) {
      return appLocalizations
          .importSelectedCategoryCount(_selectedCategoryCount);
    } else {
      return appLocalizations.importSelectedCount(_selectedTokenCount);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      bool selectAll = !_allSelected;
      for (var item in _tokenItems) {
        if (item.status != ImportTokenStatus.error) {
          item.selected = selectAll;
        }
      }
      for (var item in _categoryItems) {
        item.selected = selectAll;
      }
    });
  }

  void _setOverwrite(bool overwrite) {
    setState(() {
      _overwriteExisting = overwrite;
      _currentMergeOption =
          overwrite ? _overwriteLocalOption : _keepLocalOption;
      for (var item in _tokenItems) {
        if (item.status == ImportTokenStatus.duplicate) {
          item.selected = _overwriteExisting;
        }
      }
      for (var item in _categoryItems) {
        if (!item.isNew) {
          item.selected = _overwriteExisting;
        }
      }
    });
  }

  Future<void> _confirmImport() async {
    if (_totalSelectedCount == 0) return;
    if (_overwriteExisting && !await _confirmOverwriteImport()) return;
    if (!mounted) return;
    CustomLoadingDialog.showLoading(title: appLocalizations.importing);
    try {
      final selectedCategories = _selectedCategories;
      ImportAnalysis analysis = await ImportTokenUtil.confirmImport(
        _selectedTokens,
        selectedCategories,
        overwriteExisting: _overwriteExisting,
        tokenItems: _tokenItems,
        categoryItems: _categoryItems,
      );
      CustomLoadingDialog.dismissLoading();
      analysis.showToast(appLocalizations.importNoTokens);
      if (mounted) Navigator.of(context).pop();
    } catch (e, t) {
      CustomLoadingDialog.dismissLoading();
      ILogger.error("Failed to confirm import", e, t);
      IToast.showTop(appLocalizations.importFailed);
    }
  }

  Future<bool> _confirmOverwriteImport() {
    final completer = Completer<bool>();
    DialogBuilder.showConfirmDialog(
      context,
      title: appLocalizations.importOverwriteLocal,
      message: appLocalizations.importOverwriteWarning,
      barrierDismissible: false,
      customDialogType: CustomDialogType.warning,
      confirmButtonText: appLocalizations.confirm,
      cancelButtonText: appLocalizations.cancel,
      onTapConfirm: () => completer.complete(true),
      onTapCancel: () => completer.complete(false),
    );
    return completer.future;
  }

  String _buildCategoryBindingText(ImportCategoryItem item) {
    final bindings = item.category.bindings;
    if (bindings.isEmpty) return "";
    List<String> names = [];
    for (String uid in bindings) {
      final match = _tokenItems.where((t) => t.token.uid == uid);
      if (match.isNotEmpty) {
        final token = match.first.token;
        names.add(token.issuer.isNotEmpty ? token.issuer : token.account);
      }
    }
    if (names.isEmpty) return "";
    final count = names.length;
    if (count <= 3) {
      return appLocalizations.importCategoryContains(names.join(", "), count);
    } else {
      final displayNames = names.take(3).join(", ");
      return appLocalizations.importCategoryContainsMore(displayNames, count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ResponsiveAppBar(
        title: appLocalizations.importPreview,
        showBack: ResponsiveUtil.isLandscapeLayout() ? false : true,
        titleLeftMargin: ResponsiveUtil.isLandscapeLayout() ? 15 : 5,
        actions: [
          if (!_loading)
            CircleIconButton(
              icon: Icon(
                _allSelected ? LucideIcons.listX : LucideIcons.listChecks,
                color: ChewieTheme.iconColor,
              ),
              onTap: _toggleSelectAll,
            ),
          const SizedBox(width: 5),
        ],
        landscapeActions: [
          if (!_loading)
            ToolButton(
              context: context,
              icon: _allSelected ? LucideIcons.listX : LucideIcons.listChecks,
              buttonSize: const Size(32, 32),
              onPressed: _toggleSelectAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ChewieTheme.primaryColor.withAlpha(16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ChewieTheme.primaryColor.withAlpha(55),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.shieldCheck,
                              size: 19,
                              color: ChewieTheme.primaryColor,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                appLocalizations.importPreviewSafetyTip,
                                style: ChewieTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      InlineSelectionItem<SelectionItemModel<bool>>(
                        title: appLocalizations.importMergeStrategy,
                        selections: [
                          _keepLocalOption,
                          _overwriteLocalOption,
                        ],
                        hint: appLocalizations.importMergeStrategy,
                        selected: _currentMergeOption,
                        onChanged: (item) {
                          if (item != null) {
                            _setOverwrite(item.value);
                          }
                        },
                      ),
                      CaptionItem(
                        title:
                            "${appLocalizations.tokenCount} (${_tokenItems.length})",
                        children: _tokenItems
                            .map((item) => _buildTokenItem(item))
                            .toList(),
                      ),
                      if (_hasCategories)
                        CaptionItem(
                          title:
                              "${appLocalizations.categoryCount} (${_categoryItems.length})",
                          children: _categoryItems
                              .map((item) => _buildCategoryItem(item))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildTokenItem(ImportTokenItem item) {
    final isError = item.status == ImportTokenStatus.error;
    return InkWell(
      onTap: isError
          ? null
          : () {
              setState(() {
                item.selected = !item.selected;
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: item.selected,
              onChanged: isError
                  ? null
                  : (value) {
                      setState(() {
                        item.selected = value ?? false;
                      });
                    },
              activeColor: ChewieTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            CloudOTPItemBuilder.buildTokenImage(item.token, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.token.issuer.isNotEmpty
                        ? item.token.issuer
                        : item.token.account,
                    style: ChewieTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.token.account.isNotEmpty &&
                      item.token.account != item.token.issuer)
                    Text(
                      item.token.account,
                      style: ChewieTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isError && item.errorReason != null)
                    Text(
                      item.errorReason!,
                      style: ChewieTheme.bodySmall.copyWith(color: Colors.red),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTokenStatusText(item),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenStatusText(ImportTokenItem item) {
    String label;
    Color? color;
    switch (item.status) {
      case ImportTokenStatus.ready:
        label = appLocalizations.importReady;
      case ImportTokenStatus.duplicate:
        label = _overwriteExisting
            ? appLocalizations.importOverwrite
            : appLocalizations.importDuplicate;
      case ImportTokenStatus.error:
        label = appLocalizations.importError;
        color = Colors.red;
    }
    return Text(
      label,
      style: ChewieTheme.bodySmall.copyWith(
        color: color ?? ChewieTheme.bodySmall.color,
      ),
    );
  }

  Widget _buildCategoryItem(ImportCategoryItem item) {
    final bindingText = _buildCategoryBindingText(item);
    return InkWell(
      onTap: () {
        setState(() {
          item.selected = !item.selected;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: item.selected,
              onChanged: (value) {
                setState(() {
                  item.selected = value ?? false;
                });
              },
              activeColor: ChewieTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.title,
                    style: ChewieTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bindingText.isNotEmpty)
                    Text(
                      bindingText,
                      style: ChewieTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.isNew
                  ? appLocalizations.importCategoryNew
                  : (_overwriteExisting
                      ? appLocalizations.importOverwrite
                      : appLocalizations.importCategoryExisting),
              style: ChewieTheme.bodySmall,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: ChewieTheme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _totalSelectedCount > 0 ? _confirmImport : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ChewieTheme.primaryColor,
            disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _buttonText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
