import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Include this if you use the header component provided above

import 'NFTgridmobile.dart';

class BrowseMarketplaceMobileHeader extends StatefulWidget {
  final void Function(String)? onSearch;

  const BrowseMarketplaceMobileHeader({super.key, this.onSearch});

  @override
  State<BrowseMarketplaceMobileHeader> createState() => _BrowseMarketplaceMobileHeaderState();
}

class _BrowseMarketplaceMobileHeaderState extends State<BrowseMarketplaceMobileHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Browse Marketplace",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Browse through more than 50k NFTs on the NFT Marketplace.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search your favourite NFTs",
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: widget.onSearch,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white54),
                  onPressed: () {
                    if (widget.onSearch != null) {
                      widget.onSearch!(_searchController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class NFTMarketplaceMobilePage extends StatefulWidget {
  final void Function(String) onNFTTap;
  const NFTMarketplaceMobilePage({super.key, required this.onNFTTap});

  @override
  State<NFTMarketplaceMobilePage> createState() => _NFTMarketplaceMobilePageState();
}

class _NFTMarketplaceMobilePageState extends State<NFTMarketplaceMobilePage> {
  String _searchQuery = "";

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    // TODO: Add your filtering logic for the grid below
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrowseMarketplaceMobileHeader(onSearch: _onSearch),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: NFTGridMobile(onNFTTap: widget.onNFTTap,), // Replace with your actual data/grid
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
