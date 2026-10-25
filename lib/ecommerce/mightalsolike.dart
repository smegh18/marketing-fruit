import 'dart:ui';
import 'package:flutter/material.dart';
import 'shopsection.dart';


// class WooStoreApi {
//   static const String _base = 'https://marketingfruit.net/wp-json/wc/v3';
//   static const String consumerKey = 'ck_c807f426d3328fc433668a33577e24f8418e35f4';
//   static const String consumerSecret = 'cs_88568e745da8e56c8cb6d84eae19dca71d419aad';
//
//   Map<String, String> get _headers => {
//     'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
//     'Content-Type': 'application/json',
//   };
//
//   Future<List<WooProduct>> fetchProducts({
//     int page = 1,
//     int perPage = 12,
//     String? search,
//     int? categoryId,
//     String? orderBy,
//     String? order,
//   }) async {
//     final qp = <String, String>{
//       'page': '$page',
//       'per_page': '$perPage',
//       if (search != null && search.isNotEmpty) 'search': search,
//       if (categoryId != null) 'category': '$categoryId',
//       if (orderBy != null) 'orderby': orderBy,
//       if (order != null) 'order': order,
//     };
//     final uri = Uri.parse('$_base/products').replace(queryParameters: qp);
//     final res = await http.get(uri, headers: _headers);
//     if (res.statusCode != 200) {
//       throw Exception('Store API ${res.statusCode}: ${res.body}');
//     }
//     final List data = jsonDecode(res.body) as List;
//     return data.map((e) => WooProduct.fromJson(e as Map<String, dynamic>)).toList();
//   }
// }
//
// class WooProduct {
//   final int id;
//   final String name;
//   final String slug;
//   final String? image;
//   final double? price;
//   final double? regularPrice;
//   final int? discount; // percent discount, if calculated
//   final double? rating;
//   String? firebaseImageUrl;
//
//   WooProduct({
//     required this.id,
//     required this.name,
//     required this.slug,
//     this.image,
//     this.price,
//     this.regularPrice,
//     this.discount,
//     this.rating,
//     this.firebaseImageUrl,
//   });
//
//   factory WooProduct.fromJson(Map<String, dynamic> json) {
//     final images = (json['images'] as List?) ?? const [];
//     final priceStr = json['price']?.toString() ?? '0';
//     final regularPriceStr = json['regular_price']?.toString() ?? '0';
//     double price = double.tryParse(priceStr) ?? 0;
//     double regularPrice = double.tryParse(regularPriceStr) ?? price;
//     int? discount = regularPrice > price && regularPrice > 0
//         ? ((100 * (regularPrice - price) / regularPrice)).round()
//         : null;
//     double? rating = (json['average_rating'] is String)
//         ? double.tryParse(json['average_rating'])
//         : (json['average_rating'] is double)
//         ? json['average_rating'] as double
//         : null;
//
//     return WooProduct(
//       id: json['id'] as int,
//       name: (json['name'] ?? '').toString(),
//       slug: (json['slug'] ?? '').toString(),
//       image: images.isNotEmpty ? images.first['src']?.toString() : null,
//       price: price,
//       regularPrice: regularPrice,
//       discount: discount,
//       rating: rating,
//     );
//   }
// }
//
// // Reuse: Get or upload product image to Firebase Storage
// Future<String?> getOrUploadFirebaseImageUrl({
//   required String imageUrl,
//   required String productId,
// }) async {
//   final fileName = '$productId.jpg';
//   final storageRef = FirebaseStorage.instance.ref().child('products_images/$fileName');
//   try {
//     return await storageRef.getDownloadURL();
//   } on FirebaseException catch (e) {
//     if (e.code == 'object-not-found') {
//       try {
//         final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}';
//         final resp = await http.get(Uri.parse(proxyUrl));
//         if (resp.statusCode != 200) return null;
//         final imgBytes = resp.bodyBytes;
//         final uploadTask = await storageRef.putData(
//           imgBytes,
//           SettableMetadata(contentType: 'image/jpeg'),
//         );
//         return await uploadTask.ref.getDownloadURL();
//       } catch (uploadError) {
//         debugPrint('Firebase Upload Failed: $uploadError');
//         return null;
//       }
//     } else {
//       debugPrint('Firebase Exception: $e');
//       return null;
//     }
//   }
// }
// Use your WooStoreApi and WooProduct definitions
class AlsolikeSectionWidget extends StatefulWidget {
  const AlsolikeSectionWidget({super.key});

