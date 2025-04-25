<div align="center">
  <a href="#">
    <img src="https://user-images.githubusercontent.com/35843293/280504980-55b66c8f-455d-4b72-b7c5-9a021a362f53.png" alt="Logo" width="80" height="80"/>
  </a>
  <h1>Flutter Context Menu</h1>
  <p>
    A Flutter library that provides a flexible and customizable solution for creating and displaying context menus in Flutter applications. It allows you to easily add context menus to your UI, providing users with a convenient way to access additional options and actions specific to the selected item or area.
  </p>
  <a href="https://github.com/salah-rashad/flutter_context_menu/tree/main/example" target="_blank">
    View Example
  </a>
   · 
  <a href="https://github.com/salah-rashad/flutter_context_menu/issues/new?labels=bug&assignees=salah-rashad" target="_blank">
    Report Bug
  </a>
   · 
  <a href="https://github.com/salah-rashad/flutter_context_menu/issues/new?labels=enhancement&assignees=salah-rashad" target="_blank">
    Request Feature
  </a>
  <br/><br/>


  <a href="https://pub.dev/packages/flutter_context_menu" target="_blank">
    <img src="https://img.shields.io/pub/v/flutter_context_menu.svg?style=for-the-badge&label=pub&logo=dart"/> 
  </a>
  <a href="https://github.com/salah-rashad/flutter_context_menu/tree/main/LICENSE" target="_blank">
    <img src="https://img.shields.io/github/license/salah-rashad/flutter_context_menu.svg?style=for-the-badge&color=purple"/> 
  </a>
  <a href="https://github.com/salah-rashad/flutter_context_menu/stargazers" target="_blank">
    <img src="https://img.shields.io/github/stars/salah-rashad/flutter_context_menu.svg?style=for-the-badge&label=GitHub Stars&color=gold"/>
  </a>

  <br/>

  <a href="https://pub.dev/packages/flutter_context_menu/score" target="_blank">
    <img src="https://img.shields.io/pub/likes/flutter_context_menu.svg?style=for-the-badge&color=1e7b34&label=likes&labelColor=black"/>
    <img src="https://img.shields.io/pub/points/flutter_context_menu?style=for-the-badge&color=0056b3&label=Points&labelColor=black"/>
    <img src="https://img.shields.io/pub/popularity/flutter_context_menu.svg?style=for-the-badge&color=c05600&label=Popularity&labelColor=black"/>
  </a>
  <br/>
  <a href="https://thebsd.github.io/StandWithPalestine/" target="_blank">
    <img src="https://raw.githubusercontent.com/Safouene1/support-palestine-banner/master/StandWithPalestine.svg"/>
  </a>
  <br/><br/>
  
</div>

![Preview](assets/images/preview.gif)

## Features

- **`ContextMenu`**: The package includes a highly customizable context menu system that can be easily integrated into your Flutter application. It provides a seamless and intuitive user experience, enhancing the usability of your app.
- **Hierarchical Structure**: The context menu supports a hierarchical structure with submenu functionality. This enables you to create nested menus, providing a clear and organized representation of options and suboptions.
- **Selection Handling**: The package includes built-in selection handling for context menu items. It allows you to define callback functions for individual menu items, enabling you to execute specific actions or logic when an item is selected.
- **Customization Options**: Customize the appearance and behavior of the context menu to match your app's design and requirements. Modify the style, positioning, animation, and interaction of the menu to create a cohesive user interface.
  
- **Built-in Components**: The package includes built-in components, such as `MenuItem`, `MenuDivider`, and `MenuHeader`, that can be used in your context menu.

- **Cross Platform Support**: The package is compatible with multiple platforms, including Android, iOS, Web, and Desktop.

## Getting Started

### Installation

- #### Method 1 (Recommended):

  run this command in your terminal:

  ```bash
  flutter pub add flutter_context_menu
  ```

