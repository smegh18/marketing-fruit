import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Marketing_Fruit/marketplace/subscribe_widget.dart';

import 'NFT_grid.dart';

class NftMarketplacePage extends StatefulWidget {
  const NftMarketplacePage({super.key});

  @override
  _NftMarketplacePageState createState() => _NftMarketplacePageState();
}

class _NftMarketplacePageState extends State<NftMarketplacePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _availableTags = ['Art', 'Music', 'Gaming', 'Photography'];
  final List<String> _selectedTags = [];
  int _selectedIndex = 6;

  void _onSidebarItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0 ) {
      if (pixelRatio > baselinePixelRatio) {
        double ratio = baselinePixelRatio / pixelRatio;
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.55;
          sfg = ratio * 1.1;
          sfgg = ratio * 1.1;
        } else {
          scaleFactor = ratio * 1.7;
          sfg = ratio * 1.5;
          sfgg = ratio * 1.82;
        }
      }
    } else {
      sfgg = 0.65;
    }
    final screenWidth = MediaQuery.of(context).size.width * scaleFactor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF2B2B2B),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // SizedBox(height: 30),
            // TopNavigationBar(),
            SizedBox(height: 60),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.2 * scaleFactor),
                child: _buildHeader(),
              ),
            ),
            SizedBox(height: 20),
            _buildSearchAndFilters(),
            SizedBox(height: 20),
            _buildCategoryBar(),
            SizedBox(height: 20),

            // ADAPTIVE HEIGHT NFT GRID
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06 * scaleFactor),
              child: NFTGrid(), // No need for a fixed height: grid will size to its children!
            ),

            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06 * scaleFactor),
              child: SubscribeWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0 ) {
      if (pixelRatio > baselinePixelRatio) {
        double ratio = baselinePixelRatio / pixelRatio;
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.55;
          sfg = ratio * 1.1;
        } else {
          scaleFactor = ratio * 1.7;
          sfg = ratio * 1.5;
        }
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textAlign: TextAlign.start,
          'Browse Marketplace',
          style: GoogleFonts.poppins(
            fontSize: 28 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Browse through more than 50k NFTs on the NFT Marketplace.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 22 * scaleFactor),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            hintText: 'Search your favourite NFTs',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showFilterDialog(),
                icon: Icon(Icons.filter_list),
                label: Text('Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  fixedSize: const Size(100, 50),
                ),
              ),
              SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) {
                  // Add logic based on selected sort option
                  print("Sort by: $value");
                },
                color: Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'Trending',
                    child: Text('Trending', style: TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 'Price',
                    child: Text('Price', style: TextStyle(color: Colors.white)),
                  ),
                ],
                child: ElevatedButton.icon(
                  icon: Icon(Icons.sort),
                  label: Text('Sort'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    fixedSize: const Size(100, 50),
                  ),
                  onPressed: null,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _selectedTags
                .map(
                  (tag) => Chip(
                label: Text(tag),
                labelStyle: TextStyle(color: Colors.white),
                backgroundColor: Colors.black,
                deleteIcon: Icon(Icons.close, color: Colors.white),
                onDeleted: () => _toggleTag(tag),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white24, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NFTs',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '6',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Color(0xFF2C2C2C),
          title: Text('Select Tags', style: TextStyle(color: Colors.white)),
          content: Wrap(
            spacing: 20,
            runSpacing: 10,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                selected: isSelected,
                label: Text(tag),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                selectedColor: Colors.black,
                backgroundColor: Colors.black,
                onSelected: (_) => _toggleTag(tag),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
              child: Text('Done', style: TextStyle(color: Colors.purpleAccent)),
            )
          ],
        );
      },
    );
  }
}
