import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

import 'subscribe_widget.dart';
import 'nft_grid.dart'; // This is the NFTGrid you've created!

class NftDetailPage extends StatefulWidget {
  final String nftKey;
  const NftDetailPage({super.key, required this.nftKey});

  @override
  State<NftDetailPage> createState() => _NftDetailPageState();
}

class _NftDetailPageState extends State<NftDetailPage> {
  Map<dynamic, dynamic>? nftData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNft();
  }

  Future<void> fetchNft() async {
    final ref = FirebaseDatabase.instance.ref("nft/${widget.nftKey}");
    final snap = await ref.get();
    if (snap.exists) {
      setState(() {
        nftData = snap.value as Map<dynamic, dynamic>;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String resolveImage(String? path) {
    if (path == null) return '';
    if (path.startsWith('ipfs://')) {
      final ipfsHash = path.substring(7);
      return 'https://gateway.pinata.cloud/ipfs/$ipfsHash';
    }
    return path;
  }

  String _formatEtherscanTimestamp(dynamic ts) {
    if (ts == null || ts.toString().isEmpty) return "-";
    try {
      if (ts is int) {
        // Assume Unix timestamp (seconds)
        final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
      } else if (ts is String) {
        // Try parse as int first
        final intVal = int.tryParse(ts);
        if (intVal != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
          return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
        } else {
          // Try parse as ISO date string
          final dt = DateTime.tryParse(ts);
          if (dt != null) {
            return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
          }
        }
      }
    } catch (e) {
      // Fall through to '-'
    }
    return "-";
  }


  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0){
      if (pixelRatio > baselinePixelRatio) {
        double ratio = baselinePixelRatio / pixelRatio;
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.05; sfg = ratio * 1.1; sfgg = ratio * 1.1;
        } else {
          scaleFactor = ratio * 1.1; sfg = ratio * 1.4; sfgg = ratio * 1.82;
        }
      }
    } else {
      sfgg = 0.65;
    }
    if (isMacOS) {
      scaleFactor = 0.8;
      sfg = 0.8;
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (nftData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        body: Center(child: Text("NFT not found!", style: TextStyle(color: Colors.white))),
      );
    }

    final title = nftData?['name'] ?? 'Untitled';
    final creator = nftData?['type'] ?? 'Unknown';
    final price = nftData?['price']?.toString() ?? '0';
    final description = nftData?['description'] ?? '';
    final created = nftData?['timestamp'] != null
        ? _formatEtherscanTimestamp(nftData?['timestamp'])
        : null;
    final imagePath = nftData?['graphic'] ?? '';
    final creatorAvatar = 'assets/Assets/fox.png'; // fallback; use actual path if in DB

    String mintedDateStr = created != null
        ? created.toString()
        : "Unknown";
    print(nftData?['timestamp']);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF2B2B2B),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Banner
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.30 * sfg,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: imagePath.isNotEmpty
                        ? Image.network(resolveImage(imagePath), fit: BoxFit.cover)
                        : Container(color: Colors.grey[700]),
                  ),
                  // NFT Details Section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.065 * scaleFactor,
                      vertical: MediaQuery.of(context).size.height * 0.1 * scaleFactor,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel (NFT details)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 28 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Minted On $mintedDateStr',
                                style: GoogleFonts.poppins(
                                  fontSize: 14 * scaleFactor,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Created By',
                                style: GoogleFonts.poppins(
                                  fontSize: 22 * scaleFactor,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14 * scaleFactor,
                                    backgroundImage: AssetImage(creatorAvatar),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Marketing Fruit",
                                    style: GoogleFonts.poppins(
                                      fontSize: 22 * scaleFactor,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Description',
                                style: GoogleFonts.poppins(
                                  fontSize: 22 * scaleFactor,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                description,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  height: 1.6,
                                  fontSize: 22 * scaleFactor,
                                ),
                              ),
                              SizedBox(height: 32 * scaleFactor),
                              Text(
                                'Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 22 * scaleFactor,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (nftData?['tokenHash'] != null)
                                Row(
                                  children: [
                                    Icon(Icons.language, color: Colors.white60, size: 30 * scaleFactor),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        // Provide actual etherscan URL if you have it
                                      },
                                      child: Text('View on Etherscan', style: GoogleFonts.poppins(fontSize: 22 * scaleFactor, color: Colors.white)),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              if (nftData?['graphic'] != null)
                                Row(
                                  children: [
                                    Icon(Icons.language, color: Colors.white60, size: 30 * scaleFactor),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding: const EdgeInsets.all(16),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: InteractiveViewer(
                                                child: Image.network(
                                                  resolveImage(imagePath),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text('View Original', style: GoogleFonts.poppins(fontSize: 22 * scaleFactor, color: Colors.white)),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 32),
                              Text(
                                'Tags',
                                style: GoogleFonts.poppins(
                                  fontSize: 22 * scaleFactor,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10 * scaleFactor,
                                runSpacing: 10 * scaleFactor,
                                children: [
                                  if (nftData?['category'] != null)
                                    buildTag(nftData!['category'].toString()),
                                  if (nftData?['type'] != null)
                                    buildTag(nftData!['type'].toString()),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'More From The Artist or Brands',
                                        style: GoogleFonts.poppins(
                                          fontSize: 28 * scaleFactor,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 40),

                        // Right Purchase Card
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.4 * sfg,
                                padding: EdgeInsets.symmetric(
                                    vertical: 24 * scaleFactor,
                                    horizontal: 20 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Make it yours:',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: 22 * scaleFactor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      price,
                                      style: GoogleFonts.poppins(
                                        fontSize: 32 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ETH',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Handle buy
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFB75CFF),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            )),
                                        child: Text(
                                          'Buy Now',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16 * scaleFactor,
                                              color: Colors.white),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ------------------ NFT Grid Section! ---------------------
                  // Adaptive height: grid will size as per number of items available.
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06 * scaleFactor),
                    child: NFTGrid(),
                  ),
                  const SizedBox(height: 20),

                  // Subscribe Widget
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06 * scaleFactor),
                    child: SubscribeWidget(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B3B3B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

