// shop_screen_mobile.dart
import 'package:flutter/material.dart';

class ShopScreenMobile extends StatelessWidget {
  final List<Product>? newArrivals;
  final List<Product>? topSelling;
  final void Function(Product p)? onProductTap;
  final VoidCallback? onViewAllNewArrivals;
  final VoidCallback? onViewAllTopSelling;

  const ShopScreenMobile({
    super.key,
    this.newArrivals,
    this.topSelling,
    this.onProductTap,
    this.onViewAllNewArrivals,
    this.onViewAllTopSelling,
  });

  List<Product> get _newArrivals =>
      newArrivals ??
      const [
        Product(title: "T-shirt with Tape Details", price: 120, image: 'assets/shirt1.png', rating: 4.5),
        Product(title: "Skinny Fit Jeans", price: 240, oldPrice: 260, discount: 20, image: 'assets/jeans1.png', rating: 3.5),
        Product(title: "Checkered Shirt", price: 180, image: 'assets/shirt2.png', rating: 4.5),
        Product(title: "Sleeve Striped T-shirt", price: 130, oldPrice: 160, discount: 30, image: 'assets/shirt3.png', rating: 4.5),
      ];

  List<Product> get _topSelling =>
      topSelling ??
      const [
        Product(title: "Vertical Striped Shirt", price: 212, oldPrice: 235, discount: 10, image: 'assets/shirt4.png', rating: 5.0),
        Product(title: "Courage Graphic T-shirt", price: 145, image: 'assets/shirt5.png', rating: 4.0),
        Product(title: "Faded Skinny Jeans", price: 210, image: 'assets/jeans2.png', rating: 4.5),
        Product(title: "Loose Fit Bermuda Shorts", price: 80, image: 'assets/jeans1.png', rating: 3.0),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.04;
    final titleSize = _clamp(w * 0.065, 18, 22);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: "NEW ARRIVALS",
            titleSize: titleSize,
            products: _newArrivals,
            onProductTap: onProductTap,
            onViewAll: onViewAllNewArrivals,
          ),
          const SizedBox(height: 28),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 24),
          _Section(
            title: "TOP SELLING",
            titleSize: titleSize,
            products: _topSelling,
            onProductTap: onProductTap,
            onViewAll: onViewAllTopSelling,
          ),
        ],
      ),
    );
  }

  static double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}

class _Section extends StatelessWidget {
  final String title;
  final double titleSize;
  final List<Product> products;
  final void Function(Product p)? onProductTap;
  final VoidCallback? onViewAll;

  const _Section({
    required this.title,
    required this.titleSize,
    required this.products,
    this.onProductTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Non-scrollable grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, i) => _ProductCard(
            product: products[i],
            onTap: () => onProductTap?.call(products[i]),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  const _ProductCard({required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black38,
                    width: double.infinity,
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image, color: Colors.white24, size: 36),
                      ),
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
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              // Rating
              Row(
                children: [
                  _Stars(rating: product.rating),
                  const SizedBox(width: 6),
                  Text(
                    '${product.rating.toStringAsFixed(1)}/5',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Prices
              Row(
                children: [
                  Text(
                    '\$${_money(product.price)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  if (product.oldPrice != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '\$${_money(product.oldPrice!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  if (product.discount != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D55).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${product.discount}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFF2D55),
                          fontWeight: FontWeight.w700,
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
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star, size: 14, color: Colors.amber);
        } else if (i == full && half) {
          return const Icon(Icons.star_half, size: 14, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 14, color: Colors.amber);
        }
      }),
    );
  }
}

/// --- Model ---
class Product {
  final String title;
  final double price;
  final double? oldPrice;
  final int? discount;
  final String image;
  final double rating;

  const Product({
    required this.title,
    required this.price,
    this.oldPrice,
    this.discount,
    required this.image,
    required this.rating,
  });
}

/// --- Helpers ---
String _money(num v) {
  final s = v.toStringAsFixed(2);
  return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
}
