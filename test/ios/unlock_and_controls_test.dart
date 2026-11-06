import 'dart:async';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:awesome_chewie/src/Utils/System/screen_protection_coordinator.dart';
import 'package:cloudotp/Platform/ios/ios_home_controls.dart';
import 'package:cloudotp/Platform/ios/ios_home_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rebuilding pages does not reattach native screenshot protection',
      () async {
    final coordinator = ScreenProtectionCoordinator();
    final completer = Completer<void>();
    var calls = 0;
    Future<void> apply(bool _) async {
      calls++;
      await completer.future;
    }

    final operations = List.generate(10, (_) => coordinator.set(true, apply));
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    completer.complete();
    await Future.wait(operations);
    expect(calls, 1);
    expect(coordinator.applied, isTrue);
  });
  test(
      'real enable/disable changes stay ordered and a failed transition can retry',
      () async {
    final coordinator = ScreenProtectionCoordinator();
    var fail = true;
    final applied = <bool>[];
    Future<void> apply(bool value) async {
      if (fail) {
        fail = false;
        throw StateError('native call failed');
      }
      applied.add(value);
    }

    await expectLater(coordinator.set(true, apply), throwsStateError);
    expect(coordinator.applied, isNull);
    await Future.wait([
      coordinator.set(true, apply),
      coordinator.set(false, apply),
      coordinator.set(true, apply)
    ]);
    expect(applied, [true, false, true]);
  });
  testWidgets('iOS auth root switch paints an opaque frame without a fade',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    const background = Color(0xff123456);
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(scaffoldBackgroundColor: background),
        home: const Scaffold()));
    final route = RouteUtil.createIOSRootRoute<void>(const SizedBox.expand());
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    expect(route.opaque, isTrue);
    navigator.currentState!.pushAndRemoveUntil(route, (_) => false);
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (widget) => widget is ColoredBox && widget.color == background),
        findsOneWidget);
  });
  testWidgets(
      'scanner retains top clearance and moves with category tabs while hiding',
      (tester) async {
    final scroll = ScrollController();
    final controller = ScrollToHideController();
    const spacing = IOSHomeSpacing(
        MediaQueryData(viewPadding: EdgeInsets.only(bottom: 34)));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Align(
      alignment: Alignment.bottomCenter,
      child: ScrollToHide(
          scrollController: scroll,
          controller: controller,
          height: spacing.barHeight,
          hideDirection: Axis.vertical,
          child: IOSHomeControls(
            key: const ValueKey('bar'),
            spacing: spacing,
            scanner:
                const SizedBox(key: ValueKey('scanner'), width: 56, height: 56),
            categoryBar: Padding(
                padding: spacing.barPadding,
                child: const SizedBox(key: ValueKey('tabs'), height: 48)),
          )),
    ))));
    await tester.pumpAndSettle();
    double top(String key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy;
    expect(top('scanner') - top('bar'), 8);
    final difference = top('scanner') - top('tabs');
    expect(difference, -4);
    controller.hide();
    await tester.pump(const Duration(milliseconds: 150));
    expect(top('scanner') - top('tabs'), difference);
    controller.show();
    await tester.pump(const Duration(milliseconds: 100));
    expect(top('scanner') - top('tabs'), difference);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
  });
}
