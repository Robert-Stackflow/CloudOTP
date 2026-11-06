import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The navigation regression needs the real dialogs, but no persistent settings.
class TestChewieProvider implements ChewieProvider {
  @override
  GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();
  @override
  late BuildContext rootContext;
  @override
  void setRootContext(BuildContext context) {
    rootContext = context;
  }

  @override
  Widget Function(double, bool) loadingWidgetBuilder =
      (_, __) => const SizedBox();
  @override
  ChewieThemeColorData get lightTheme =>
      ChewieThemeColorData.defaultLightThemes.first;
  @override
  ChewieThemeColorData get darkTheme =>
      ChewieThemeColorData.defaultDarkThemes.first;
  @override
  ActiveThemeMode get themeMode => ActiveThemeMode.light;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GlobalKey<NavigatorState> navigator;
  late BuildContext root;
  late Widget Function(double, bool) loadingBuilder;

  Future<void> showRoot(WidgetTester tester) async {
    navigator = GlobalKey<NavigatorState>();
    chewieProvider = TestChewieProvider();
    chewieProvider.globalNavigatorKey = navigator;
    loadingBuilder = chewieProvider.loadingWidgetBuilder;
    chewieProvider.loadingWidgetBuilder =
        (_, __) => const SizedBox(width: 40, height: 40);
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        home: Builder(builder: (context) {
          root = context;
          chewieProvider.setRootContext(context);
          return const Scaffold(body: Text('cloud backups'));
        })));
    addTearDown(() {
      chewieProvider.loadingWidgetBuilder = loadingBuilder;
    });
  }

  testWidgets(
      'download import closes its loading dialog before showing the iOS preview',
      (tester) async {
    await showRoot(tester);
    final progress = showProgressDialog('importing', showProgress: false);
    await tester.pumpAndSettle();
    expect(find.text('importing'), findsOneWidget);
    final opened = RouteUtil.pushIOSPageRoute<String>(
        root, const Scaffold(body: Text('import preview')));
    progress.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('importing'), findsNothing);
    expect(find.text('import preview'), findsOneWidget);
    expect(tester.takeException(), isNull);
    navigator.currentState!.pop('closed');
    await tester.pumpAndSettle();
    expect(await opened, 'closed');
    expect(find.text('cloud backups'), findsOneWidget);
  });

  testWidgets(
      'password validation finishes both overlays without popping the iOS preview',
      (tester) async {
    await showRoot(tester);
    unawaited(navigator.currentState!.push(DialogRoute<void>(
        context: root,
        builder: (_) => const Dialog(child: Text('backup password')))));
    await tester.pumpAndSettle();
    final progress = showProgressDialog('decrypting', showProgress: false);
    await tester.pumpAndSettle();
    final opened = RouteUtil.pushIOSPageRoute<void>(
        root, const Scaffold(body: Text('import preview')));
    progress.dismiss();
    // The asynchronous password validator returns before the sheet closes.
    await Future<void>.value();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('decrypting'), findsNothing);
    expect(find.text('backup password'), findsNothing);
    expect(find.text('import preview'), findsOneWidget);
    expect(tester.takeException(), isNull);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await opened;
  });

  testWidgets(
      'a disposed origin cannot open a stale destination after an async import',
      (tester) async {
    await showRoot(tester);
    late BuildContext origin;
    unawaited(navigator.currentState!
        .push(MaterialPageRoute<void>(builder: (context) {
      origin = context;
      return const Scaffold(body: Text('origin'));
    })));
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(origin.mounted, isFalse);
    final opened =
        RouteUtil.pushIOSPageRoute<void>(origin, const Text('stale preview'));
    await tester.pump();
    await opened;
    expect(find.text('stale preview'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
