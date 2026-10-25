import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Marketing_Fruit/marketplace/NFT_Profile.dart';
import 'package:Marketing_Fruit/marketplace/NFT_market.dart';
import 'package:Marketing_Fruit/marketplace/browse_categories.dart';
import 'package:Marketing_Fruit/marketplace/subscribe_widget.dart';
import 'package:Marketing_Fruit/marketplace/top_creators.dart';


// void main() {
//   runApp(const NFTApp());
// }
//
// class NFTApp extends StatelessWidget {
//   const NFTApp({super.key});
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'NFT Landing Page',
//       home: const NFTLandingScreen(),
//     );
//   }
// }

class NFTLandingScreen extends StatefulWidget {
  const NFTLandingScreen({super.key});

  @override
  State<NFTLandingScreen> createState() => _NFTLandingScreenState();
}

class _NFTLandingScreenState extends State<NFTLandingScreen> {
  final GlobalKey<NavigatorState> _nftNavigatorKey = GlobalKey<NavigatorState>();


  int _selectedIndex = 6;

  void _onSidebarItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _nftNavigatorKey,
      onGenerateRoute: (settings) {
        late Widget page;

        switch (settings.name) {
          case '/':
            page = NFTMainLandingBody(navigate: _navigateTo);
            break;
          case '/trendingDetail':
            page = NftMarketplacePage();
            break;
          case '/creatorProfile':
            page = const NftProfileScreen();
            break;
        // Add more cases as needed
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




class NFTMainLandingBody extends StatelessWidget {
  final void Function(String routeName, {Object? arguments}) navigate;

  const NFTMainLandingBody({super.key, required this.navigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          final screenWidth = constraints.maxWidth;
          final padding = screenWidth * 0.02;
          final titleFontSize = screenWidth * (isMobile ? 0.06 : 0.05);
          final textFontSize = screenWidth * (isMobile ? 0.03 : 0.02);
          final statSpacing = isMobile ? 20.0 : 30.0;
          final imageSize = screenWidth * (isMobile ? 0.5 : 0.4);

          return CustomScrollView(
            slivers: [
              // SliverPadding(
              //   padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
              //   sliver: SliverToBoxAdapter(child: TopNavigationBar()),
              // ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 50),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLeftContent(context,titleFontSize, textFontSize, statSpacing),
                          const SizedBox(height: 40),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/heroanimation.gif',
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      )
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.35,
                            child: _buildLeftContent(
                              context,
                              titleFontSize,
                              textFontSize,
                              statSpacing,
                            ),
                          ),
                          const SizedBox(width: 100),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/heroanimation.gif',
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                      TrendingSection(onItemTap: () => navigate('/trendingDetail'), padding: padding,),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: TopCreatorsScreen(onCreatorTap: () => navigate('/creatorProfile'), padding: padding,),
              ),
              SliverToBoxAdapter(child: BrowseCategoriesSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.065, vertical: 20),
                  child: Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: SubscribeWidget(),
                  ),
                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftContent(context,
      double titleFontSize, double textFontSize, double statSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover\nDigital Art &\nCollect NFTs',
          style: GoogleFonts.spaceGrotesk(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 20),
        Text(
          'NFT marketplace UI created with Anima for \nFigma.Collect, buy and sell art from more \nthan 20k NFT artists.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: textFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.8),
            height: 1,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NftMarketplacePage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA259FF),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.rocket_launch_rounded,
              size: 20, color: Colors.white),
          label: Text(
            'Get Started',
            style: GoogleFonts.spaceGrotesk(
              fontSize: textFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 60),
        Wrap(
          spacing: statSpacing,
          runSpacing: 20,
          children: const [
            StatBox(count: '240k+', label: 'Total Sale'),
            StatBox(count: '100k+', label: 'Auctions'),
            StatBox(count: '240k+', label: 'Artists'),
          ],
        ),
      ],
    );
  }
}


class StatBox extends StatelessWidget {
  final String count;
  final String label;

  const StatBox({super.key, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}


class TrendingSection extends StatefulWidget {
  final double padding;
  final VoidCallback onItemTap;

  const TrendingSection({
    super.key,
    required this.padding,
    required this.onItemTap,
  });

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double ds = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0 ) {
      if (pixelRatio > baselinePixelRatio) {
        // Clamp the values within a reasonable scaling range
        double ratio = baselinePixelRatio / pixelRatio;

        // Prevent too aggressive scaling at 125%
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.1; // mild scale
          ds = ratio * 1.2;
          sfg = ratio * 1.1;
        } else {
          scaleFactor = ratio * 1.25; // regular scale
          sfg = ratio * 1.5;
          ds = ratio * 1.33;
        }
      }
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.065),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Collection',
            style: GoogleFonts.poppins(
              fontSize: 28 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
            'Checkout Our Weekly Updated Trending Collection.',
            style: GoogleFonts.poppins(
              fontSize: 22 * scaleFactor,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 32 * scaleFactor),
          SizedBox(
            height: isMacOS ? screenHeight * 0.58 * ds : screenHeight * 0.53 * ds,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 6 ,
              radius: Radius.circular(4 ),
              child: Padding(
                padding: EdgeInsets.only(bottom: 1 * sfg),
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 2 * sfg),
                  itemCount: 6,
                  separatorBuilder: (context, index) => SizedBox(width: 12 * scaleFactor),
                  itemBuilder: (context, index) {
                    return buildTrendingCard(
                      context,
                      dpr: scaleFactor,
                      mainImage: "assets/Assets/kutta.png",
                      subImages: ["assets/Assets/billi.png", "assets/Assets/bhalu.png"],
                      title: "DSGN Animals",
                      creator: "MrFox",
                      creatorAvatar: "assets/Assets/fox.png",
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTrendingCard(
      BuildContext context, {
        required double dpr,
        required String mainImage,
        required List<String> subImages,
        required String title,
        required String creator,
        required String creatorAvatar,
      }) {
    bool isHovered = false;
    final screenWidth = MediaQuery.of(context).size.width * dpr;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              alignment: Alignment.center,
              width: screenWidth * 0.20 * dpr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedScale(
                    scale: isHovered ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        mainImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * dpr),
                  Row(
                    children: [
                      ...subImages.map(
                            (img) => _HoverableImage(
                          imagePath: img,
                          size: screenWidth * 0.05 * dpr,
                        ),
                      ),
                      Container(
                        width: screenWidth * 0.05 *dpr,
                        height: screenWidth * 0.05 * dpr,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * dpr,
                          vertical: 10 * dpr,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB259FF),
                          borderRadius: BorderRadius.circular(16 * dpr),
                        ),
                        child: Center(
                          child: Text(
                            '1025+',
                            style: GoogleFonts.spaceMono(
                              fontSize: 22 * dpr * 0.7,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 10 * dpr),
                  Text(
                    title,
                    style: GoogleFonts.workSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * dpr,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4 * dpr),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(creatorAvatar),
                        radius: 12 * dpr,
                      ),
                      SizedBox(width: 6 * dpr),
                      Text(
                        creator,
                        style: GoogleFonts.poppins(
                          fontSize: 12 * dpr,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HoverableImage extends StatefulWidget {
  final String imagePath;
  final double size;

  const _HoverableImage({
    required this.imagePath,
    required this.size,
  });

  @override
  State<_HoverableImage> createState() => _HoverableImageState();
}

class _HoverableImageState extends State<_HoverableImage> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: !_hovered ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              widget.imagePath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}


