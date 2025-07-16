/*
 * Copyright (c) 2025 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

class SettingNavigationItem {
  final String Function() title;
  final IconData icon;

  const SettingNavigationItem({required this.title, required this.icon});
}

class MyNavigationBar extends StatefulWidget {
  final double width;
  final List<SettingNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const MyNavigationBar({
    super.key,
    this.width = 144,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant MyNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ChewieTheme.canvasColor,
        border: ChewieTheme.rightDivider,
      ),
      child: ListView.builder(
        itemCount: widget.items.length,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: SettingNavigationItemWidget(
              title: item.title(),
              icon: item.icon,
              selected: index == _selectedIndex,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onSelected(index);
              },
            ),
          );
        },
      ),
    );
  }
}

class SettingNavigationItemWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const SettingNavigationItemWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? ChewieTheme.primaryColor : Colors.transparent;
    final textColor = selected ? ChewieTheme.primaryButtonColor : null;

    return PressableAnimation(
      onTap: onTap,
      child: InkAnimation(
        color: bgColor,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Icon(icon, color: textColor),
              // const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: ChewieTheme.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
