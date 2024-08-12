/// A Flutter library that provides animating, reordering, and swiping capabilities
/// for both [ListView] and [GridView]. This library enhances the user experience
/// by allowing seamless and visually appealing interactions with list or grid items.
///
/// Features:
///
/// - Animates item insertions, removals, and reordering with customizable animations.
/// - Allows users to interactively reorder items with drag-and-drop gestures.
/// - Swipe-to-remove functionality for removing items with animated effects.
/// - Configurable decorators for the dragged and swiped items.
/// - Callbacks for tracking item drag and swipe events.
///
/// Usage:
///
/// To use this library, import it into your Flutter project and wrap
/// your [ListView] or [GridView] with the [AnimatedReorderable] widget.
///
/// Example:
///
/// ```dart
/// import 'package:animated_reorderable/animated_reorderable.dart';
/// import 'package:flutter/material.dart';
///
/// void main() {
///   runApp(const Example());
/// }
///
/// class Example extends MaterialApp {
///   const Example({super.key})
///       : super(
///           home: const Scaffold(
///             body: ListViewExample(),
///           ),
///         );
/// }
///
/// class ListViewExample extends StatefulWidget {
///   const ListViewExample({super.key});
///
///   @override
///   State<ListViewExample> createState() => _ListViewExampleState();
/// }
///
/// class _ListViewExampleState extends State<ListViewExample> {
///   final items = [1, 2, 3, 4, 5];
///
///   @override
///   Widget build(BuildContext context) {
///     return AnimatedReorderable.list(
///       keyGetter: (index) => ValueKey(items[index]),
///       onReorder: (permutations) => permutations.apply(items),
///       listView: ListView.builder(
///         itemCount: items.length,
///         itemBuilder: (context, index) => Card(
///           child: Padding(
///             padding: const EdgeInsets.all(16),
///             child: Text('Item: ${items[index]}'),
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
library animated_reorderable;

export 'src/animated_reorderable.dart';
export 'src/model/permutations.dart';
export 'src/WaterfallFlow/waterfall_flow.dart';
export 'src/WaterfallFlow/reorderable_grid_view.dart';
export 'src/WaterfallFlow/reorderable_grid.dart';
