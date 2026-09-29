import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows again when the scroll position returns to the top',
      (tester) async {
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 30,
                  itemBuilder: (context, index) => const SizedBox(height: 60),
                ),
              ),
              ScrollToHide(
                scrollController: scrollController,
                height: 60,
                hideDirection: Axis.vertical,
                child: const SizedBox(height: 60),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollToHideState>(find.byType(ScrollToHide)).isShown,
      isFalse,
    );

    scrollController.jumpTo(scrollController.position.minScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollToHideState>(find.byType(ScrollToHide)).isShown,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    scrollController.dispose();
  });
}