  @override
  State<AlsolikeSectionWidget> createState() => _AlsolikeSectionWidgetState();
}

class _AlsolikeSectionWidgetState extends State<AlsolikeSectionWidget> {
  final _api = WooStoreApi();
  List<WooProduct> _alsoLikeProducts = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchAlsolikeProducts();
  }

  Future<void> _fetchAlsolikeProducts() async {
    setState(() { _loading = true; _error = ''; });
    try {
      // You may define the logic you want for 'also like' (e.g., random/top selling/recommended)
      final products = await _api.fetchProducts(
        page: 1,
        perPage: 6,
        orderBy: 'date', // You can customize this
        order: 'desc',
      );
      for (var prod in products) {
        if (prod.image != null) {
          prod.firebaseImageUrl = await getOrUploadFirebaseImageUrl(
            imageUrl: prod.image!,
            productId: prod.id.toString(),
          );
        }
      }
      setState(() {
        _alsoLikeProducts = products;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scale = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0) {
      if (pixelRatio > baselinePixelRatio) {
        double ratio = baselinePixelRatio / pixelRatio;
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scale = ratio * 1.05;
          sfg = ratio * 1.1;
          sfgg = ratio * 1.1;
        } else {
          scale = ratio * 1.1;
          sfg = ratio * 1.4;
          sfgg = ratio * 1.82;
        }
      }
    }
    if (isMacOS) {
      scale = 0.9;
      sfg = 1.0;
      sfgg = 1.0;
    }

    final cardColor = theme.cardColor;
    final textColor = theme.hintColor;
    final borderColor = theme.scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.0 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10.0 * scale,
            spreadRadius: 1.0 * scale,
          ),
        ],
      ),
      padding: EdgeInsets.all(24.0 * scale),
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
          if (!_loading && _error.isEmpty)
            _buildSection("You Might Also Like", _alsoLikeProducts, scale, cardColor, textColor, borderColor, isMacOS),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<WooProduct> products, double scale, Color cardColor, Color textColor, Color borderColor, bool isMac) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22 * scale,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMac ? 10 * scale : 20 * scale),
        Center(
          child: SizedBox(
            height: isMac ? 350 * scale : 400 * scale,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (_, __) => SizedBox(width: 20 * scale),
              itemBuilder: (context, index) {
                return _buildProductCard(products[index], scale, cardColor, textColor, borderColor);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(WooProduct product, double scale, Color cardColor, Color textColor, Color borderColor) {
    return Container(
      width: 260 * scale,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10.0 * scale,
            spreadRadius: 1.0 * scale,
          ),
        ],
      ),
      padding: EdgeInsets.all(16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12 * scale),
              child: Container(
                decoration: const BoxDecoration(color: Colors.grey),
                child: product.firebaseImageUrl != null
                    ? Image.network(
                  product.firebaseImageUrl!,
                  fit: BoxFit.cover,
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(height: 14 * scale),
          Text(
            product.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16 * scale,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Icon(Icons.star, size: 16 * scale, color: Colors.amber),
              SizedBox(width: 6 * scale),
              Text("${product.rating?.toStringAsFixed(1) ?? '4.0'}/5", style: TextStyle(fontSize: 14 * scale)),
            ],
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Text(
                "\$${product.price?.toStringAsFixed(2) ?? '--'}",
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (product.regularPrice != null && product.regularPrice != product.price) ...[
                SizedBox(width: 8 * scale),
                Text(
                  "\$${product.regularPrice?.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14 * scale,
                    decoration: TextDecoration.lineThrough,
                    color: textColor,
                  ),
                ),
              ],
              if (product.discount != null && product.discount! > 0) ...[
                SizedBox(width: 6 * scale),
                Text(
                  "-${product.discount}%",
                  style: TextStyle(color: Colors.red, fontSize: 14 * scale),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
