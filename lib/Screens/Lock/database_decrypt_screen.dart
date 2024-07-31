import 'package:cloudotp/Resources/theme.dart';
import 'package:cloudotp/Utils/route_util.dart';
import 'package:cloudotp/Widgets/Item/item_builder.dart';
import 'package:cloudotp/Widgets/Scaffold/my_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Database/database_manager.dart';
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

class DatabaseDecryptScreenState extends State<DatabaseDecryptScreen> {
  final TextEditingController _controller = TextEditingController();
  late InputStateController _stateController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _stateController = InputStateController(
      controller: _controller,
      validate: (value) {
        if (value.isEmpty) {
          return Future.value(S.current.encryptDatabasePasswordCannotBeEmpty);
        }
        return Future.value(null);
      },
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
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
          child: InputItem(
            controller: _controller,
            stateController: _stateController,
            focusNode: _focusNode,
            maxLines: 1,
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
        const SizedBox(height: 30),
        ItemBuilder.buildRoundButton(
          context,
          text: S.current.confirm,
          background: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
          onTap: () async {
            try {
              await DatabaseManager.initDataBase(_controller.text);
            } catch (e) {
              _stateController.setError(S.current.encryptDatabasePasswordWrong);
            }
            if (DatabaseManager.initialized) {
              Navigator.of(context).pushReplacement(RouteUtil.getFadeRoute(
                  ItemBuilder.buildContextMenuOverlay(const MainScreen())));
            }
          },
        ),
      ],
    );
  }
}
