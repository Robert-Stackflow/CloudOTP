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

import 'package:cloudotp/Database/token_category_binding_dao.dart';
import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Models/token_category.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Widgets/BottomSheet/select_category_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../Database/category_dao.dart';
import '../../TokenUtils/check_token_util.dart';
import '../../TokenUtils/token_image_util.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import '../../Widgets/BottomSheet/select_icon_bottom_sheet.dart';
import '../../Widgets/cloudotp/cloudotp_item_builder.dart';
import '../../generated/l10n.dart';

class AddTokenScreen extends StatefulWidget {
  const AddTokenScreen({
    super.key,
    this.token,
  });

  final OtpToken? token;

  static const String routeName = "/token/add";

  @override
  State<AddTokenScreen> createState() => _AddTokenScreenState();
}

class _AddTokenScreenState extends State<AddTokenScreen>
    with TickerProviderStateMixin {
  final TextEditingController _issuerController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _counterController = TextEditingController();
  final GroupButtonController _typeController = GroupButtonController();
  final GroupButtonController _digitsController = GroupButtonController();
  final GroupButtonController _algorithmController = GroupButtonController();
  late OtpToken _otpToken;
  bool _isEditing = false;
  bool _showAdvancedInfo = false;
  bool customedImage = false;

  bool get isSteam =>
      // ignore: unnecessary_null_comparison
      _otpToken != null && _otpToken.tokenType == OtpTokenType.Steam;

  bool get isHotp =>
      // ignore: unnecessary_null_comparison
      _otpToken != null && _otpToken.tokenType == OtpTokenType.HOTP;

  bool get isMotp =>
      // ignore: unnecessary_null_comparison
      _otpToken != null && _otpToken.tokenType == OtpTokenType.MOTP;

  bool get isYandex =>
      // ignore: unnecessary_null_comparison
      _otpToken != null && _otpToken.tokenType == OtpTokenType.Yandex;

  List<TokenCategory> categories = [];
  List<String> selectedCategoryUids = [];
  List<String> oldSelectedCategoryUids = [];

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _otpToken = widget.token!.clone();
      setState(() {
        _isEditing = true;
      });
    } else {
      _otpToken = OtpToken.init();
    }
    _issuerController.text = _otpToken.issuer;
    _accountController.text = _otpToken.account;
    _secretController.text = _otpToken.secret;
    _pinController.text = _otpToken.pin;
    _periodController.text = _otpToken.period.toString();
    _counterController.text = _otpToken.counter.toString();
    _typeController.selectIndex(_otpToken.tokenType.index);
    _digitsController.selectIndex(_otpToken.digits.index);
    _algorithmController.selectIndex(_otpToken.algorithm.index);
    _issuerController.addListener(() {
      _otpToken.issuer = _issuerController.text;
      if (!_isEditing && !customedImage) {
        setState(() {
          _otpToken.imagePath = TokenImageUtil.matchBrandLogo(_otpToken) ?? "";
        });
      }
    });
    _accountController.addListener(() {
      _otpToken.account = _accountController.text;
    });
    _secretController.addListener(() {
      _otpToken.secret = _secretController.text;
    });
    _pinController.addListener(() {
      _otpToken.pin = _pinController.text;
    });
    _periodController.addListener(() {
      _otpToken.periodString = _periodController.text;
    });
    _counterController.addListener(() {
      _otpToken.counterString = _counterController.text;
    });
    getCategories();
  }

  getCategories() async {
    categories = await CategoryDao.listCategories();
    if (!_isEditing) {
      selectedCategoryUids = [];
      oldSelectedCategoryUids = [];
    } else {
      selectedCategoryUids =
          await BindingDao.getCategoryUids(widget.token!.uid);
      oldSelectedCategoryUids = List.from(selectedCategoryUids);
    }
    setState(() {});
  }

  Future<bool> isValid() async {
    return formKey.currentState?.validate() ?? false;
    // bool issuerValid = await _issuerStateController.isValid();
    // bool secretValid = await _secretStateController.isValid();
    // bool pinValid = await _pinStateController.isValid();
    // bool periodValid = await _periodStateController.isValid();
    // bool counterValid = await _counterStateController.isValid();
    // switch (_otpToken.tokenType) {
    //   case OtpTokenType.TOTP:
    //     return issuerValid && secretValid && periodValid;
    //   case OtpTokenType.HOTP:
    //     return issuerValid && secretValid && counterValid;
    //   case OtpTokenType.MOTP:
    //     return issuerValid && secretValid && pinValid;
    //   case OtpTokenType.Yandex:
    //     return issuerValid && secretValid && pinValid;
    //   case OtpTokenType.Steam:
    //     return issuerValid && secretValid;
    //   default:
    //     return false;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ResponsiveAppBar(
        title: _isEditing ? S.current.editToken : S.current.addToken,
        showBack: !ResponsiveUtil.isLandscape(),
        titleLeftMargin: ResponsiveUtil.isLandscape() ? 15 : 5,
        actions: [
          CircleIconButton(
            icon: Icon(
              Icons.done_rounded,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {
              processDone();
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: EasyRefresh(
        child: _buildBody(),
      ),
    );
  }

  processDone() async {
    if (await isValid()) {
      bool success = false;
      List<String> unselectedCategoryUids = oldSelectedCategoryUids
          .where((element) => !selectedCategoryUids.contains(element))
          .toList();
      List<String> newSelectedCategoryUids = selectedCategoryUids
          .where((element) => !oldSelectedCategoryUids.contains(element))
          .toList();
      bool counterChanged = widget.token?.counter != _otpToken.counter;
      try {
        if (_isEditing) {
          widget.token?.copyFrom(_otpToken);
          await TokenDao.updateToken(_otpToken);
        } else {
          await TokenDao.insertToken(_otpToken);
        }
        await BindingDao.bingdingsForToken(
            _otpToken.uid, newSelectedCategoryUids);
        await BindingDao.unBingdingsForToken(
            _otpToken.uid, unselectedCategoryUids);
        success = true;
      } catch (e, t) {
        ILogger.error("Failed to save token", e, t);
        IToast.showTop(S.current.saveFailed);
      } finally {
        if (!_isEditing) {
          homeScreenState?.insertToken(_otpToken, forceAll: true);
        } else {
          homeScreenState?.updateToken(_otpToken,
              counterChanged: counterChanged);
        }
        homeScreenState?.changeCategoriesForToken(
          _otpToken,
          unselectedCategoryUids,
          newSelectedCategoryUids,
        );
        if (success) {
          if (ResponsiveUtil.isLandscape()) {
            chewieProvider.dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        }
      }
    }
  }

  _buildBody() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _iconInfo(),
              const SizedBox(height: 40),
              _typeInfo(),
              const SizedBox(height: 10),
              _basicInfo(),
              const SizedBox(height: 10),
              ..._categoryInfo(),
              const SizedBox(height: 10),
              if (_isEditing) ..._copyTimesInfo(),
              if (_isEditing && !isSteam && !isYandex)
                const SizedBox(height: 10),
              if (!_showAdvancedInfo && !isSteam && !isYandex)
                _showAdvancedInfoButton(),
              if (_showAdvancedInfo && !isSteam && !isYandex) _advancedInfo(),
              if (_isEditing) ..._deleteButton(),
              SizedBox(height: _isEditing ? 0 : 30),
            ],
          ),
        ),
      ],
    );
  }

  _iconInfo() {
    return _otpToken.imagePath.nullOrEmpty && _otpToken.issuer.nullOrEmpty
        ? Container(
            constraints: const BoxConstraints(maxWidth: 81),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.grey.withOpacity(0.1), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logo.png',
                height: 79,
                width: 79,
                fit: BoxFit.contain,
              ),
            ),
          )
        : CloudOTPItemBuilder.buildTokenImage(_otpToken);
  }

  _typeInfo() {
    return ContainerItem(
      child: ItemBuilder.buildGroupTile(
        context: context,
        // title: S.current.tokenType,
        controller: _typeController,
        buttons: OtpTokenType.toLabels(),
        onSelected: (value, index, isSelected) {
          _otpToken.tokenType = index.otpTokenType;
          _otpToken.digits = index.otpTokenType.defaultDigits;
          _digitsController.selectIndex(_otpToken.digits.index);
          _periodController.text = _otpToken.periodString =
              _otpToken.tokenType.defaultPeriod.toString();
          if (_otpToken.tokenType == OtpTokenType.Yandex) {
            _otpToken.digits = OtpDigits.D8;
            _otpToken.algorithm = OtpAlgorithm.SHA256;
          }
          setState(() {});
        },
      ),
    );
  }

  _basicInfo() {
    return ContainerItem(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: Column(
        children: [
          InputItem(
            controller: _issuerController,
            textInputAction: TextInputAction.next,
            title: S.current.tokenIssuer,
            validator: (text) {
              if (text.isEmpty) {
                return S.current.issuerCannotBeEmpty;
              }
              return null;
            },
            hint: S.current.tokenIssuerHint,
            style: InputItemStyle(
              maxLength: 32,
            ),
          ),
          InputItem(
            controller: _accountController,
            textInputAction: TextInputAction.next,
            title: S.current.tokenAccount,
            hint: S.current.tokenAccountHint,
          ),
          InputItem(
            controller: _secretController,
            textInputAction: TextInputAction.next,
            title: S.current.tokenSecret,
            style: InputItemStyle(
              obscure: _isEditing,
            ),
            tailingConfig: InputItemLeadingTailingConfig(
              type: InputItemLeadingTailingType.password,
            ),
            hint: S.current.tokenSecretHint,
            inputFormatters: [
              RegexInputFormatter.onlyNumberAndLetterAndSymbol,
            ],
            validator: (text) {
              if (text.isEmpty) {
                return S.current.secretCannotBeEmpty;
              }
              if (!CheckTokenUtil.isSecretBase32(text)) {
                return S.current.secretNotBase32;
              }
              return null;
            },
          ),
          Visibility(
            visible: isMotp || isYandex,
            child: InputItem(
              controller: _pinController,
              textInputAction: TextInputAction.next,
              title: S.current.tokenPin,
              style: InputItemStyle(
                obscure: _isEditing,
                maxLength: _otpToken.tokenType.maxPinLength,
              ),
              tailingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.password,
              ),
              hint: S.current.tokenPinHint,
              validator: (text) {
                if (text.isEmpty) {
                  return S.current.pinCannotBeEmpty;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  _categoryInfo() {
    return [
      EntryItem(
        tipWidth: 120,
        title: S.current.autoMatchTokenIcon,
        onTap: () {
          setState(() {
            customedImage = false;
            _otpToken.imagePath =
                TokenImageUtil.matchBrandLogo(_otpToken) ?? "";
          });
        },
      ),
      EntryItem(
        tipWidth: 300,
        title: S.current.editTokenIcon,
        tip: _otpToken.imagePath.notNullOrEmpty ? _otpToken.imagePath : "",
        onTap: () {
          BottomSheetBuilder.showBottomSheet(
            context,
            responsive: true,
            (context) => SelectIconBottomSheet(
              token: _otpToken,
              onSelected: (path) {
                customedImage = true;
                _otpToken.imagePath = path;
                setState(() {});
              },
            ),
          );
        },
      ),
      EntryItem(
        tipWidth: 300,
        title: S.current.editTokenCategory,
        tipWidget: selectedCategoryUids.isNotEmpty
            ? Wrap(
                spacing: 5,
                runSpacing: 5,
                children: selectedCategoryUids
                    .map(
                      (e) => RoundIconTextButton(
                        radius: 6,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        background: Theme.of(context).primaryColor,
                        text: categories
                            .firstWhere((element) => element.uid == e)
                            .title,
                      ),
                    )
                    .toList(),
              )
            : null,
        onTap: () {
          BottomSheetBuilder.showBottomSheet(
            context,
            responsive: true,
            (context) => SelectCategoryBottomSheet(
              token: _otpToken,
              isEditingToken: true,
              initialCategorUids: selectedCategoryUids,
              onCategoryChanged: (selected) {
                selectedCategoryUids = selected;
                setState(() {});
              },
            ),
          );
        },
      ),
    ];
  }

  _showAdvancedInfoButton() {
    return Row(
      children: [
        Expanded(
          child: RoundIconTextButton(
            background: Theme.of(context).canvasColor,
            radius: 12,
            text: S.current.showAdvancedInfo,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textStyle: Theme.of(context).textTheme.titleMedium,
            fontSizeDelta: 2,
            onPressed: () {
              setState(() {
                _showAdvancedInfo = true;
              });
            },
          ),
        ),
      ],
    );
  }

  _advancedInfo() {
    return ContainerItem(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: Column(
        children: [
          Visibility(
            visible: !isSteam && !isYandex,
            child: ItemBuilder.buildGroupTile(
              context: context,
              title: S.current.tokenDigits,
              controller: _digitsController,
              buttons: OtpDigits.toStrings(),
              onSelected: (value, index, isSelected) {
                _otpToken.digits = OtpDigits.fromString(value);
                setState(() {});
              },
            ),
          ),
          Visibility(
            visible: !isSteam && !isMotp && !isYandex,
            child: ItemBuilder.buildGroupTile(
              context: context,
              title: S.current.tokenAlgorithm,
              controller: _algorithmController,
              buttons: OtpAlgorithm.toStrings(),
              onSelected: (value, index, isSelected) {
                _otpToken.algorithm = index.otpAlgorithm;
                setState(() {});
              },
            ),
          ),
          Visibility(
            visible: !isSteam && !isYandex && !isHotp,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              child: InputItem(
                controller: _periodController,
                title: S.current.tokenPeriod,
                keyboardType: TextInputType.number,
                inputFormatters: [RegexInputFormatter.onlyNumber],
                textInputAction: _otpToken.tokenType == OtpTokenType.TOTP
                    ? TextInputAction.done
                    : TextInputAction.next,
                hint: S.current.tokenPeriodHint,
                validator: (text) {
                  if (text.isEmpty) {
                    return S.current.periodCannotBeEmpty;
                  }
                  if (int.tryParse(text) == null) {
                    return S.current.periodTooLong;
                  }
                  return null;
                },
              ),
            ),
          ),
          Visibility(
            visible: !isSteam && !isYandex && isHotp,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              child: InputItem(
                controller: _counterController,
                title: S.current.tokenCounter,
                inputFormatters: [RegexInputFormatter.onlyNumber],
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                hint: S.current.tokenCounterHint,
                validator: (text) {
                  if (text.isEmpty) {
                    return S.current.counterCannotBeEmpty;
                  }
                  if (int.tryParse(text) == null) {
                    return S.current.counterTooLong;
                  }
                  return null;
                },
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            width: double.infinity,
            child: RoundIconTextButton(
              background: Theme.of(context).canvasColor,
              radius: 12,
              text: S.current.hideAdvancedInfo,
              icon: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textStyle: Theme.of(context).textTheme.titleMedium,
              fontSizeDelta: 2,
              onPressed: () {
                setState(() {
                  _showAdvancedInfo = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  _copyTimesInfo() {
    return [
      EntryItem(
        tipWidth: 300,
        title: S.current.resetCopyTimes,
        tip: S.current.currentCopyTimes(_otpToken.copyTimes),
        onTap: () {
          DialogBuilder.showConfirmDialog(
            context,
            title: S.current.resetCopyTimesTitle,
            message: S.current.resetCopyTimesMessage(_otpToken.title),
            onTapConfirm: () async {
              await TokenDao.resetSingleTokenCopyTimes(_otpToken);
              homeScreenState?.resetCopyTimesSingle(_otpToken);
              IToast.showTop(S.current.resetSuccess);
              setState(() {});
            },
            onTapCancel: () {},
          );
        },
      ),
      EntryItem(
        tipWidth: 300,
        title: S.current.lastCopyTime,
        tip: _otpToken.lastCopyTimeStamp == 0
            ? S.current.neverCopied
            : TimeUtil.timestampToDateString(_otpToken.lastCopyTimeStamp),
        onTap: () {},
      ),
    ];
  }

  _deleteButton() {
    return [
      if ((!isSteam && !isYandex) || _isEditing) const SizedBox(height: 30),
      Row(
        children: [
          const SizedBox(width: 30),
          Expanded(
            child: RoundIconTextButton(
              background: Colors.red,
              text: S.current.deleteToken,
              fontSizeDelta: 2,
              onPressed: () {
                DialogBuilder.showConfirmDialog(
                  context,
                  title: S.current.deleteTokenTitle(_otpToken.title),
                  message: S.current.deleteTokenMessage(_otpToken.title),
                  onTapConfirm: () async {
                    await TokenDao.deleteToken(_otpToken);
                    chewieProvider.dialogNavigatorState?.popPage();
                    IToast.showTop(
                        S.current.deleteTokenSuccess(_otpToken.title));
                    homeScreenState?.removeToken(_otpToken);
                  },
                  onTapCancel: () {},
                );
              },
            ),
          ),
          const SizedBox(width: 30),
        ],
      ),
      const SizedBox(height: 20),
    ];
  }
}
