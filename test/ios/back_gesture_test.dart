import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<GlobalKey<NavigatorState>> showPage(
    WidgetTester tester, Widget page) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator, home: const Scaffold(body: Text('root'))));
  navigator.currentState!.push(RouteUtil.createIOSPageRoute<void>(page));
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  testWidgets(
      'content drags complete the real gesture password without navigating',
      (tester) async {
    List<int>? selected;
    final key = GlobalKey<GestureState>();
    final navigator = await showPage(
        tester,
        Scaffold(
            body: Center(
                child: GestureUnlockView(
          key: key,
          size: 300,
          padding: 30,
          roundSpace: 30,
          onCompleted: (points, _) => selected = List.of(points),
        ))));
    final origin = tester.getTopLeft(find.byType(GestureUnlockView));
    final points = key.currentState!.points;
    final first = origin + Offset(points[0].x, points[0].y);
    final gesture = await tester.startGesture(first - const Offset(35, 0));
    await gesture.moveTo(first - const Offset(5, 0));
    await gesture.moveTo(first + const Offset(2, 0));
    await gesture.moveTo(origin + Offset(points[1].x, points[1].y));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(origin + Offset(points[2].x, points[2].y));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, [0, 1, 2]);
    expect(navigator.currentState!.canPop(), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('token-style horizontal actions keep their drag gestures',
      (tester) async {
    var distance = 0.0;
    final navigator = await showPage(
        tester,
        Scaffold(
            body: Center(
                child: GestureDetector(
          key: const ValueKey('token'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => distance += details.delta.dx,
          child: const SizedBox(
              width: 400, height: 100, child: Text('token actions')),
        ))));
    await tester.drag(
        find.byKey(const ValueKey('token')), const Offset(180, 0));
    await tester.pumpAndSettle();
    expect(distance, greaterThan(100));
    expect(navigator.currentState!.canPop(), isTrue);
  });

  testWidgets('leading-edge swipe still returns to the previous page',
      (tester) async {
    final navigator =
        await showPage(tester, const Scaffold(body: Text('details')));
    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isFalse);
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('authentication PopScope cannot be bypassed by edge swipe',
      (tester) async {
    final navigator = await showPage(tester,
        const PopScope(canPop: false, child: Scaffold(body: Text('locked'))));
    await tester.dragFrom(const Offset(5, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isTrue);
    expect(find.text('locked'), findsOneWidget);
  });
}
