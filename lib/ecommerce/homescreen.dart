import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:Marketing_Fruit/ecommerce/customer.dart';
import 'package:Marketing_Fruit/ecommerce/dresssection.dart';
import 'package:Marketing_Fruit/ecommerce/tshirtdesign.dart';
import 'shopsection.dart';

// Import your WooProduct model for type safety
// import 'path_to_your_woo_product_model.dart';

class FashionLandingPage extends StatefulWidget {
  const FashionLandingPage({super.key});

  @override
  State<FashionLandingPage> createState() => _FashionLandingPageState();
}

class _FashionLandingPageState extends State<FashionLandingPage> {
  final GlobalKey<NavigatorState> _nftNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _nftNavigatorKey,
      onGenerateRoute: (settings) {
        late Widget page;
        switch (settings.name) {
          case '/':
            page = BannerPage(navigate: _navigateTo);
            break;
          case '/tshirtdesign':
          // Get the WooProduct argument from navigation
            final product = settings.arguments as WooProduct?;
            if (product == null) {
              page = const Scaffold(body: Center(child: Text("No product selected")));
            } else {
              page = TShirtDetailPage(product: product);
            }
            break;
          default:
            page = const Scaffold(body: Center(child: Text("Page not found")));
        }
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }

  void _navigateTo(String routeName, {Object? arguments}) {
    _nftNavigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }
}

class BannerPage extends StatelessWidget {
  final void Function(String routeName, {Object? arguments}) navigate;
  const BannerPage({super.key, required this.navigate});

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isMobile) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => navigate('/tshirtdesign'),
            child: Center(
              child: Image.asset(
                'assets/mobile_banner.png',
                width: size.width,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }

    return _buildDesktopLayout(context, size);
  }

  Widget _buildDesktopLayout(BuildContext context, Size size) {
    final width = size.width;
    final height = size.height;
    final theme = Theme.of(context);
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    var scale = MediaQuery.of(context).devicePixelRatio;
    if (scale == 2.0) scale = 1.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60 / scale),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: EdgeInsets.only(left: 30 / scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 80 / scale),
                                Text(
                                  'FIND CLOTHES\nTHAT MATCHES\nYOUR STYLE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 64 / scale,
                                    fontWeight: FontWeight.w800,
                                    height: isMacOS ? 1.0 : 1.3,
                                    color: theme.hintColor,
                                  ),
                                ),
                                SizedBox(height: 16 / scale),
                                Text(
                                  'Browse through our diverse range of meticulously crafted garments, designed\n'
                                      'to bring out your individuality and cater to your sense of style.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22 / scale,
                                    color: theme.hintColor,
                                    height: isMacOS ? 1.2 : 1.5,
                                  ),
                                ),
                                SizedBox(height: 24 / scale),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 8,
                                    shadowColor: Colors.black.withOpacity(0.8),
                                    backgroundColor: theme.cardColor,
                                    foregroundColor: theme.hintColor,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 18 / scale,
                                      horizontal: 36 / scale,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: theme.scaffoldBackgroundColor,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () => navigate('/tshirtdesign'),
                                  child: Text(
                                    'Shop Now',
                                    style: TextStyle(fontSize: 18 / scale),
                                  ),
                                ),
                                SizedBox(height: isMacOS ? 20 / scale : 32 / scale),
                                Row(
                                  children: [
                                    _buildStat('200+', 'International Brands', scale, isMacOS),
                                    SizedBox(width: 40 / scale),
                                    _buildStat('2,000+', 'High-Quality Products', scale, isMacOS),
                                    SizedBox(width: 40 / scale),
                                    _buildStat('30,000+', 'Happy Customers', scale, isMacOS),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: isMacOS ? height * 0.9 : height * 0.85,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Align(
                                    alignment: isMacOS ? Alignment.bottomCenter : Alignment.topCenter,
                                    child: Image.asset(
                                      'assets/model.png',
                                      height: isMacOS ? height * 0.9 : height * 0.85,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: height * 0.065,
                                  right: width * 0.05,
                                  child: Image.asset(
                                    'assets/vector.png',
                                    width: width * 0.075,
                                    color: theme.hintColor,
                                  ),
                                ),
                                Positioned(
                                  top: height * 0.35,
                                  left: width * 0.035,
                                  child: Image.asset(
                                    'assets/vector.png',
                                    width: width * 0.025,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BRAND LOGOS STRIP
                  Container(
                    color: Colors.black,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 60 / scale,
                      horizontal: 160 / scale,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _BrandLogo(name: 'VERSACE'),
                        _BrandLogo(name: 'ZARA'),
                        _BrandLogo(name: 'GUCCI'),
                        _BrandLogo(name: 'PRADA'),
                        _BrandLogo(name: 'Calvin Klein'),
                      ],
                    ),
                  ),

                  SizedBox(height: 80 / scale),

                  // Desktop-only sections below
                  ShopSectionWidget(
                    onProductTap: (product) => navigate('/tshirtdesign', arguments: product),
                  ),
                  DressStyleSection(),
                  SizedBox(height: 20 / scale),
                  HappyCustomersSection(width: 1480,),
                  SizedBox(height: 60 / scale),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String title, String subtitle, double scale, bool isMac) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isMac ? 20 / scale : 24 / scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6 / scale),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: isMac ? 12 / scale : 14 / scale,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final String name;
  const _BrandLogo({required this.name});

  @override
  Widget build(BuildContext context) {
    var scale = MediaQuery.of(context).devicePixelRatio;
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    if (scale == 2.0) scale = 1.0;
    scale = isMacOS ? 0.9 : 1.0;

    return Text(
      name,
      style: GoogleFonts.poppins(
        fontSize: 22 / scale,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.3,
      ),
    );
  }
}
