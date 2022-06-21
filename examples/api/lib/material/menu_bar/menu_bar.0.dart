// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for MenuBar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String kMessage = '"Talk less. Smile more." - A. Burr';

void main() => runApp(const MenuBarApp());

enum MenuSelection {
  about('About'),
  showMessage('Show Message'),
  resetMessage('Reset Message'),
  hideMessage('Hide Message'),
  colorMenu('Color Menu'),
  colorRed('Red Background'),
  colorGreen('Green Background'),
  colorBlue('Blue Background');

  const MenuSelection(this.label);
  final String label;
}

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MenuBar Sample',
      home: Scaffold(body: MyMenuBar()),
    );
  }
}

class MyMenuBar extends StatefulWidget {
  const MyMenuBar({super.key});

  @override
  State<MyMenuBar> createState() => _MyMenuBarState();
}

class _MyMenuBarState extends State<MyMenuBar> {
  MenuSelection? lastSelection;

  bool get showingMessage => _showMessage;
  bool _showMessage = false;
  set showingMessage(bool value) {
    if (_showMessage != value) {
      setState(() {
        _showMessage = value;
      });
    }
  }

  Color get backgroundColor => _backgroundColor;
  Color _backgroundColor = Colors.red;
  set backgroundColor(Color value) {
    if (_backgroundColor != value) {
      setState(() {
        _backgroundColor = value;
      });
    }
  }

  void _activate(MenuSelection selection) {
    setState(() {
      lastSelection = selection;
    });
    switch (selection) {
      case MenuSelection.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Sample',
          applicationVersion: '1.0.0',
        );
        break;
      case MenuSelection.showMessage:
        showingMessage = true;
        break;
      case MenuSelection.resetMessage:
      case MenuSelection.hideMessage:
        showingMessage = false;
        break;
      case MenuSelection.colorMenu:
        break;
      case MenuSelection.colorRed:
        backgroundColor = Colors.red;
        break;
      case MenuSelection.colorGreen:
        backgroundColor = Colors.green;
        break;
      case MenuSelection.colorBlue:
        backgroundColor = Colors.blue;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        MenuBar(
          children: <MenuItem>[
            MenuBarMenu(
              autofocus: true,
              label: 'Menu App',
              children: <MenuItem>[
                MenuBarButton(
                  label: MenuSelection.about.label,
                  onSelected: () => _activate(MenuSelection.about),
                ),
                // Toggles the message.
                MenuBarButton(
                  label: showingMessage ? MenuSelection.hideMessage.label : MenuSelection.showMessage.label,
                  onSelected: () => _activate(showingMessage ? MenuSelection.hideMessage : MenuSelection.showMessage),
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
                ),
                // Hides the message, but is only enabled if the message isn't already hidden.
                MenuBarButton(
                  label: MenuSelection.resetMessage.label,
                  onSelected: showingMessage ? () => _activate(MenuSelection.resetMessage) : null,
                  shortcut: const SingleActivator(LogicalKeyboardKey.escape),
                ),
                MenuBarMenu(
                  label: 'Background Color',
                  children: <MenuItem>[
                    MenuItemGroup(members: <MenuItem>[
                      MenuBarButton(
                        onSelected: () => _activate(MenuSelection.colorRed),
                        label: MenuSelection.colorRed.label,
                        shortcut: const SingleActivator(LogicalKeyboardKey.keyR, control: true),
                      ),
                      MenuBarButton(
                        onSelected: () => _activate(MenuSelection.colorGreen),
                        label: MenuSelection.colorGreen.label,
                        shortcut: const SingleActivator(LogicalKeyboardKey.keyG, control: true),
                      ),
                    ]),
                    MenuBarButton(
                      onSelected: () => _activate(MenuSelection.colorBlue),
                      label: MenuSelection.colorBlue.label,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            color: backgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(showingMessage ? kMessage : '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Text(lastSelection != null ? 'Last Selected: ${lastSelection!.label}' : ''),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
