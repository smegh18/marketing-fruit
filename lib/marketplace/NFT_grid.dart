import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/screens/dashboard/NFTDetailScreen.dart';

// Make sure this matches your actual file name for the detail page

// Utility to support ipfs:// URLs
String resolveImage(String path) {
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

class NFTGrid extends StatefulWidget {
  const NFTGrid({super.key});

  @override
  _NFTGridState createState() => _NFTGridState();
}

class _NFTGridState extends State<NFTGrid> {
  List<NFT> _nfts = [];
  bool _isLoading = true;
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    fetchNFTs();
  }

  Future<void> fetchNFTs() async {
    setState(() => _isLoading = true);
    final ref = FirebaseDatabase.instance.ref("nft");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> nftsMap = Map.from(snapshot.value as Map);
      final nftList = nftsMap.entries.map((entry) => NFT.fromMap(Map<String, dynamic>.from(entry.value), entry.key as String)).toList();
      setState(() {
        _nfts = nftList;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgc = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0) {
      if (pixelRatio > baselinePixelRatio) {
        double ratio = baselinePixelRatio / pixelRatio;
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.05;
          sfg = ratio * 0.9;
          sfgc = ratio * 1.5;
        } else {
          scaleFactor = ratio * 1.1;
          sfg = ratio * 1.6;
          sfgc = ratio * 1.83;
        }
      }
    } else {
      scaleFactor = 1.0;
      sfg = 1.0;
      sfgc = 0.65;
    }
    double cardHeight = MediaQuery.of(context).size.height * 0.355 * sfgc;
    double gridSpacing = 50 * sfgc;
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = (screenWidth - 2 * screenWidth * 0.05 - 2 * gridSpacing) / 4;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      child: Wrap(
        spacing: gridSpacing,
        runSpacing: gridSpacing * scaleFactor,
        children: _nfts.map((nft) {
          return SizedBox(
            width: itemWidth * 0.9 * sfg,
            child: buildNFTCard(
              nft,
              cardHeight,
              itemWidth * 0.9 * sfg,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildNFTCard(
      NFT nft,
      double cardHeight,
      double cardWidth,
      ) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0) {
      if (pixelRatio > baselinePixelRatio) {
        double ratio = baselinePixelRatio / pixelRatio;
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.05;
          sfg = ratio * 0.9;
        } else {
          scaleFactor = ratio * 1.3;
          sfg = ratio * 1.4;
        }
      }
    } else {
      scaleFactor = 0.5;
    }
    final imageHeight = cardHeight * 0.55;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return MouseRegion(
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NFTDetailScreen(nftId: nft.key),
                ),
              );
            },
            child: AnimatedScale(
              scale: isHovered ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                height: cardHeight,
                width: cardWidth,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: cardWidth,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: nft.imagePath.isNotEmpty
                            ? Image.network(resolveImage(nft.imagePath), fit: BoxFit.cover)
                            : Container(color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18 * scaleFactor, vertical: 8 * scaleFactor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nft.title,
                              style: GoogleFonts.workSans(
                                  fontSize: 22 * scaleFactor,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10 * scaleFactor,
                                  backgroundColor: Colors.grey[700],
                                  child: Icon(Icons.person, color: Colors.white, size: 14),
                                  // You can use a custom Avatar if you add that info to your db
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nft.creator,
                                    style: GoogleFonts.spaceMono(
                                        color: Colors.white70,
                                        fontSize: 16 * scaleFactor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Price',
                                        style: GoogleFonts.spaceMono(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text("${nft.price} ETH",
                                        style: GoogleFonts.spaceMono(
                                            fontSize: 16,
                                            color: Colors.white)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Category',
                                        style: GoogleFonts.spaceMono(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text(nft.category,
                                        style: GoogleFonts.spaceMono(
                                            fontSize: 16,
                                            color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
