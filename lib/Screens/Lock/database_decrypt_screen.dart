import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Widgets/Dialog/custom_dialog.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../Database/database_manager.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/Item/input_item.dart';
import '../../Widgets/Window/window_caption.dart';
import '../../generated/l10n.dart';
import '../main_screen.dart';

class DatabaseDecryptScreen extends StatefulWidget {
  const DatabaseDecryptScreen({super.key});

  @override
  DatabaseDecryptScreenState createState() => DatabaseDecryptScreenState();
}

class DatabaseDecryptScreenState extends State<DatabaseDecryptScreen>
    with WindowListener {
  final FocusNode _focusNode = FocusNode();
  late InputValidateAsyncController validateAsyncController;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void dispose() {
    super.dispose();
    windowManager.removeListener(this);
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
    validateAsyncController = InputValidateAsyncController(
      listen: false,
      validator: (text) async {
        if (text.isNotEmpty) {
          try {
            await DatabaseManager.initDataBase(text);
            if (DatabaseManager.initialized) {
              return null;
            }
          } catch (e) {
            return S.current.encryptDatabasePasswordWrong;
          }
        }
        return null;
      },
      controller: TextEditingController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      backgroundColor: MyTheme.getBackground(context),
      body: SafeArea(
        right: false,
        child: Stack(
          children: [
            if (ResponsiveUtil.isDesktop()) const WindowMoveHandle(),
            Center(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  onSubmit() async {
    CustomLoadingDialog.showLoading(
        title: S.current.decryptingDatabasePassword);
    String? error = await validateAsyncController.validate();
    bool isValidAsync = (error == null);
    CustomLoadingDialog.dismissLoading();
    if (isValidAsync) {
      if (DatabaseManager.initialized) {
        Navigator.of(context).pushReplacement(RouteUtil.getFadeRoute(
            ItemBuilder.buildContextMenuOverlay(const MainScreen())));
      }
    }
  }

  _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(S.current.decryptDatabasePassword,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 30),
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Form(
            key: formKey,
            child: InputItem(
              validator: (value) {
                if (value.isEmpty) {
                  return S.current.encryptDatabasePasswordCannotBeEmpty;
                }
                return null;
              },
              validateAsyncController: validateAsyncController,
              focusNode: _focusNode,
              maxLines: 1,
              onSubmit: (_) => onSubmit(),
              textInputAction: TextInputAction.done,
              backgroundColor: Colors.transparent,
              tailingType: InputItemTailingType.password,
              leadingType: InputItemLeadingType.none,
              hint: S.current.inputEncryptDatabasePassword,
              topRadius: true,
              bottomRadius: true,
              inputFormatters: [
                RegexInputFormatter.onlyNumberAndLetter,
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ItemBuilder.buildRoundButton(
          context,
          text: S.current.confirm,
          fontSizeDelta: 2,
          background: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
          onTap: onSubmit,
        ),
      ],
    );
  }
}