- #### Method 2:

  add this line to your `pubspec.yaml` dependencies:

  ```yaml
  dependencies:
      flutter_context_menu: ^0.2.0
  ```

  then, run this command in your terminal:

  ```bash
  flutter pub get
  ```

## Usage

1. First, import the package:
    ```dart
    import 'package:flutter_context_menu/flutter_context_menu.dart';
    ```
    
2. Then, initialize a `ContextMenu` instance:
    
    ```dart
    // define your context menu entries
    final entries = <ContextMenuEntry>[
      const MenuHeader(text: "Context Menu"),
      MenuItem(
        label: 'Copy',
        icon: Icons.copy,
        onSelected: () {
          // implement copy
        },
      ),
      MenuItem(
        label: 'Paste',
        icon: Icons.paste,
        onSelected: () {
          // implement paste
        },
      ),
      const MenuDivider(),
      MenuItem.submenu(
        label: 'Edit',
        icon: Icons.edit,
        items: [
          MenuItem(
            label: 'Undo',
            value: "Undo",
            icon: Icons.undo,
            onSelected: () {
              // implement undo
            },
          ),
          MenuItem(
            label: 'Redo',
            value: 'Redo',
            icon: Icons.redo,
            onSelected: () {
              // implement redo
            },
          ),
        ],
      ),
    ];

    // initialize a context menu
    final menu = ContextMenu(
      entries: entries,
      position: const Offset(300, 300),
      padding: const EdgeInsets.all(8.0),
    );
    ```

3. Finally, to show the context menu, there are two ways:
    - **Method 1**: Directly calling one of the show methods. 
      > This will show the context menu at the manually specified position.
      ```dart
      showContextMenu(context, contextMenu: menu);
      // or 
      final selectedValue = await menu.show(context);
      print(selectedValue);
      ```

    - **Method 2**: Using the `ContextMenuRegion` widget to show the context menu when the user right-clicks or long-presses the region area.
      > This will show the context menu where the user clicks when the `position` property is not specified in the `ContextMenu` constructor.
      ```dart
      ...

      @override
      Widget build(BuildContext context) {
        return Column(
          children: [
            ContextMenuRegion(
              contextMenu: contextMenu,
              onItemSelected: (value) {
                print(value);
              },
              child: Container(
                color: Colors.indigo,
                height: 300,
                width: 300,
                child: const Center(
                  child: Text(
                    'Right click or long press!',
                  ),
                ),
              ),
            )
          ],
        );
      }
      ```
    
## Customization

> **Theme**: By default, the context menu and its items uses the `MaterialApp`'s theme data for styling. However, you can customize the appearance and behavior of the context menu by modifying the theme data. Or individually by specifying a `BoxDecoration` in the `boxDecoration` property of the `ContextMenu`.

> **Custom Entries**: You can create your own context menu entries by subclassing the `ContextMenuEntry` class. This allows you to customize the appearance, behavior, and functionality of the context menu items.

## Learn More

- More info: Full documentation will be provided, inshallah 🙏
- See: [Full Example](https://github.com/salah-rashad/flutter_context_menu/tree/main/example)

## Feedback and Contributions

If you have any suggestions or feedback, please [open an issue](https://github.com/salah-rashad/flutter_context_menu/issues/new) or [create a pull request](https://github.com/salah-rashad/flutter_context_menu/pulls). 

If you like this package, please [star](https://github.com/salah-rashad/flutter_context_menu) it and follow me on [X](https://x.com/SalahRAhmed) and [GitHub](https://github.com/salah-rashad).

## License

This project is licensed under the [BSD 3-Clause License](https://github.com/salah-rashad/flutter_context_menu/tree/main/LICENSE).


<br/><br/>

<div align="center"> 
  Made with ❤️ in Egypt 🇪🇬
  <br/>
  <h3 align="center"> 🇵🇸 Stand With Palestine 🇵🇸 </h3>
</div>
