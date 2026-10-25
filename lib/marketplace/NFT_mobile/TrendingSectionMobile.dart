import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class TrendingSectionMobile extends StatefulWidget {
  const TrendingSectionMobile({super.key});

  @override
  State<TrendingSectionMobile> createState() => _TrendingSectionMobileState();
}

class _TrendingSectionMobileState extends State<TrendingSectionMobile> {
  Map? randomNft;

  @override
  void initState() {
    super.initState();
    fetchRandomNft();
  }

  Future<void> fetchRandomNft() async {
    final dbRef = FirebaseDatabase.instance.ref().child('nft');
    DataSnapshot snapshot = await dbRef.get();
    if (snapshot.value != null && snapshot.value is Map) {
      final nfts = (snapshot.value as Map).values.toList();
      if (nfts.isNotEmpty) {
        final rand = Random();
        final randomIndex = rand.nextInt(nfts.length);
        setState(() {
          randomNft = nfts[randomIndex] as Map;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: randomNft == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Collection',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Checkout our weekly updated trending collection.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 22),
          // Main NFT Card
          Center(
            child: Container(
              width: width * 0.85,
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Main image (use NetworkImage for IPFS http gateway)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20)),
                    child: Image.network(
                      _ipfsUrl(randomNft!['graphic']),
                      height: width * 0.6,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (a, b, c) => Container(
                          height: width * 0.6,
                          color: Colors.black12,
                          child: Icon(Icons.broken_image, size: 48)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Sub items and counter row (use the same image)
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  //   child: Row(
                  //     children: [
                  //       _MiniImage(_ipfsUrl(randomNft!['graphic'])),
                  //       const SizedBox(width: 8),
                  //       _MiniImage(_ipfsUrl(randomNft!['graphic'])),
                  //       const SizedBox(width: 8),
                  //       Container(
                  //         width: 56,
                  //         height: 40,
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFFA259FF),
                  //           borderRadius: BorderRadius.circular(12),
                  //         ),
                  //         child: Center(
                  //           child: Text(
                  //             '${randomNft!['quantity'] ?? '1'}+',
                  //             style: GoogleFonts.spaceGrotesk(
                  //               fontWeight: FontWeight.bold,
                  //               fontSize: 15,
                  //               color: Colors.white,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      randomNft!['name'] ?? 'NFT',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      randomNft!['description'] ?? 'NFT',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Creator row: Show category as creator if available
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.amber,
                          child: Text(
                            ((randomNft!['type'] ?? 'C') as String)
                                .substring(0, 1),
                            style: TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          randomNft!['type'] ?? 'Marketing Fruit',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple IPFS to http gateway
  static String _ipfsUrl(String? ipfs) {
    if (ipfs == null) return '';
    return ipfs.startsWith('ipfs://')
        ? 'https://gateway.pinata.cloud/ipfs/${ipfs.substring(7)}'
        : ipfs;
  }
}

class _MiniImage extends StatelessWidget {
  final String url;

  const _MiniImage(this.url);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (a, b, c) =>
            Container(width: 40, height: 40, color: Colors.black12),
      ),
    );
  }
}
