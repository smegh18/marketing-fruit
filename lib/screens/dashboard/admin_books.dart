import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/dashboard/books_filter_controller.dart';
import 'package:provider/provider.dart';

import 'package:Marketing_Fruit/components/books_search.dart';
import 'package:Marketing_Fruit/components/books_list.dart';
// import 'package:Marketing_Fruit/components/books_filter_controller.dart';

class AdminBooksScreen extends StatelessWidget {
  final void Function() onAddBook;
  const AdminBooksScreen({super.key, required this.onAddBook});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BooksFilterController(),
      child: Scaffold(
        backgroundColor: const Color(0xfff5f6fa),
        body: SafeArea(
          child: SingleChildScrollView(
            // No horizontal padding → children can use their own full width
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BooksSearchSection(onAddBook: onAddBook),
                const SizedBox(height: 16),
                const BookDashboardPage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
