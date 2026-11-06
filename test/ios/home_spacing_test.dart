import 'package:cloudotp/Platform/ios/ios_home_spacing.dart';
import 'package:cloudotp/Widgets/Home/pull_search_scroll_physics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'bottom bar ignores Scaffold-injected padding and consumes safe area once',
      () {
    final spacing = IOSHomeSpacing(const MediaQueryData(
      padding: EdgeInsets.only(bottom: 110),
      viewPadding: EdgeInsets.only(bottom: 34),
    ));
    expect(spacing.safeBottom, 34);
    expect(spacing.barHeight, 102);
    expect(spacing.barHeight - spacing.barPadding.vertical, 48);
    expect(spacing.barPadding.bottom, 42);
  });
  test('keyboard and an already-consumed safe area do not leave a bottom gap',
      () {
    expect(
        const IOSHomeSpacing(MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: 34),
          viewInsets: EdgeInsets.only(bottom: 300),
        )).barHeight,
        68);
    expect(const IOSHomeSpacing(MediaQueryData()).barHeight, 68);
  });
  test(
      'iOS pull physics clamp bounce without blocking valid coordinated scroll',
      () {
    final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 500,
        pixels: 0,
        viewportDimension: 600,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 3);
    final physics = PullSearchScrollPhysics(
            isPulling: () => true, clampPullOverscroll: true)
        .applyTo(const BouncingScrollPhysics());
    expect(physics.applyBoundaryConditions(metrics, -100), -100);
    expect(physics.applyBoundaryConditions(metrics, 20), 0);
    expect(physics.applyBoundaryConditions(metrics, 550), 50);
    final legacy = PullSearchScrollPhysics(isPulling: () => true);
    expect(legacy.applyBoundaryConditions(metrics, 20), 20);
  });
  testWidgets(
      'iOS nested pull has no second native translation or ballistic assertion',
      (tester) async {
    final outer = ScrollController();
    var pulling = false;
    var overscroll = 0.0;
    ScrollPhysics physics() => PullSearchScrollPhysics(
        isPulling: () => pulling,
        clampPullOverscroll: true,
        parent: const ClampingScrollPhysics());
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: NotificationListener<OverscrollNotification>(
          onNotification: (event) {
            if (event.overscroll < 0) {
              pulling = true;
              overscroll += event.overscroll;
            }
            return false;
          },
          child: NestedScrollView(
            controller: outer,
            physics: physics(),
            floatHeaderSlivers: true,
            headerSliverBuilder: (_, __) => [
              const SliverAppBar(
                  pinned: true, floating: true, title: Text('Search'))
            ],
            body: ListView.builder(
                physics: physics(),
                padding: EdgeInsets.zero,
                itemCount: 20,
                itemBuilder: (_, index) => SizedBox(
                    key: ValueKey('token-$index'),
                    height: 100,
                    child: Text('Token $index'))),
          )),
    )));
    await tester.pumpAndSettle();
    final initial = tester.getTopLeft(find.byKey(const ValueKey('token-0')));
    await tester.dragFrom(const Offset(200, 150), const Offset(0, 220));
    await tester.pumpAndSettle();
    expect(overscroll, lessThan(0));
    expect(outer.offset, 0);
    expect(tester.getTopLeft(find.byKey(const ValueKey('token-0'))), initial);
    expect(tester.takeException(), isNull);
    pulling = false;
    await tester.fling(find.byType(ListView), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, 900), 1400);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    outer.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
