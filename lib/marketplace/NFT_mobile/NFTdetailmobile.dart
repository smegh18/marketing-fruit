import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:Marketing_Fruit/screens/dashboard/web3_helpers_stub.dart';


const String contractAddress = ' 0xF1Ef28A571d62af56ea37956aA8a6FBBAA95ed55';
final List<dynamic> contractAbi = <dynamic>[
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "defaultUri",
        "type": "string"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "sender",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "balance",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "needed",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "ERC1155InsufficientBalance",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "approver",
        "type": "address"
      }
    ],
    "name": "ERC1155InvalidApprover",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "idsLength",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "valuesLength",
        "type": "uint256"
      }
    ],
    "name": "ERC1155InvalidArrayLength",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "operator",
        "type": "address"
      }
    ],
    "name": "ERC1155InvalidOperator",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "receiver",
        "type": "address"
      }
    ],
    "name": "ERC1155InvalidReceiver",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "sender",
        "type": "address"
      }
    ],
    "name": "ERC1155InvalidSender",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      }
    ],
    "name": "ERC1155MissingApprovalForAll",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      }
    ],
    "name": "OwnableInvalidOwner",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "OwnableUnauthorizedAccount",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "bool",
        "name": "approved",
        "type": "bool"
      }
    ],
    "name": "ApprovalForAll",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "buyer",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "qty",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "totalPrice",
        "type": "uint256"
      }
    ],
    "name": "Bought",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "Delisted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "newUri",
        "type": "string"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "newPrice",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "newValidity",
        "type": "uint256"
      }
    ],
    "name": "Edited",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "creator",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "qty",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "price",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "validity",
        "type": "uint256"
      }
    ],
    "name": "Minted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "previousOwner",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "ids",
        "type": "uint256[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "values",
        "type": "uint256[]"
      }
    ],
    "name": "TransferBatch",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      }
    ],
    "name": "TransferSingle",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "string",
        "name": "value",
        "type": "string"
      },
      {
        "indexed": true,
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      }
    ],
    "name": "URI",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      }
    ],
    "name": "balanceOf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "accounts",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "ids",
        "type": "uint256[]"
      }
    ],
    "name": "balanceOfBatch",
    "outputs": [
      {
        "internalType": "uint256[]",
        "name": "",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "quantity",
        "type": "uint256"
      }
    ],
    "name": "buy",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "delistNFT",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "newUri",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "newPriceWei",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "newValidity",
        "type": "uint256"
      }
    ],
    "name": "editNFT",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "infoOf",
    "outputs": [
      {
        "internalType": "address",
        "name": "creator",
        "type": "address"
      },
      {
        "internalType": "string",
        "name": "uri",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "priceWei",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "validity",
        "type": "uint256"
      },
      {
        "internalType": "bool",
        "name": "isListed",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "operator",
        "type": "address"
      }
    ],
    "name": "isApprovedForAll",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "uri_",
        "type": "string"
      },
      {
        "internalType": "uint256",
        "name": "quantity",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "priceWei",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "validity",
        "type": "uint256"
      }
    ],
    "name": "mintNFT",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "nextTokenId",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "priceWei",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "validity",
        "type": "uint256"
      }
    ],
    "name": "relistNFT",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "renounceOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256[]",
        "name": "ids",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "values",
        "type": "uint256[]"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "safeBatchTransferFrom",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "value",
        "type": "uint256"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "safeTransferFrom",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "operator",
        "type": "address"
      },
      {
        "internalType": "bool",
        "name": "approved",
        "type": "bool"
      }
    ],
    "name": "setApprovalForAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes4",
        "name": "interfaceId",
        "type": "bytes4"
      }
    ],
    "name": "supportsInterface",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "transferOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "uri",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
];

class NFTDetailMobileScreen extends StatefulWidget {
  final String nftId;
  final String? adminWallet;
  final VoidCallback? onClose;
  final void Function(String txnHash)? onTxnTap;

  const NFTDetailMobileScreen({
    super.key,
    required this.nftId,
    this.adminWallet = '0xb65BF8a2416EEd21C31A067F771A4Cf65059FaCE',
    this.onClose,
    this.onTxnTap,
  });

  @override
  State<NFTDetailMobileScreen> createState() => _NFTDetailMobileScreenState();
}

