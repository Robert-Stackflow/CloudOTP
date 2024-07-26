# context_menus
A package to show context menus on right-click or long-press.

<img src="http://screens.gskinner.com/shawn/0tVhpe5OY2.gif" alt="" />

## 🔨 Installation
```yaml
dependencies:
  context_menus: ^1.0.2
```

### ⚙ Import

```dart
import 'package:context_menus/context_menus.dart';
```

## 🕹️ Usage

To get started, wrap a `ContextMenuOverlay` around your top-most view or app:

```dart
return ContextMenuOverlay(
  child: MaterialApp(...)
);
```

You can then use the `ContextMenuRegion` widget to tag sections of the Widget tree that should trigger a context menu.
```dart
/// Example hyperlink menu
return ContextMenuRegion(
  contextMenu: LinkContextMenu(url: 'http://flutter.dev'),
  child: TextButton(onPressed: () {}, child: Text("http://flutter.dev")),
),
```

Each `ContextMenuRegion` requires a `contextMenu` widget which will be shown on right-click or long-press.

Included in this package are a few pre-made ones which you can use as templates to quickly build your own.
* LinkContextMenu
* TextContextMenu
* GenericContextMenu

## ✨ ️Styling

You have three options to modify styling
* pass in custom `ContextMenuButtonStyle` for small styling tweaks
* use your own `cardBuilder` or `buttonBuilder` delegate for more control
* pass your own custom menus for total control

For basic styling, just pass button styling values to the `ContextMenuOverlay`:
```dart
return ContextMenuOverlay(
    buttonStyle: ContextMenuButtonStyle(
      fgColor: Colors.green,
      bgColor: Colors.red.shade100,
      hoverBgColor: Colors.red.shade200,
    ),
    child: MaterialApp(...);
}
```

For more control, you can overide the cardBuilder and buttonBuilder delegates:
```dart
return ContextMenuOverlay(
  /// Make a custom background
  cardBuilder: (_, children) => Container(color: Colors.purple.shade100, child: Column(children: children)),
  /// Make custom buttons
  buttonBuilder: (_, config, [__]) => TextButton(
    onPressed: config.onPressed,
    child: Container(width: double.infinity, child: Text(config.label)),
  ),
  child: MaterialApp( ... ),
);
```

Finally, you can disregard all of this and just provide your own menus directly to the `ContextMenuRegion`:
```dart
ContextMenuRegion(
  contextMenu: MyCustomMenu(),
  child: ...,
),
```
In this case, you are responsible for closing the menu when your buttons are triggered, which you can do using an extension on BuildContext:
```dart
context.contextMenuOverlay.hide();
```

## 💡 Custom Menus
The easiest way to create a custom menu is to use the `GenericContextMenu`. Just pass it a list of `ContextMenuButtonConfig` instances:
```dart
/// Custom Context Menu for an Image
ContextMenuRegion(
  contextMenu: GenericContextMenu(
    buttonConfigs: [
      ContextMenuButtonConfig(
        "View image in browser",
        onPressed: () => launch(_testImageUrl),
      ),
      ContextMenuButtonConfig(
        "Copy image path",
        onPressed: () => Clipboard.setData(ClipboardData(text: _testImageUrl)),
      )
    ],
  ),
  child: Image.network(_testImageUrl),
),
```

Another easy way to create custom menus is to use the `ContextMenuStateMixin`, and then call the `cardBuilder` and `buttonBuilder` methods to create your commands.

You can see this in action with the existing `LinkContextMenu`:
```dart
class _LinkContextMenuState extends State<LinkContextMenu> with ContextMenuStateMixin {
  @override
  Widget build(BuildContext context) {
    // cardBuilder is provided to us by the mixin, pass it a list of children to layout
    return cardBuilder.call(
      context,
      [
        // buttonBuilder is also provided by the mixin, use it to build each btn
        buttonBuilder.call(
          context,
          // button builder needs a config, so it knows how to setup the btn
          ContextMenuButtonConfig(
            "Open link in new window",
            icon: widget.useIcons ? Icon(Icons.link, size: 18) : null,
            onPressed: () => handlePressed(context, _handleNewWindowPressed),
          ),
        ),
        buttonBuilder.call(
          context,
          ContextMenuButtonConfig(
            "Copy link address",
            icon: widget.useIcons ? Icon(Icons.copy, size: 18) : null,
            onPressed: () => handlePressed(context, _handleClipboardPressed),
          ),
        )
      ],
    );
  }
```

In the above example, you could provide your own Card and Buttons directly, rather than using the builders, but the builders give you a couple of advantages:
* You can style all menus using the `button` and `card` builders on the `ContextMenuOverlay`
* All buttons will auto-close the context menu when triggered, saving you some boilerplate
* Your custom menus will match the existing set of menus

## 🐞 Bugs/Requests

If you encounter any problems please open an issue. If you feel the library is missing a feature, please raise a ticket on Github and we'll look into it. Pull request are welcome.

## 📃 License

MIT License
