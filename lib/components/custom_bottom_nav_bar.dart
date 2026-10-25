import 'dart:ui';
import 'package:flutter/material.dart';

class NavItem {
  final String iconPath;
  final String label;

  const NavItem({
    required this.iconPath,
    required this.label,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: const Border(
              top: BorderSide(color: Colors.white30, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () => onTabSelected(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      item.iconPath,
                      width: isSelected ? 32 : 28,
                      height: isSelected ? 32 : 28,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: isSelected ? 13 : 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
