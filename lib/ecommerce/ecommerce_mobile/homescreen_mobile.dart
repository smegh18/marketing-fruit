// homescreen_screen_mobile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Sections
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/customer_mobile.dart';
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/dresssection_mobile.dart';
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/shop_mobile.dart';
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/tshirt_mobile.dart';
import 'package:Marketing_Fruit/ecommerce/cart_service.dart';
import 'package:Marketing_Fruit/ecommerce/cart_screen.dart';

class HomeScreenMobile extends StatefulWidget {
  const HomeScreenMobile({super.key});

  @override
  State<HomeScreenMobile> createState() => _HomeScreenMobileState();
}

class _HomeScreenMobileState extends State<HomeScreenMobile> {
  static const double _maxContentWidth = 480;
  bool tshirt = false;
  Product? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    if (tshirt) {
      return TShirtScreenMobile(
        product: _selectedProduct,
        onBack: () => setState(() {
          tshirt = false;
          _selectedProduct = null;
        }),
      );
    }

    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final w = MediaQuery.of(context).size.width;
    final pad = _hp(w);
    final headlineSize = _clamp(w * 0.085, 22, 30);
    final bodySize = _clamp(w * 0.038, 12, 14);
    final statNumberSize = _clamp(w * 0.052, 14, 18);
    final statLabelSize = _clamp(w * 0.032, 10, 12);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Merchandise',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          // Live Cart Button with badge
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
          physics: const AlwaysScrollableScrollPhysics(),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // HERO / CTA
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(pad, 22, pad, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FIND CLOTHES\nTHAT MATCHES\nYOUR STYLE',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: headlineSize,
                              fontWeight: FontWeight.w800,
                              height: 1.08,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Browse through our diverse range of meticulously crafted garments, '
                            'designed to bring out your individuality and cater to your sense of style.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: bodySize,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedProduct = null;
                                  tshirt = true;
                                });
                              },
                              child: Text(
                                'Shop Now',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // STATS
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Stat(number: '200+', label: 'International Brands', nSize: statNumberSize, lSize: statLabelSize),
                        _Stat(number: '2,000+', label: 'Quality Products', nSize: statNumberSize, lSize: statLabelSize),
                        _Stat(number: '30,000+', label: 'Happy Customers', nSize: statNumberSize, lSize: statLabelSize),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // HERO IMAGE
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: AspectRatio(
                      aspectRatio: 9 / 11.5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                color: cardBg,
                                child: Image.asset('assets/model.png', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Positioned(top: 10, right: 10, child: Image.asset('assets/vector.png', width: w * 0.15)),
                          Positioned(left: 12, bottom: w * 0.25, child: Image.asset('assets/vector.png', width: w * 0.08)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // BRAND STRIP
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: const [
                          _BrandRow(['VERSACE', 'ZARA', 'GUCCI']),
                          _BrandRow(['PRADA', 'Calvin Klein']),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SHOP SECTION WITH WIRED onProductTap
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: ShopScreenMobile(
                      onProductTap: (product) {
                        setState(() {
                          _selectedProduct = product;
                          tshirt = true;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // DRESS SECTION
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: const DressScreenMobile(),
                  ),

                  const SizedBox(height: 18),

                  // CUSTOMER / TESTIMONIALS
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: ClipRect(child: const CustomerScreenMobile()),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _clamp(double v, double min, double max) => v < min ? min : (v > max ? max : v);
  static double _hp(double screenW) => screenW < 380 ? 14 : 18;
}

class _Stat extends StatelessWidget {
  final String number;
  final String label;
  final double nSize;
  final double lSize;

  const _Stat({required this.number, required this.label, required this.nSize, required this.lSize});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            number,
            style: GoogleFonts.poppins(
              fontSize: nSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: lSize,
              color: Colors.white.withOpacity(0.6),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  final List<String> brands;
  const _BrandRow(this.brands);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: brands
            .map((t) => Text(
                  t,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
