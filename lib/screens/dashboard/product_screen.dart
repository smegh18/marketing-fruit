import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class WooStoreApi {
  static const String _base = 'https://marketingfruit.net/wp-json/wc/v3';
  static const String consumerKey = 'ck_c807f426d3328fc433668a33577e24f8418e35f4';
  static const String consumerSecret = 'cs_88568e745da8e56c8cb6d84eae19dca71d419aad';

  Map<String, String> get _headers => {
    'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
    'Content-Type': 'application/json',
  };

  Future<List<WooProduct>> fetchProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    int? minPrice,
    int? maxPrice,
    int? categoryId,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'search': search,
      if (minPrice != null) 'min_price': '$minPrice',
      if (maxPrice != null) 'max_price': '$maxPrice',
      if (categoryId != null) 'category': '$categoryId',
    };
    final uri = Uri.parse('$_base/products').replace(queryParameters: qp);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Store API ${res.statusCode}: ${res.body}');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => WooProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<WooCategory>> fetchCategories() async {
    final uri = Uri.parse('$_base/products/categories');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Categories ${res.statusCode}: ${res.body}');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => WooCategory.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class WooProduct {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final List<String> categories;
  final int? stockQuantity;
  final String stockStatus;
  String? firebaseImageUrl;

  WooProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
    required this.categories,
    required this.stockQuantity,
    required this.stockStatus,
    this.firebaseImageUrl,
  });

  factory WooProduct.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? const [];
    final cats = (json['categories'] as List?)
        ?.map((c) => (c as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList() ?? const <String>[];
    return WooProduct(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      image: images.isNotEmpty ? images.first['src']?.toString() : null,
      categories: cats,
      stockQuantity: json['stock_quantity'] is int ? json['stock_quantity'] as int : null,
      stockStatus: (json['stock_status'] ?? 'instock').toString(),
    );
  }
}

class WooCategory {
  final int id;
  final String name;
  final String slug;
  final int count;
  WooCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.count,
  });
  factory WooCategory.fromJson(Map<String, dynamic> json) => WooCategory(
    id: json['id'] as int,
    name: (json['name'] ?? '').toString(),
    slug: (json['slug'] ?? '').toString(),
    count: (json['count'] ?? 0) as int,
  );
}

// Get or upload product image to Firebase Storage
Future<String?> getOrUploadFirebaseImageUrl({
  required String imageUrl,
  required String productId,
}) async {
  final fileName = '$productId.jpg';
  final storageRef = FirebaseStorage.instance.ref().child('products_images/$fileName');
  try {
    return await storageRef.getDownloadURL();
  } on FirebaseException catch (e) {
    if (e.code == 'object-not-found') {
      try {
        final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}';
        final resp = await http.get(Uri.parse(proxyUrl));
        if (resp.statusCode != 200) return null;
        final imgBytes = resp.bodyBytes;
        final uploadTask = await storageRef.putData(
          imgBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        return await uploadTask.ref.getDownloadURL();
      } catch (uploadError) {
        debugPrint('Firebase Upload Failed: $uploadError');
        return null;
      }
    } else {
      debugPrint('Firebase Exception: $e');
      return null;
    }
  }
}

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});
  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  final _api = WooStoreApi();
  List<WooProduct> _products = [];
  List<WooCategory> _categories = [];
  int _page = 1;
  final int _perPage = 20;
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  int? _selectedCategoryId;

  final _searchCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFirebaseAndBootstrap();
  }

  Future<void> _initFirebaseAndBootstrap() async {
    await Firebase.initializeApp();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final cats = await _api.fetchCategories();
      setState(() {
        _categories = cats;
      });
      await _fetch(reset: true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _products = [];
        _page = 1;
        _error = '';
      });
    }
    final int? minPrice = int.tryParse(_minCtrl.text.trim());
    final int? maxPrice = int.tryParse(_maxCtrl.text.trim());
    final String? search = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
    try {
      if (reset) {
        setState(() => _loading = true);
      } else {
        setState(() => _loadingMore = true);
      }

      final list = await _api.fetchProducts(
        page: _page,
        perPage: _perPage,
        search: search,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categoryId: _selectedCategoryId,
      );

      // For each product, get or upload then get the Firebase Storage URL.
      for (var prod in list) {
        if (prod.image != null) {
          prod.firebaseImageUrl = await getOrUploadFirebaseImageUrl(
            imageUrl: prod.image!,
            productId: prod.id.toString(),
          );
        }
      }

      setState(() {
        if (reset) {
          _products = list;
        } else {
          _products.addAll(list);
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _fetch(reset: true);
  }

  void _loadMore() {
    setState(() => _page += 1);
    _fetch(reset: false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;
    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // ... (filters omitted for brevity, keep original code)
                const SizedBox(height: 20),
                const Text('Products List', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),
                if (_loading && _products.isEmpty)
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                if (!_loading && _products.isEmpty && _error.isEmpty)
                  const Expanded(child: Center(child: Text('No products found.'))),
                if (_products.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          columnSpacing: 48,
                          headingRowHeight: 48,
                          columns: const [
                            DataColumn(label: Text('Image')),
                            DataColumn(label: Text('Product Name')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Pieces')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: _products.map((p) {
                            final firstCat = p.categories.isNotEmpty ? p.categories.first : '-';
                            final pieces = p.stockQuantity?.toString() ?? (p.stockStatus == 'instock' ? '—' : '0');
                            return DataRow(cells: [
                              DataCell(
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: (p.firebaseImageUrl != null)
                                        ? Image.network(p.firebaseImageUrl!, fit: BoxFit.cover)
                                        : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(p.name)),
                              DataCell(Text(firstCat)),
                              DataCell(Text(pieces)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () {/* Implement delete on server-side */},
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_products.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loadingMore ? null : _loadMore,
                        icon: _loadingMore
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.expand_more),
                        label: const Text('Load more'),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
