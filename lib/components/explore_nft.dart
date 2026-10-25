import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

import '../screens/dashboard/NFTDetailScreen.dart';

String resolveImage(String? path) {
  if (path == null) return '';
  if (path.startsWith('ipfs://')) {
    final ipfsHash = path.substring(7);
    return 'https://gateway.pinata.cloud/ipfs/$ipfsHash';
  }
  return path;
}

class NFT {
  final String key;
  final String title;
  final String creator;
  final String price;
  final String imagePath;
  final String category;

  NFT({
    required this.key,
    required this.title,
    required this.creator,
    required this.price,
    required this.imagePath,
    required this.category,
  });

  factory NFT.fromMap(Map<dynamic, dynamic> map, String key) {
    return NFT(
      key: key,
      title: map['name']?.toString() ?? '',
      creator: map['type']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      imagePath: map['graphic']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
    );
  }
}

class ExploreNFTSection extends StatefulWidget {
  final double width;
  const ExploreNFTSection({super.key, required this.width});

  @override
  State<ExploreNFTSection> createState() => _ExploreNFTSectionState();
}

class _ExploreNFTSectionState extends State<ExploreNFTSection> {
  final ScrollController _scrollController = ScrollController();

  List<NFT> _nfts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNFTs();
  }

  Future<void> _fetchNFTs() async {
    setState(() => _isLoading = true);
    try {
      final ref = FirebaseDatabase.instance.ref("nft");
      final snapshot = await ref.get();
      if (!snapshot.exists || snapshot.value == null) {
        setState(() => _isLoading = false);
        return;
      }

      final raw = snapshot.value;
      if (raw is! Map) {
        setState(() => _isLoading = false);
        return;
      }

      final Map<dynamic, dynamic> nftsMap = Map.from(raw);
      final nftList = nftsMap.entries.map((entry) {
        final key = entry.key.toString();
        final value = Map<String, dynamic>.from(entry.value as Map);
        return NFT.fromMap(value, key);
      }).toList();

      setState(() {
        _nfts = nftList;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ---- IDENTICAL DPI / SCALE LOGIC AS ExploreContentSection ----
    final dpi = MediaQueryData.fromView(WidgetsBinding.instance.window).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.4;
    } else if (dpi >= 2.0) {
      scale = 0.9;
    } else {
      scale = 1.0;
    }

    // ---- IDENTICAL HEIGHTS AS ExploreContentSection ----
    final containerH = MediaQuery.of(context).size.height * 0.5 * scale;
    final innerH     = MediaQuery.of(context).size.height * 0.485 * scale;

    return Container(
      width: widget.width,
      height: containerH,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.width * 0.97,
          height: innerH,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Top bar: title + Explore button (same sizing/styles) ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Our NFT',
                      style: GoogleFonts.poppins(
                        fontSize: 20, // Reduced from 24 to give more space
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Changed to white
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                        backgroundColor: theme.cardColor,
                        side: BorderSide(color: Colors.purple.shade700, width: 2.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        // TODO: wire up navigation if you want this button to open a tab
                      },
                      icon: const Icon(Icons.search, color: Colors.purple, size: 20),
                      label: Text(
                        'Explore',
                        style: GoogleFonts.workSans(
                          color: theme.hintColor,
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ---- Horizontal scroller IDENTICAL to ExploreContentSection ----
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_nfts.isEmpty
                        ? const Center(child: Text('No NFTs found.'))
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: _nfts
                                    .map((nft) => Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: _NFTMiniCard(
                                            height: MediaQuery.of(context).size.height * 0.3 * scale, // match content card height
                                            nft: nft,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => NFTDetailScreen(nftId: nft.key),
                                                ),
                                              );
                                            },
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- NFT mini card that mirrors _BaseMiniCard sizing and style, but shows NFT fields ----
class _NFTMiniCard extends StatelessWidget {
  final double height;
  final NFT nft;
  final VoidCallback onTap;

  const _NFTMiniCard({
    required this.height,
    required this.nft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260, // match ExploreContentSection card width
      height: height,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // same 120px banner height as content cards
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: nft.imagePath.isNotEmpty
                  ? Image.network(
                      resolveImage(nft.imagePath),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackBanner(),
                    )
                  : _fallbackBanner(),
            ),
            const SizedBox(height: 12),

            // Category chip (mirrors the “chip” feel)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (nft.category.isNotEmpty ? nft.category : 'NFT').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Title (2 lines)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                nft.title.isEmpty ? 'Untitled' : nft.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Spacer(),

            // Creator + Price row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    radius: 9,
                    child: Icon(Icons.person, color: theme.hintColor, size: 13),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      nft.creator,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${nft.price} POL',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }
}
