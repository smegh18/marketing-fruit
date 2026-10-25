import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Marketing_Fruit/ecommerce/ecommerce_mobile/homescreen_mobile.dart';
import 'package:Marketing_Fruit/marketplace/NFT_mobile/NFTLandingMobile.dart';
import 'package:Marketing_Fruit/components/book_section_mobile.dart';


import 'package:Marketing_Fruit/components/sim_shop_screen.dart';

// Example detail widgets (Replace with your actual content widgets)
class SimShopPage extends StatelessWidget {
  final VoidCallback? onBack;
  const SimShopPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SimShopScreen(onBack: onBack);
  }
}

class MerchandisePage extends StatelessWidget {
  const MerchandisePage({super.key});

  @override
  Widget build(BuildContext context) => _SimplePage(title: "Merchandise");
}
class NFTPage extends StatelessWidget {
  const NFTPage({super.key});

  @override
  Widget build(BuildContext context) => _SimplePage(title: "NFT Marketplace");
}
class BooksGamesPage extends StatelessWidget {
  const BooksGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Books & Games", style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              BookSectionMobile(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  const _SimplePage({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "$title Page",
        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class MarketplaceChoiceSection extends StatefulWidget {
  final Function() onNFTtap;
  const MarketplaceChoiceSection({super.key, required this.onNFTtap});

  @override
  State<MarketplaceChoiceSection> createState() => _MarketplaceChoiceSectionState();
}

class _MarketplaceChoiceSectionState extends State<MarketplaceChoiceSection> {
  int? showDetailIndex;

  static final List<_MarketplaceCardData> _options = [
    _MarketplaceCardData("Sim Shop", Icons.shopping_cart),
    _MarketplaceCardData("Merchandise", Icons.shopping_bag),
    _MarketplaceCardData("NFT", Icons.monetization_on),
    _MarketplaceCardData("Books & Games", Icons.book),
  ];

  Widget _buildDetail(int index) {
    switch (index) {
      case 0: return SimShopPage(onBack: () => setState(() => showDetailIndex = null));
      case 1: return HomeScreenMobile();
      case 2: return NFTLandingMobilePage();
      case 3: return BooksGamesPage();
      default: return SizedBox.shrink();
    }
  }


  @override
  Widget build(BuildContext context) {
    if (showDetailIndex != null) {
      return _buildDetail(showDetailIndex!);
    }

    // Default grid of options
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Choose the marketplace",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 28,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.22,
                ),
                itemBuilder: (context, index) {
                  final card = _options[index];
                  return _MarketplaceOptionCard(
                    label: card.label,
                    icon: card.icon,
                    onTap: () {
                      if (index == 2) {
                        widget.onNFTtap(); // <<< Call this for NFT only
                      }
                      setState(() => showDetailIndex = index);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceCardData {
  final String label;
  final IconData icon;
  _MarketplaceCardData(this.label, this.icon);
}

class _MarketplaceOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MarketplaceOptionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.purple[700]),
              const SizedBox(height: 18),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
