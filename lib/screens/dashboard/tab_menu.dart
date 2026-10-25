import 'package:flutter/material.dart';

typedef OnTabClose = void Function(int index);
typedef OnTabSelect = void Function(int index);

class TabMenu extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final OnTabClose onTabClose;
  final OnTabSelect onTabSelect;

  const TabMenu({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabClose,
    required this.onTabSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      color: theme.primaryColor,
      // padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        padding: EdgeInsets.only(top: 8),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final bool isSelected = index == selectedIndex;

          return Material(
            elevation: isSelected ? 4 : 0,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              splashColor: Colors.blue.withOpacity(0.2),
              onTap: () => onTabSelect(index),
              child: AnimatedContainer(
                height: 30,
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.scaffoldBackgroundColor : theme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onTabClose(index),
                      behavior: HitTestBehavior.translucent,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
