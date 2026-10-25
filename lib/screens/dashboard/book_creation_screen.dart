// lib/screens/dashboard/book_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/dashboard/book_creation_controller.dart';
import 'package:provider/provider.dart';
// import 'package:Marketing_Fruit/components/book_creation_controller.dart';

import '../../components/books_info.dart';
import '../../components/book_upload.dart';
import '../../components/book_preview.dart';
import '../../components/books_publish.dart';
import '../../components/book_timeline_section.dart';

class BookCreationScreen extends StatefulWidget {
  const BookCreationScreen({super.key});

  @override
  State<BookCreationScreen> createState() => _BookCreationScreenState();
}

class _BookCreationScreenState extends State<BookCreationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<String> _stepLabels = [
    'Books Info',
    'Content Upload',
    'Preview',
    'Publish',
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookCreationController(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                BookTimelineSection(
                  currentStep: _currentPage,
                  steps: _stepLabels,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: const [
                      BookInfoSection(),
                      BookUploadSection(),
                      BookPreviewSection(),
                      BooksOverviewSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      ElevatedButton(
                        onPressed: _previousPage,
                        child: const Text('Previous'),
                      ),
                    if (_currentPage < 3)
                      ElevatedButton(
                        onPressed: _nextPage,
                        child: const Text('Next'),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
