// lib/components/books_filter_controller.dart
import 'package:flutter/foundation.dart';

class BooksFilterController extends ChangeNotifier {
  String _search = '';
  String _tag = 'All Tags';

  String get search => _search;
  String get tag => _tag;

  void setSearch(String value) {
    if (value == _search) return;
    _search = value.trim().toLowerCase();
    notifyListeners();
  }

  void setTag(String? value) {
    final v = (value ?? 'All Tags');
    if (v == _tag) return;
    _tag = v;
    notifyListeners();
  }
}