class _NFTDetailMobileScreenState extends State<NFTDetailMobileScreen> {
  Map<String, dynamic>? nft;
  bool isLoading = true;
  Map<String, dynamic>? matchedEtherscanTxn;
  bool etherscanTxnLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNft();
  }

  Future<void> fetchNft() async {
    final dbRef = FirebaseDatabase.instance.ref('nft/${widget.nftId}');
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final nftMap = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        nft = nftMap;
        isLoading = false;
      });
      final nftHash = nftMap['hash'] ?? nftMap['txHash'] ?? nftMap['transactionHash'];
      if (nftHash != null) {
        fetchEtherscanTxnDetailsIfPresent(nftHash);
      }
    } else {
      setState(() {
        nft = null;
        isLoading = false;
      });
    }
  }

  Future<void> fetchEtherscanTxnDetailsIfPresent(String hash) async {
    setState(() {
      etherscanTxnLoading = true;
    });
    final match = await fetchEtherscanTxnByHash(hash);
    setState(() {
      matchedEtherscanTxn = match;
      etherscanTxnLoading = false;
    });
  }

  static const etherscanApiKey = 'T6KZZ5BM5XYCCMJGQ32X3II4KZEA7TV5EZ';
  static const adminWallet = '0xb65BF8a2416EEd21C31A067F771A4Cf65059FaCE';
  static const etherscanApiBase = 'https://api.etherscan.io/v2/api';
  static const etherscanChainId = 137;

  Future<Map<String, dynamic>?> fetchEtherscanTxnByHash(String hash) async {
    final url = '$etherscanApiBase'
        '?chainid=$etherscanChainId'
        '&module=account'
        '&action=tokennfttx'
        '&address=$adminWallet'
        '&page=1'
        '&offset=100'
        '&sort=desc'
        '&apikey=$etherscanApiKey';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    final body = json.decode(resp.body);
    if (body['status'] != '1') return null;
    final List txns = body['result'];
    final match = txns.cast<Map<String, dynamic>>().where(
            (tx) => (tx['hash'] ?? '').toString().toLowerCase() == hash.toLowerCase());
    return match.isNotEmpty ? match.first : null;
  }

  String convertIpfs(String? input) {
    if (input == null) return '';
    if (input.startsWith('ipfs://')) {
      return 'https://gateway.pinata.cloud/ipfs/${input.substring(7)}';
    }
    return input;
  }

  String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "-";
    try {
      var date = DateTime.parse(isoString.split('.').first);
      return "${_monthName(date.month)} ${date.day}, ${date.year}";
    } catch (_) {
      return isoString;
    }
  }

  String _monthName(int m) => [
    "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"
  ][m - 1];

  String _formatEtherscanTimestamp(dynamic ts) {
    if (ts == null || ts.toString().isEmpty) return "-";
    final intVal = int.tryParse(ts.toString());
    if (intVal == null) return "-";
    final dt = DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (nft == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        body: const Center(child: Text("NFT not found!", style: TextStyle(color: Colors.white))),
      );
    }

    final detailsWidth = media.size.width * 0.92;

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFF232323),
      //   elevation: 0,
      //   title: Row(
      //     children: [
      //       Icon(Icons.shopping_bag, color: Colors.purpleAccent),
      //       const SizedBox(width: 4),
      //       Text(
      //         "NFT Marketplace",
      //         style: GoogleFonts.poppins(
      //             color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
      //       ),
      //     ],
      //   ),
      //   actions: [
      //     IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {}),
      //   ],
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NFT main image
              Container(
                margin: const EdgeInsets.all(16),
                height: media.size.width * 0.6,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey[800]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: nft!["graphic"] != null && nft!["graphic"].toString().isNotEmpty
                      ? Image.network(convertIpfs(nft!["graphic"]), fit: BoxFit.cover)
                      : const Icon(Icons.image_outlined, color: Colors.white12, size: 60),
                ),
              ),
              // Name and date
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nft!["name"] ?? "-", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      "Minted On ${formatDate(nft?["timestamp"])}",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              // Basic Info Table
              _infoTableMobile(detailsWidth),
              // Description section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Description", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 7),
                    Text(
                      nft?["description"] ?? "-",
                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
              // Benefits section
              if (nft?["benefit"] != null)
                _benefitsSectionMobile(detailsWidth),
              // Details
              _detailsSectionMobile(detailsWidth),
              // Buy/Owner section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF353535),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy Now',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Price: ${nft?["price"] ?? "-"} POL",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA259FF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: () async {
                             await handleBuyNow(context,
                                nft?["tokenId"]?.toString() ?? '0',
                                nft?["price"]?.toString() ?? '0',
                                nft?["quantity"] ?? 1,
                                contractAddress,contractAbi);
                          },
                          child: const Text("Buy Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Created by
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey[700],
                      child: const Icon(Icons.account_circle, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nft?["owner"] ?? "Marketing Fruit",
                      style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15),
                    )
                  ],
                ),
              ),
              // Tags
              if (nft?["category"] != null || nft?["type"] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (nft?["category"] != null)
                        _tagChipMobile(nft!["category"].toString()),
                      if (nft?["type"] != null)
                        _tagChipMobile(nft!["type"].toString()),
                    ],
                  ),
                ),
              // Activity
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Transaction Activity", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 8),
                    _txnActivityMobile(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTableMobile(double width) {
    final cellStyle = GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.38);
    final headerStyle = cellStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white);

    Widget divider = Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 20,
      width: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF353535),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _cellMobile("Min Price", nft?["minPrice24h"]?.toString() ?? "N/A", headerStyle, cellStyle),
            divider,
            _cellMobile("Last Sale", nft?["lastSaleItem"]?.toString() ?? "N/A", headerStyle, cellStyle),
            divider,
            _cellMobile("Contract Sale", nft?["lastSaleContract"]?.toString() ?? "N/A", headerStyle, cellStyle),
          ],
        ),
      ),
    );
  }

  Widget _cellMobile(String title, String value, TextStyle h, TextStyle v) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: h, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value, style: v, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _benefitsSectionMobile(double width) {
    final titleStyle = GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15);
    final valueStyle = GoogleFonts.poppins(color: Colors.white70, fontSize: 13);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF353535),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Benefits", style: titleStyle),
            const SizedBox(height: 10),
            Divider(),
            Row(
              children: [
                Text("Benefit: ", style: titleStyle.copyWith(fontWeight: FontWeight.w500)),
                Expanded(child: Text(nft?["benefit"].toString() ?? "", style: valueStyle)),
              ],
            ),
            if (nft?["value"] != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text("Value: ", style: titleStyle.copyWith(fontWeight: FontWeight.w500)),
                  Expanded(child: Text(nft!["value"].toString(), style: valueStyle)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _detailsSectionMobile(double width) {
    final excludeKeys = [
      "graphic", "name", "timestamp", "owner", "description", "quantity", "price",
      "metadata", "minPrice24h", "lastSaleItem", "lastSaleContract", "benefits", "value"
    ];
    final titleStyle = GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15);
    final valueStyle = GoogleFonts.poppins(color: Colors.white70, fontSize: 13);
    final filtered = nft!.entries.where((e) =>
    !excludeKeys.contains(e.key) && !e.key.toLowerCase().startsWith('benefit_')).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF353535),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Details", style: titleStyle),
            const SizedBox(height: 6),
            Divider(),
            ...filtered.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key.toString().replaceFirst(entry.key.toString().substring(0, 1),
                      entry.key.toString().substring(0, 1).toUpperCase()), style: valueStyle.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(entry.value.toString(), style: valueStyle, textAlign: TextAlign.right)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _tagChipMobile(String tag) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF434343),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(tag, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
  );

  Widget _txnActivityMobile() {
    if (etherscanTxnLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (matchedEtherscanTxn == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No Item Activity", style: TextStyle(color: Colors.white60)),
      );
    }
    final tx = matchedEtherscanTxn!;
    String trim(String s) => s.length > 12 ? '${s.substring(0, 7)}...${s.substring(s.length-4)}' : s;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF353535),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txnRowMobile("Txn Hash", trim(tx['hash'] ?? '-')),
          const Divider(height: 8),
          _txnRowMobile("Type", (tx['from']?.toString().toLowerCase() ==
              '0x0000000000000000000000000000000000000000') ? "Mint" : "Transfer"),
          _txnRowMobile("Block", tx['blockNumber']?.toString() ?? '-'),
          _txnRowMobile("From", trim(tx['from'] ?? '-')),
          _txnRowMobile("To", trim(tx['to'] ?? '-')),
          _txnRowMobile("Token", tx['tokenName'] ?? '-'),
          _txnRowMobile("TokenId", tx['tokenID'] ?? '-'),
          _txnRowMobile("Time", _formatEtherscanTimestamp(tx['timeStamp'])),
        ],
      ),
    );
  }

  Widget _txnRowMobile(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13), textAlign: TextAlign.right)),
      ],
    ),
  );
}
