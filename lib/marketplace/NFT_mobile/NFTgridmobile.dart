import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

// Helper to support ipfs:// URLs
String resolveImage(String path) {
  if (path.isEmpty) return '';
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

class NFTGridMobile extends StatefulWidget {
  final void Function(String) onNFTTap;
  const NFTGridMobile({super.key, required this.onNFTTap});

  @override
  State<NFTGridMobile> createState() => _NFTGridMobileState();
}

class _NFTGridMobileState extends State<NFTGridMobile> {
  List<NFT> _nfts = [];
  bool _isLoading = true;

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
      final nftList = nftsMap.entries
          .map((entry) => NFT.fromMap(Map<String, dynamic>.from(entry.value), entry.key as String))
          .toList();
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
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: CircularProgressIndicator(),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _nfts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.77,
        ),
        itemBuilder: (context, index) => _buildNFTCard(_nfts[index], context),
      ),
    );
  }

  Widget _buildNFTCard(NFT nft, BuildContext context) {
    return GestureDetector(
      onTap:() {
        print(nft.key);
        widget.onNFTTap(nft.key);
      },
      //     () {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (_) => NFTDetailScreen(nftId: nft.key)),
      //   );
      // },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF353535),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NFT Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: nft.imagePath.isNotEmpty
                  ? Image.network(
                resolveImage(nft.imagePath),
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 110,
                color: Colors.grey[700],
                alignment: Alignment.center,
                child: Icon(Icons.image, color: Colors.white24, size: 48),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nft.title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, size: 12, color: Colors.white70),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nft.creator,
                          style: GoogleFonts.spaceMono(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price',
                                style: GoogleFonts.spaceMono(
                                    color: Colors.white38, fontSize: 11)),
                            Text("${nft.price} ETH",
                                style: GoogleFonts.spaceMono(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Category',
                                style: GoogleFonts.spaceMono(
                                    color: Colors.white38, fontSize: 11)),
                            Text(nft.category,
                                style: GoogleFonts.spaceMono(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
