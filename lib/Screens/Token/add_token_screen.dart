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
  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _counterController = TextEditingController();
  final GroupButtonController _typeController = GroupButtonController();
  final GroupButtonController _digitsController = GroupButtonController();
  final GroupButtonController _algorithmController = GroupButtonController();
  late OtpToken _otpToken;
  bool _isEditing = false;
  bool customedImage = false;

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
    _intervalController.text = _otpToken.period.toString();
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
    _intervalController.addListener(() {
      _otpToken.periodString = _intervalController.text;
    });
    _counterController.addListener(() {
      _otpToken.counterString = _counterController.text;
    });
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
          "添加令牌",
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
    CheckTokenError? e = CheckTokenUtil.checkToken(_otpToken);
    if (e == null) {
      bool success = false;
      try {
        if (_isEditing) {
          await TokenDao.updateToken(_otpToken);
        } else {
          await TokenDao.insertToken(_otpToken);
        }
        success = true;
      } catch (e) {
        IToast.showTop("保存失败");
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
    } else {
      IToast.showTop(e.message);
    }
  }

  _buildBody() {
    return EasyRefresh(
      child: ListView(
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
                                color: Colors.grey.withOpacity(0.1),
                                width: 0.5),
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
                            preferMinWidth: 500,
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
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    ItemBuilder.buildInputItem(
                      context: context,
                      controller: _issuerController,
                      textInputAction: TextInputAction.next,
                      leadingText: "应用",
                      topRadius: true,
                      hint: "应用名称",
                    ),
                    ItemBuilder.buildInputItem(
                      context: context,
                      controller: _accountController,
                      textInputAction: TextInputAction.next,
                      leadingText: "帐户",
                      hint: "帐户名称或邮箱",
                    ),
                    ItemBuilder.buildInputItem(
                      context: context,
                      controller: _secretController,
                      textInputAction: TextInputAction.next,
                      leadingText: "密钥",
                      hint: "Base32编码的密钥",
                      bottomRadius: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildContainerItem(
                context: context,
                topRadius: true,
                bottomRadius: true,
                padding: const EdgeInsets.only(top: 5, bottom: 10),
                child: Column(
                  children: [
                    ItemBuilder.buildGroupTile(
                      context: context,
                      title: "类型",
                      disabled: _isEditing,
                      controller: _typeController,
                      buttons: OtpTokenType.labels(),
                      onSelected: (value, index, isSelected) {
                        _otpToken.tokenType = index.otpTokenType;
                        setState(() {});
                      },
                    ),
                    ItemBuilder.buildGroupTile(
                      context: context,
                      title: "位数",
                      disabled: _isEditing,
                      controller: _digitsController,
                      buttons: OtpDigits.D5.strings,
                      onSelected: (value, index, isSelected) {
                        _otpToken.digits = index.otpDigits;
                        setState(() {});
                      },
                    ),
                    ItemBuilder.buildGroupTile(
                      context: context,
                      title: "算法",
                      controller: _algorithmController,
                      buttons: OtpAlgorithm.SHA1.strings,
                      disabled: _isEditing,
                      onSelected: (value, index, isSelected) {
                        _otpToken.algorithm = index.otpAlgorithm;
                        setState(() {});
                      },
                    ),
                    ItemBuilder.buildInputItem(
                      context: context,
                      controller: _intervalController,
                      leadingText: "间隔",
                      keyboardType: TextInputType.number,
                      textInputAction: _otpToken.tokenType == OtpTokenType.TOTP
                          ? TextInputAction.done
                          : TextInputAction.next,
                      hint: "密码刷新时间间隔，默认为30秒",
                      readOnly: _isEditing,
                    ),
                    Visibility(
                      visible: _otpToken.tokenType == OtpTokenType.HOTP,
                      child: ItemBuilder.buildInputItem(
                        context: context,
                        controller: _counterController,
                        leadingText: "计数",
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        bottomRadius: true,
                        hint: "HOTP类型令牌的计数器",
                        readOnly: _isEditing,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
