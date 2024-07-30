import 'package:cloudotp/Database/token_dao.dart';
import 'package:cloudotp/Models/opt_token.dart';
import 'package:cloudotp/Utils/app_provider.dart';
import 'package:cloudotp/Utils/itoast.dart';
import 'package:cloudotp/Utils/responsive_util.dart';
import 'package:cloudotp/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:cloudotp/Widgets/General/EasyRefresh/easy_refresh.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';

import '../../TokenUtils/check_token_util.dart';
import '../../TokenUtils/token_image_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/select_icon_bottom_sheet.dart';
import '../../Widgets/Item/input_item.dart';
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
  late final InputStateController _issuerStateController;
  late final InputStateController _secretStateController;
  late final InputStateController _periodStateController;
  late final InputStateController _pinStateController;
  late final InputStateController _counterStateController;
  late OtpToken _otpToken;
  bool _isEditing = false;
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
    _issuerStateController = InputStateController(
      controller: _issuerController,
      validate: (text) {
        if (text.isEmpty) {
          return S.current.issuerCannotBeEmpty;
        }
        return null;
      },
    );
    _secretStateController = InputStateController(
      controller: _secretController,
      validate: (text) {
        if (text.isEmpty) {
          return S.current.secretCannotBeEmpty;
        }
        if (_otpToken.tokenType == OtpTokenType.Steam &&
            !CheckTokenUtil.isSecretBase32(text)) {
          return S.current.secretNotBase32;
        }
        return null;
      },
    );
    _pinStateController = InputStateController(
      controller: _pinController,
      validate: (text) {
        if (text.isEmpty) {
          return S.current.pinCannotBeEmpty;
        }
        return null;
      },
    );
    _periodStateController = InputStateController(
      controller: _periodController,
      validate: (text) {
        if (text.isEmpty) {
          return S.current.periodCannotBeEmpty;
        }
        if (int.tryParse(text) == null) {
          return S.current.periodTooLong;
        }
        return null;
      },
    );
    _counterStateController = InputStateController(
      controller: _counterController,
      validate: (text) {
        if (text.isEmpty) {
          return S.current.counterCannotBeEmpty;
        }
        if (int.tryParse(text) == null) {
          return S.current.counterTooLong;
        }
        return null;
      },
    );
  }

  bool isValid() {
    bool issuerValid = _issuerStateController.isValid();
    bool secretValid = _secretStateController.isValid();
    bool pinValid = _pinStateController.isValid();
    bool periodValid = _periodStateController.isValid();
    bool counterValid = _counterStateController.isValid();
    return issuerValid &&
        secretValid &&
        pinValid &&
        periodValid &&
        counterValid;
  }

  resetState() {
    _issuerStateController.reset();
    _secretStateController.reset();
    _pinStateController.reset();
    _periodStateController.reset();
    _counterStateController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: ItemBuilder.buildAppBar(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        forceShowClose: true,
        leading: Icons.close_rounded,
        onLeadingTap: () {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
          } else {
            Navigator.pop(context);
          }
        },
        title: Text(
          S.current.addToken,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.apply(fontWeightDelta: 2),
        ),
        center: true,
        actions: [
          ItemBuilder.buildIconButton(
            context: context,
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
      body: _buildBody(),
    );
  }

  processDone() async {
    if (isValid()) {
      bool success = false;
      try {
        if (_isEditing) {
          await TokenDao.updateToken(_otpToken);
        } else {
          await TokenDao.insertToken(_otpToken);
        }
        success = true;
      } catch (e) {
        IToast.showTop(S.current.saveFailed);
      } finally {
        homeScreenState?.refresh();
        if (success) {
          if (ResponsiveUtil.isLandscape()) {
            dialogNavigatorState?.popPage();
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
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      children: [
        Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Utils.isEmpty(_otpToken.imagePath) &&
                        Utils.isEmpty(_otpToken.issuer)
                    ? Container(
                        constraints: const BoxConstraints(maxWidth: 82),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.1), width: 0.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : ItemBuilder.buildTokenImage(_otpToken),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ItemBuilder.buildIconButton(
                      context: context,
                      icon: const Icon(Icons.auto_awesome_outlined, size: 20),
                      onTap: () async {
                        setState(() {
                          customedImage = false;
                          _otpToken.imagePath =
                              TokenImageUtil.matchBrandLogo(_otpToken) ?? "";
                        });
                      },
                    ),
                    const SizedBox(height: 5),
                    ItemBuilder.buildIconButton(
                      context: context,
                      icon: const Icon(Icons.image_search_rounded, size: 20),
                      onTap: () async {
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
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            ItemBuilder.buildContainerItem(
              context: context,
              topRadius: true,
              bottomRadius: true,
              child: Column(
                children: [
                  ItemBuilder.buildGroupTile(
                    context: context,
                    title: S.current.tokenType,
                    disabled: _isEditing,
                    controller: _typeController,
                    buttons: OtpTokenType.labels(),
                    onSelected: (value, index, isSelected) {
                      _otpToken.tokenType = index.otpTokenType;
                      if (_otpToken.tokenType == OtpTokenType.MOTP) {
                        _otpToken.periodString = "10";
                        _periodController.text = "10";
                      } else if (_otpToken.tokenType == OtpTokenType.Yandex) {
                        _otpToken.periodString = "30";
                        _periodController.text = "30";
                        _otpToken.digits = OtpDigits.D8;
                        _otpToken.algorithm = OtpAlgorithm.SHA256;
                      } else {
                        _otpToken.periodString = "30";
                        _periodController.text = "30";
                      }
                      resetState();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ItemBuilder.buildContainerItem(
              context: context,
              topRadius: true,
              bottomRadius: true,
              padding: const EdgeInsets.only(top: 15, bottom: 5),
              child: Column(
                children: [
                  InputItem(
                    controller: _issuerController,
                    textInputAction: TextInputAction.next,
                    leadingText: S.current.tokenIssuer,
                    leadingType: InputItemLeadingType.text,
                    topRadius: true,
                    stateController: _issuerStateController,
                    hint: S.current.tokenIssuerHint,
                    maxLength: 32,
                  ),
                  InputItem(
                    controller: _accountController,
                    textInputAction: TextInputAction.next,
                    leadingType: InputItemLeadingType.text,
                    leadingText: S.current.tokenAccount,
                    hint: S.current.tokenAccountHint,
                  ),
                  InputItem(
                    controller: _secretController,
                    textInputAction: TextInputAction.next,
                    leadingType: InputItemLeadingType.text,
                    leadingText: S.current.tokenSecret,
                    tailingType: InputItemTailingType.password,
                    hint: S.current.tokenSecretHint,
                    inputFormatters: [
                      RegexInputFormatter.onlyNumberAndLetter,
                    ],
                    stateController: _secretStateController,
                    bottomRadius: !isMotp,
                  ),
                  Visibility(
                    visible: isMotp || isYandex,
                    child: InputItem(
                      controller: _pinController,
                      textInputAction: TextInputAction.next,
                      leadingText: S.current.tokenPin,
                      leadingType: InputItemLeadingType.text,
                      tailingType: InputItemTailingType.password,
                      hint: S.current.tokenPinHint,
                      maxLength: 4,
                      bottomRadius: true,
                      stateController: _pinStateController,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ItemBuilder.buildContainerItem(
              context: context,
              topRadius: true,
              bottomRadius: true,
              padding: const EdgeInsets.only(top: 15, bottom: 5),
              child: Column(
                children: [
                  Visibility(
                    visible: !isSteam && !isYandex,
                    child: ItemBuilder.buildGroupTile(
                      context: context,
                      title: S.current.tokenDigits,
                      disabled: _isEditing,
                      controller: _digitsController,
                      buttons: OtpDigits.D5.strings,
                      onSelected: (value, index, isSelected) {
                        _otpToken.digits = OtpDigits.fromLabel(value);
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
                      buttons: OtpAlgorithm.SHA1.strings,
                      disabled: _isEditing,
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
                        leadingText: S.current.tokenPeriod,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RegexInputFormatter.onlyNumber],
                        leadingType: InputItemLeadingType.text,
                        textInputAction:
                            _otpToken.tokenType == OtpTokenType.TOTP
                                ? TextInputAction.done
                                : TextInputAction.next,
                        hint: S.current.tokenPeriodHint,
                        readOnly: _isEditing,
                        stateController: _periodStateController,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !isSteam && !isYandex && isHotp,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: InputItem(
                        controller: _counterController,
                        leadingText: S.current.tokenCounter,
                        inputFormatters: [RegexInputFormatter.onlyNumber],
                        leadingType: InputItemLeadingType.text,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        bottomRadius: true,
                        hint: S.current.tokenCounterHint,
                        readOnly: _isEditing,
                        stateController: _counterStateController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
