import 'package:Marketing_Fruit/components/allproducts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';

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
    int? categoryId,
    String? orderBy,
    String? order,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category': '$categoryId',
      if (orderBy != null) 'orderby': orderBy,
      if (order != null) 'order': order,
    };
    final uri = Uri.parse('$_base/products').replace(queryParameters: qp);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Store API ${res.statusCode}: ${res.body}');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => WooProduct.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class WooProduct {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final double? price;
  final double? regularPrice;
  final int? discount;
  final double? rating;
  String? firebaseImageUrl;

  WooProduct({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.price,
    this.regularPrice,
    this.discount,
    this.rating,
    this.firebaseImageUrl,
  });

  factory WooProduct.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?) ?? const [];
    final priceStr = json['price']?.toString() ?? '0';
    final regularPriceStr = json['regular_price']?.toString() ?? '0';
    double price = double.tryParse(priceStr) ?? 0;
    double regularPrice = double.tryParse(regularPriceStr) ?? price;
    int? discount = regularPrice > price && regularPrice > 0
        ? ((100 * (regularPrice - price) / regularPrice)).round()
        : null;
    double? rating = (json['average_rating'] is String)
        ? double.tryParse(json['average_rating'])
        : (json['average_rating'] is double)
            ? json['average_rating'] as double
            : null;

    return WooProduct(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      image: images.isNotEmpty ? images.first['src']?.toString() : null,
      price: price,
      regularPrice: regularPrice,
      discount: discount,
      rating: rating,
    );
  }
}

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

// class ShopSectionWidget extends StatefulWidget {
//   final void Function(WooProduct product) onProductTap;
//   const ShopSectionWidget({super.key, required this.onProductTap});

//   @override
//   State<ShopSectionWidget> createState() => _ShopSectionWidgetState();
// }

class ShopSectionWidget extends StatefulWidget {
  final void Function(WooProduct product) onProductTap;
  const ShopSectionWidget({super.key, required this.onProductTap});

  @override
  State<ShopSectionWidget> createState() => _ShopSectionWidgetState();
}

class _ShopSectionWidgetState extends State<ShopSectionWidget> {
  final _api = WooStoreApi();
  List<WooProduct> _newArrivals = [];
  List<WooProduct> _topSelling = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initFirebaseAndFetch();
  }

  Future<void> _initFirebaseAndFetch() async {
    await Firebase.initializeApp();
    await _fetchProductsSections();
  }

  Future<void> _fetchProductsSections() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final arrivals = await _api.fetchProducts(
        page: 1,
        perPage: 6,
        orderBy: 'date',
        order: 'desc',
      );
      final topSelling = await _api.fetchProducts(
        page: 1,
        perPage: 6,
        orderBy: 'popularity',
        order: 'desc',
      );

      await _uploadFirebaseImages(arrivals);
      await _uploadFirebaseImages(topSelling);

      setState(() {
        _newArrivals = arrivals;
        _topSelling = topSelling;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadFirebaseImages(List<WooProduct> products) async {
    for (var prod in products) {
      if (prod.image != null) {
        prod.firebaseImageUrl = await getOrUploadFirebaseImageUrl(
          imageUrl: prod.image!,
          productId: prod.id.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.hintColor;
    final cardColor = theme.cardColor;
    var scale = MediaQuery.of(context).devicePixelRatio;
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    if (scale == 2.0) scale = 1.0;
    scale = isMacOS ? 0.9 : 1.0;

    return Padding(
      padding: EdgeInsets.all(isMacOS ? 50.0 * scale : 24.0 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ),
          if (!_loading && _error.isEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(vertical: 20 * scale, horizontal: 16 * scale),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10 * scale,
                      spreadRadius: 1 * scale,
                    )
                  ]),
              child: _buildSection("New Arrivals", _newArrivals, scale, textColor, cardColor, isMacOS),
            ),
            SizedBox(height: 32 * scale),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 32 * scale),
            Container(
              padding: EdgeInsets.symmetric(vertical: 20 * scale, horizontal: 16 * scale),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10 * scale,
                      spreadRadius: 1 * scale,
                    )
                  ]),
              child: _buildSection("Top Selling", _topSelling, scale, textColor, cardColor, isMacOS),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
      String title,
      List<WooProduct> products,
      double scale,
      Color textColor,
      Color cardColor,
      bool isMac) {
    final double cardWidth = 220 * scale;
    final double cardHeight = isMac ? 315 * scale : 300 * scale;
    final double listPadding = 12 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 28 * scale, color: textColor),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMac ? 10 * scale : 20 * scale),
        Center(
          child: SizedBox(
            height: cardHeight + 36,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: listPadding, vertical: 8),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (_, __) => SizedBox(width: 20 * scale),
              itemBuilder: (context, index) {
                final product = products[index];
                return _BaseMiniCard(
                  width: cardWidth,
                  height: cardHeight,
                  image: product.firebaseImageUrl ?? product.image ?? '',
                  title: product.name,
                  fallbackIcon: Icons.shopping_bag_outlined,
                  onTap: () => widget.onProductTap(product),
                  price: product.price,
                  regularPrice: product.regularPrice,
                  discount: product.discount,
                  rating: product.rating, chipText: '',
                );
              },
            ),
          ),
        ),
        SizedBox(height: 36), // Ensures "View All" button is separated
        _buildViewAllButton(title, scale, title == "New Arrivals" ? 'date' : 'popularity'),
      ],
    );
  }

  Widget _buildViewAllButton(String sectionTitle, double scale, String orderBy) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AllProductsGridPage(
              title: sectionTitle,
              onProductTap: widget.onProductTap,
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
      ),
      child: Text("View All", style: TextStyle(fontSize: 14 * scale)),
    );
  }
}

class _BaseMiniCard extends StatelessWidget {
  final double width; // <-- Added
  final double height;
  final String image;
  final String chipText;
  final String title;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final double? price;
  final double? regularPrice;
  final int? discount;
  final double? rating;

  const _BaseMiniCard({
    required this.width, // <-- Added
    required this.height,
    required this.image,
    required this.chipText,
    required this.title,
    required this.fallbackIcon,
    required this.onTap,
    this.price,
    this.regularPrice,
    this.discount,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width, // <-- Changed from fixed width
      height: height,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      height: 170,
                      width: width,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackBanner(),
                    )
                  : _fallbackBanner(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                title.isEmpty ? 'Untitled' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    "${rating?.toStringAsFixed(1) ?? '4.0'}/5",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Text(
                    price != null ? "\$${price!.toStringAsFixed(2)}" : "--",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (regularPrice != null && regularPrice != price) ...[
                    const SizedBox(width: 8),
                    Text(
                      "\$${regularPrice?.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  if (discount != null && discount! > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      "-$discount%",
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      height: 120,
      width: width, // <-- Changed from double.infinity
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 40, color: Colors.grey.shade600),
    );
  }
}
