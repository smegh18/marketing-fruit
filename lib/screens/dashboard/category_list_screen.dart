import 'package:flutter/material.dart';
import 'category_table.dart';
import 'category_tab_bar.dart';
import 'category_filters.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Title + Search + Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const CategoryFilters(),
              ],
            ),
            const SizedBox(height: 20),

            // Tabs (All, Published, etc.)
            const CategoryTabBar(),
            const SizedBox(height: 20),

            // Category Table
            const Expanded(child: CategoryTable()),
          ],
        ),
      ),
    );
  }
}
