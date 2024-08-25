import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_window_example/event_widget.dart';

int winId = 0;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    winId = windowId;
    final argument = args[2].isEmpty ? const {} : jsonDecode(args[2]) as Map<String, dynamic>;
    WindowController.fromWindowId(windowId).show();
    WindowController.fromWindowId(windowId).focus();
    runApp(_ExampleSubWindow(
      windowController: WindowController.fromWindowId(windowId),
      args: argument,
    ));
  } else {
    runApp(const _ExampleMainWindow());
  }
}

class _ExampleMainWindow extends StatefulWidget {
  const _ExampleMainWindow({Key? key}) : super(key: key);

  @override
  State<_ExampleMainWindow> createState() => _ExampleMainWindowState();
}

class CustomCursor extends MouseCursor {
  @override
  MouseCursorSession createSession(int device) {
    // TODO: implement createSession
    throw UnimplementedError();
  }

  @override
  // TODO: implement debugDescription
  String get debugDescription => throw UnimplementedError();
}

class _ExampleMainWindowState extends State<_ExampleMainWindow> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Listener(
          onPointerDown: (_) => debugPrint("down"),
          onPointerUp: (_) => debugPrint("up"),
          child: Column(
            children: [
              if (Platform.isLinux)
                FutureBuilder(
                  builder: (context, data) {
                    if (data.hasData) {
                      return Text("WindowID: ${WindowController.main().windowId}, XID: ${data.data}");
                    } else {
                      return Text(data.error.toString());
                    }
                  },
                  future: WindowController.main().getXID(),
                ),
              MouseRegion(
                cursor: SystemMouseCursors.alias,
                child: TextButton(
                  onPressed: () async {
                    final window = await DesktopMultiWindow.createWindow(jsonEncode({
                      'args1': 'Sub window',
                      'args2': 100,
                      'args3': true,
                      'bussiness': 'bussiness_test',
                    }));
                    window
                      ..setFrame(const Offset(0, 0) & const Size(1280, 720))
                      ..center()
                      ..setTitle('Another window')
                      ..show();
                  },
                  child: const Text('Create a new World!'),
                ),
              ),
              TextButton(
                child: const Text('Send event to all sub windows'),
                onPressed: () async {
                  final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
                  for (final windowId in subWindowIds) {
                    DesktopMultiWindow.invokeMethod(
                      windowId,
                      'broadcast',
                      'Broadcast from main window',
                    );
                  }
                },
              ),
              Expanded(
                child: EventWidget(controller: WindowController.fromWindowId(0)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleSubWindow extends StatelessWidget {
  const _ExampleSubWindow({
    Key? key,
    required this.windowController,
    required this.args,
  }) : super(key: key);

  final WindowController windowController;
  final Map? args;

  void debug(BuildContext context, Size size) async {
    final frame = await windowController.getFrame();
    print("${frame.width}/${frame.height}, ${size.width}/${size.height}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          debug(context, size);
          return SubWindowContent(
            windowController: windowController,
            args: args,
          );
        },
      ),
    );
  }
}

class SubWindowContent extends StatefulWidget {
  final WindowController windowController;
  final Map? args;
  const SubWindowContent({Key? key, required this.windowController, this.args}) : super(key: key);

  @override
  State<SubWindowContent> createState() => _SubWindowContentState();
}

class _SubWindowContentState extends State<SubWindowContent> with MultiWindowListener {
  bool isPreventClose = false;

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.addListener(this);
  }

  @override
  void dispose() {
    DesktopMultiWindow.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowEvent(String eventName) {
    print("window event: $eventName");
  }

  @override
  void onWindowEnterFullScreen() {
    print("enter fullscreen");
  }

  @override
  void onWindowLeaveFullScreen() {
    print("exit fullscreen");
  }

  @override
  Widget build(BuildContext context) {
    return SubWindowDragToResizeArea(
      windowId: widget.windowController.windowId,
      child: MouseRegion(
        cursor: SystemMouseCursors.alias,
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onPanDown: (_) {
                widget.windowController.startDragging();
              },
              child: const Row(children: [Expanded(child: Text("Multi Window App"))]),
            ),
          ),
          body: Column(
            children: [
              if (Platform.isLinux)
                FutureBuilder(
                  builder: (context, data) {
                    if (data.hasData) {
                      return Text("WindowID: ${widget.windowController.windowId}, XID: ${data.data}");
                    } else {
                      return Text(data.error.toString());
                    }
                  },
                  future: widget.windowController.getXID(),
                ),
              if (widget.args != null)
                Text(
                  'Arguments: ${widget.args.toString()}',
                  style: const TextStyle(fontSize: 20),
                ),
              // ValueListenableBuilder<bool>(
              //   valueListenable: DesktopLifecycle.instance.isActive,
              //   builder: (context, active, child) {
              //     if (active) {
              //       return const Text('Window Active');
              //     } else {
              //       return const Text('Window Inactive');
              //     }
              //   },
              // ),
              TextButton(
                onPressed: () async {
                  widget.windowController.close();
                },
                child: const Text('Close this window'),
              ),
              TextButton(
                onPressed: () async {
                  isPreventClose = !isPreventClose;
                  widget.windowController.setPreventClose(isPreventClose);

                  isPreventClose = await widget.windowController.isPreventClose();
                  setState(() {});
                },
                child: Text(!isPreventClose ? 'Set Prevent Close' : 'Unset Prevent Close'),
              ),
              TextButton(
                onPressed: () async {
                  widget.windowController.setFullscreen(true);
                },
                child: const Text('enter fullscreen'),
              ),
              TextButton(
                onPressed: () async {
                  widget.windowController.setFullscreen(false);
                },
                child: const Text('cancel fullscreen'),
              ),
              TextButton(
                onPressed: () async {
                  widget.windowController.minimize();
                },
                child: const Text('minimize'),
              ),
              TextButton(
                onPressed: () async {
                  if (await widget.windowController.isMaximized()) {
                    widget.windowController.unmaximize();
                  } else {
                    widget.windowController.maximize();
                  }
                },
                child: const Text('maximize/unmaximize'),
              ),
              TextButton(
                onPressed: () async {
                  widget.windowController.close();
                },
                child: const Text('close window'),
              ),
              Expanded(child: EventWidget(controller: widget.windowController)),
            ],
          ),
        ),
      ),
    );
  }
}
