
// mightalsolike_screen_mobile.dart
import 'package:flutter/material.dart';

class MightAlsoLikeScreenMobile extends StatelessWidget {
  /// Provide your own products or use the defaults below.
  final List<Product>? products;

  /// Optional: handle taps on a product card.
  final void Function(Product product)? onProductTap;

  const MightAlsoLikeScreenMobile({
    super.key,
    this.products,
    this.onProductTap,
  });

  List<Product> get _items =>
      products ??
          const [
            Product(
              title: "Polo with Contrast Trims",
              price: 212,
              oldPrice: 242,
              discountPercent: 20,
              image: 'assets/shirt1.png',
              rating: 4.0,
            ),
            Product(
              title: "Gradient Graphic T-shirt",
              price: 145,
              image: 'assets/shirt2.png',
              rating: 3.5,
            ),
            Product(
              title: "Checkered Shirt",
              price: 180,
              image: 'assets/shirt3.png',
              rating: 4.5,
            ),
            Product(
              title: "Sleeve Striped Tee",
              price: 130,
              oldPrice: 160,
              discountPercent: 30,
              image: 'assets/shirt1.png',
              rating: 4.5,
            ),
          ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.06;
    final titleSize = _clamp(w * 0.09, 20, 26);

    return Container(
      color: const Color(0xFFF6F6F6),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 18, pad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'YOU MIGHT\nALSO LIKE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),

              // 2-column grid of products
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  // 👉 Smaller ratio = taller card
                  childAspectRatio: 0.70,
                ),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final p = _items[i];
                  return _ProductCard(
                    product: p,
                    onTap: () => onProductTap?.call(p),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}

/// --- UI building blocks ---

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  const _ProductCard({required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image taller now
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: const Color(0xFFEDEDED),
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),

              // Stars + rating text
              Row(
                children: [
                  _Stars(rating: product.rating),
                  const SizedBox(width: 6),
                  Text(
                    '${product.rating.toStringAsFixed(1)}/5',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Price row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '\$${_money(product.price)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (product.oldPrice != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '\$${_money(product.oldPrice!)}',
                      style: const TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                  if (product.discountPercent != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7E7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '-${product.discountPercent}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD82424),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating; // 0..5, supports halves like 3.5
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final int full = rating.floor();
    final bool half = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star, size: 16, color: Colors.amber);
        } else if (i == full && half) {
          return const Icon(Icons.star_half, size: 16, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 16, color: Colors.amber);
        }
      }),
    );
  }
}

/// --- Simple model ---

class Product {
  final String title;
  final double price;
  final double? oldPrice;
  final int? discountPercent;
  final String image;
  final double rating;

  const Product({
    required this.title,
    required this.price,
    this.oldPrice,
    this.discountPercent,
    required this.image,
    required this.rating,
  });
}

/// --- Helpers ---
String _money(num v) {
  final s = v.toStringAsFixed(2);
  return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
}
