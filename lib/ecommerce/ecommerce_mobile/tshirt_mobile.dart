// tshirt_screen_mobile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/rating_mobile.dart';
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/mightalsolike_mobile.dart' hide Product;
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/newsletter_mobile.dart';
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/shop_mobile.dart';
import 'package:Marketing_Fruit/ecommerce/cart_service.dart';
import 'package:Marketing_Fruit/ecommerce/cart_screen.dart';
import 'package:Marketing_Fruit/ecommerce/checkout_screen.dart';

/// Product Details (Mobile)
class TShirtScreenMobile extends StatefulWidget {
  final Product? product;
  final VoidCallback? onBack;

  const TShirtScreenMobile({super.key, this.product, this.onBack});

  @override
  State<TShirtScreenMobile> createState() => _TShirtScreenMobileState();
}

class _TShirtScreenMobileState extends State<TShirtScreenMobile> {
  late final List<String> _images;

  final List<Color> _colors = const [
    Color(0xFF4C4B40), // olive
    Color(0xFF2F4A38), // deep green
    Color(0xFF363F62), // blue-grey
  ];

  final List<String> _sizes = const ['Small', 'Medium', 'Large', 'X-Large'];

  int _imgIndex = 0;
  int _qty = 1;
  int _colorIndex = 0;
  String _size = 'Large';

  @override
  void initState() {
    super.initState();
    if (widget.product != null && widget.product!.image.isNotEmpty) {
      _images = [
        widget.product!.image,
        'assets/tshirt1.png',
        'assets/tshirt2.png',
      ];
    } else {
      _images = const [
        'assets/tshirt.png',
        'assets/tshirt1.png',
        'assets/tshirt2.png',
        'assets/tshirt3.png',
      ];
    }
  }

  String get _title => widget.product?.title ?? 'ONE LIFE GRAPHIC\nT-SHIRT';
  double get _price => widget.product?.price ?? 260.0;
  double? get _oldPrice => widget.product?.oldPrice ?? 300.0;
  int? get _discount => widget.product?.discount ?? 40;
  double get _rating => widget.product?.rating ?? 4.5;
  String get _mainImage => _images[_imgIndex.clamp(0, _images.length - 1)];

  void _addToCart({bool navigateToCheckout = false}) {
    final item = CartItem(
      id: '${widget.product?.title ?? "tshirt"}_${_size}_$_colorIndex',
      productId: widget.product?.title.toLowerCase().replaceAll(' ', '_') ?? 'tshirt_graphic_01',
      title: widget.product?.title ?? 'One Life Graphic T-Shirt',
      price: _price,
      regularPrice: _oldPrice,
      image: _mainImage,
      quantity: _qty,
      size: _size,
      colorName: _colorIndex == 0 ? 'Olive' : (_colorIndex == 1 ? 'Deep Green' : 'Blue-Grey'),
      color: _colors[_colorIndex],
    );

    CartService.instance.addItem(item);

    if (navigateToCheckout) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF25293A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.purple.withOpacity(0.5)),
          ),
          content: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black26,
                ),
                child: _buildThumb(_mainImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Added to Cart!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      '$_qty × ${_title.replaceAll("\n", " ")} ($_size)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.purpleAccent,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.05;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          'Product Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // Live Cart icon with badge
          AnimatedBuilder(
            animation: CartService.instance,
            builder: (context, _) {
              final count = CartService.instance.itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Main product image card ----
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildThumb(_mainImage, fit: BoxFit.contain),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---- Thumbnail strip ----
              if (_images.length > 1) ...[
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final selected = i == _imgIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _imgIndex = i),
                        child: Container(
                          width: 68,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? Colors.purpleAccent : Colors.white12,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildThumb(_images[i]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ---- Title ----
              Text(
                _title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: _clamp(w * 0.06, 18, 22),
                  height: 1.15,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // ---- Stars + rating ----
              Row(
                children: [
                  _Stars(rating: _rating),
                  const SizedBox(width: 8),
                  Text(
                    '$_rating/5',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ---- Price / strike / discount ----
              Row(
                children: [
                  Text(
                    '\$${_price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (_oldPrice != null && _oldPrice! > _price) ...[
                    const SizedBox(width: 10),
                    Text(
                      '\$${_oldPrice!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.4),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  if (_discount != null && _discount! > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2D55).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.5)),
                      ),
                      child: Text(
                        '-$_discount%',
                        style: const TextStyle(
                          color: Color(0xFFFF2D55),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // ---- Description ----
              Text(
                "This graphic t-shirt is designed for both comfort and standout style. "
                "Crafted from premium breathable cotton, it features iconic artwork and a tailored fit.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 16),

              // ---- Select Colors ----
              const Text(
                'Select Colors',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(_colors.length, (i) {
                  final selected = _colorIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _ColorDot(
                      color: _colors[i],
                      selected: selected,
                      onTap: () => setState(() => _colorIndex = i),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 18),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 16),

              // ---- Choose Size ----
              const Text(
                'Choose Size',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _sizes.map((s) {
                  final selected = _size == s;
                  return _SizeChip(
                    label: s,
                    selected: selected,
                    onTap: () => setState(() => _size = s),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ---- Qty Stepper & CTA Buttons ----
              Row(
                children: [
                  _QtyStepper(
                    qty: _qty,
                    onDec: () => setState(() {
                      if (_qty > 1) _qty--;
                    }),
                    onInc: () => setState(() => _qty++),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _addToCart(navigateToCheckout: false),
                        icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.purpleAccent),
                        label: const Text(
                          'Add to Cart',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _addToCart(navigateToCheckout: true),
                        child: const Text(
                          'Buy Now',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 16),

              // Ratings / reviews section
              const RatingScreenMobile(),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 16),

              // Might also like
              const MightAlsoLikeScreenMobile(),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 16),

              // Newsletter signup
              const NewsletterScreenMobile(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(String image, {BoxFit fit = BoxFit.cover}) {
    if (image.isEmpty) {
      return const Icon(Icons.image, size: 30, color: Colors.white38);
    }
    if (image.startsWith('assets/')) {
      return Image.asset(image, fit: fit);
    }
    return Image.network(
      image,
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 30, color: Colors.white38),
    );
  }
}

/// ---------------- Pieces ----------------

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

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.purpleAccent : Colors.white24,
            width: selected ? 2.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.expand(),
            ),
            if (selected)
              const Icon(Icons.check, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.purple : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.purpleAccent : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const _QtyStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
            onPressed: onDec,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white70, size: 18),
            onPressed: onInc,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

double _clamp(double v, double min, double max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}
