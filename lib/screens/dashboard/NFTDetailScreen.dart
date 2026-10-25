import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'web3_helpers_stub.dart'
if (dart.library.html) 'web3_helpers_web.dart';

// Provide your contract address and ABI below
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
class NFTDetailScreen extends StatefulWidget {
  final String nftId;
  final String? adminWallet;
  final VoidCallback? onClose;
  final void Function(String txnHash)? onTxnTap;

  const NFTDetailScreen({
    super.key,
    required this.nftId,
    this.adminWallet = '0xb65BF8a2416EEd21C31A067F771A4Cf65059FaCE',
    this.onClose,
    this.onTxnTap,
  });

  @override
  State<NFTDetailScreen> createState() => _NFTDetailScreenState();
}

class _NFTDetailScreenState extends State<NFTDetailScreen> {
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
  static const etherscanChainId = 137; // Polygon

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
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ][m - 1];

  Widget _infoTable(double width, double scale) {
    final cellStyle = GoogleFonts.poppins(fontSize: 16 * scale, color: Theme.of(context).hintColor);
    final headerStyle = cellStyle.copyWith(fontWeight: FontWeight.bold);

    Widget divider = Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 42,
      width: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _tableCellWithTooltip(
            "Min Price (24h)",
            "The lowest sale price for this NFT in the past 24 hours.",
            nft?["minPrice24h"]?.toString() ?? "N/A",
            cellStyle,
            headerStyle,
          ),
          divider,
          _tableCellWithTooltip(
            "Last Sale (Item)",
            "The last sale price of this specific NFT.",
            nft?["lastSaleItem"]?.toString() ?? "N/A",
            cellStyle,
            headerStyle,
          ),
          divider,
          _tableCellWithTooltip(
            "Last Sale (Contract)",
            "The latest sale price for any NFT in this contract.",
            nft?["lastSaleContract"]?.toString() ?? "N/A",
            cellStyle,
            headerStyle,
          ),
        ],
      ),
    );
  }

  Widget _tableCellWithTooltip(String title, String tooltip, String value, TextStyle cellStyle, TextStyle headerStyle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: headerStyle),
              const SizedBox(width: 4),
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.help_outline, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(value, style: cellStyle),
        ],
      ),
    );
  }

  /// Benefits section logic - change as per your actual data
  /// Supports NFT map key `benefits: {benefit1: value, ...}`
  /// or keys starting with 'benefit_'.
  Widget _benefitsSection(double width, double scale) {
    final theme = Theme.of(context);
    final titleStyle = GoogleFonts.poppins(
        fontSize: 18 * scale, fontWeight: FontWeight.bold, color: theme.hintColor);
    final valueStyle = GoogleFonts.poppins(
        fontSize: 16 * scale, color: theme.hintColor);

    final benefitKey = "benefit"; // or whatever your key name is
    final benefitValue = nft?[benefitKey];

    final benefitAmtKey = "value"; // or whatever your key name is
    final benefitAmtValue = nft?[benefitAmtKey];

    if (benefitValue == null) return SizedBox.shrink();

    return Container(
      width: width,
      margin: const EdgeInsets.only(top: 24, bottom: 2),
      // decoration: BoxDecoration(
      //   color: Theme.of(context).cardColor,
      //   borderRadius: BorderRadius.circular(16),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.5),
      //       spreadRadius: 2,
      //       blurRadius: 5,
      //     ),
      //   ],
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18, left: 20, bottom: 6),
            child: Text("Benefits", style: titleStyle),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(thickness: 1, height: 2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text("Benefit", style: titleStyle.copyWith(fontSize: 16 * scale, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(benefitValue.toString(), style: valueStyle),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(thickness: 1, height: 2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text("Value", style: titleStyle.copyWith(fontSize: 16 * scale, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 3,
                  child: Text("$benefitAmtValue %", style: valueStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Details section with divider after heading and after each entry
  Widget _detailsSection(double width, double scale) {
    final theme = Theme.of(context);
    final titleStyle = GoogleFonts.poppins(
        fontSize: 18 * scale, fontWeight: FontWeight.bold, color: theme.hintColor);
    final valueStyle = GoogleFonts.poppins(
        fontSize: 16 * scale, color: theme.hintColor);

    var excludeKeys = [
      "graphic",
      "name",
      "timestamp",
      "owner",
      "description",
      "quantity",
      "price",
      "metadata",
      "minPrice24h",
      "lastSaleItem",
      "lastSaleContract",
      "benefits",
      "value"
    ];

    final filteredEntries = nft!.entries
        .where((e) => !excludeKeys.contains(e.key) && !e.key.toLowerCase().startsWith('benefit_'))
        .toList();

    return Container(
      width: width,
      margin: const EdgeInsets.only(top: 18, bottom: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18, left: 20, bottom: 6),
            child: Text("Details", style: titleStyle),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(thickness: 1, height: 2),
          ),
          ...filteredEntries.mapIndexed((i, entry) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 26, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: width * 0.35,
                      child: Text(
                        entry.key.toString().replaceFirst(entry.key.toString().substring(0, 1),
                            entry.key.toString().substring(0, 1).toUpperCase()),
                        style: titleStyle.copyWith(fontSize: 16 * scale, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != filteredEntries.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: Divider(height: 2, thickness: 1),
                ),
            ],
          )),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16),
            child: Divider(height: 2, thickness: 1),
          ),
          _benefitsSection(width, scale)
        ],
      ),
    );
  }

  // Transaction activity table revised:
  Widget _itemActivityTable() {
    final TextStyle cellStyle =
    GoogleFonts.poppins(fontSize: 15, color: Theme.of(context).hintColor);
    final TextStyle headingStyle = GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).hintColor);

    String trimHash(String hash, {int leading = 8, int trailing = 6}) {
      if (hash.length <= leading + trailing) return hash;
      return "${hash.substring(0, leading)}...${hash.substring(hash.length - trailing)}";
    }

    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding( // Always show heading
            padding: const EdgeInsets.only(top: 22, left: 26, bottom: 10),
            child: Text("Transaction Activity", style: headingStyle),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 2, thickness: 1),
          ),
          if (etherscanTxnLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (matchedEtherscanTxn == null)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: Text("No Item Activity")),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1300),
                child: DataTable(
                  columnSpacing: 32,
                  columns: const [
                    DataColumn(label: Text('Txn Hash')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Block')),
                    DataColumn(label: Text('From')),
                    DataColumn(label: Text('To')),
                    DataColumn(label: Text('Token')),
                    DataColumn(label: Text('TokenId')),
                    DataColumn(label: Text('Time')),
                  ],
                  rows: [
                    DataRow(cells: [
                      DataCell(
                        InkWell(
                          onTap: () => widget.onTxnTap?.call(matchedEtherscanTxn!['hash']),
                          child: Tooltip(
                            message: matchedEtherscanTxn!['hash'] ?? '-',
                            child: SizedBox(
                              width: 110,
                              child: Text(
                                trimHash(matchedEtherscanTxn!['hash'] ?? '-'),
                                style: cellStyle.copyWith(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(
                        (matchedEtherscanTxn!['from']?.toString().toLowerCase() ==
                            '0x0000000000000000000000000000000000000000')
                            ? "Mint"
                            : "Transfer",
                        style: cellStyle,
                      )),
                      DataCell(Text(matchedEtherscanTxn!['blockNumber']?.toString() ?? '-', style: cellStyle)),
                      DataCell(
                        Tooltip(
                          message: matchedEtherscanTxn!['from'] ?? '-',
                          child: SizedBox(
                            width: 110,
                            child: Text(
                              trimHash(matchedEtherscanTxn!['from'] ?? '-'),
                              style: cellStyle.copyWith(fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Tooltip(
                          message: matchedEtherscanTxn!['to'] ?? '-',
                          child: SizedBox(
                            width: 110,
                            child: Text(
                              trimHash(matchedEtherscanTxn!['to'] ?? '-'),
                              style: cellStyle.copyWith(fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(matchedEtherscanTxn!['tokenName'] ?? '-', style: cellStyle)),
                      DataCell(Text(matchedEtherscanTxn!['tokenID']?.toString() ?? '-', style: cellStyle)),
                      DataCell(Text(_formatEtherscanTimestamp(matchedEtherscanTxn!['timeStamp']), style: cellStyle)),
                    ])
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

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
    final pixelRatio = media.devicePixelRatio;
    const baselinePixelRatio = 1.0;
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    final theme = Theme.of(context);

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;

    if (pixelRatio < 2.0) {
      double ratio = baselinePixelRatio / pixelRatio;
      if ((pixelRatio - 1.0).abs() < 0.3) {
        scaleFactor = ratio * 1.05;
        sfg = ratio * 1.1;
      } else {
        scaleFactor = ratio * 1.1;
        sfg = ratio * 1.4;
      }
    }
    if (isMacOS) scaleFactor = sfg = 0.8;

    final detailsWidth = media.size.width * 0.6 * sfg;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: isLoading
          ? const Center(
          child: Padding(
            padding: EdgeInsets.all(80),
            child: CircularProgressIndicator(),
          ))
          : nft == null
          ? Center(child: Text('NFT not found', style: TextStyle(color: theme.hintColor)))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: media.size.height * 0.35 * sfg,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: const Color(0xFF353535),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  convertIpfs(nft!["graphic"] ?? ""),
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.red, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: media.size.width * 0.065 * scaleFactor),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NAME
                        Text(
                          nft!["name"] ?? "-",
                          style: GoogleFonts.poppins(
                            fontSize: 32 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Minted On ${formatDate(nft?["timestamp"])}",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scaleFactor,
                            color: const Color.fromRGBO(65, 105, 225, 1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Created By",
                          style: GoogleFonts.poppins(
                            fontSize: 22 * scaleFactor,
                            color: theme.hintColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14 * scaleFactor,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.account_circle_outlined,
                                  color: theme.hintColor, size: 18 * scaleFactor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              nft?["owner"] ?? "Marketing Fruit",
                              style: GoogleFonts.poppins(
                                fontSize: 19 * scaleFactor,
                                color: theme.hintColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // --- Description (with divider after heading)
                        const SizedBox(height: 32),
                        Container(
                          width: detailsWidth,
                          padding: const EdgeInsets.only(left: 15),
                          margin: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 18, left: 20, bottom: 6),
                                  child: Text(
                                    "Description",
                                    style: GoogleFonts.poppins(
                                      fontSize: 22 * scaleFactor,
                                      color: theme.hintColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  )),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(thickness: 1, height: 2),
                              ),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Text(
                                    nft?["description"] ?? "-",
                                    style: GoogleFonts.poppins(
                                      color: theme.hintColor,
                                      height: 1.6,
                                      fontSize: 22 * scaleFactor,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        // info Table
                        _infoTable(detailsWidth, scaleFactor),
                        // DETAILS section (divider after heading and all entries)
                        _detailsSection(detailsWidth, scaleFactor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // SECONDARY COLUMN (image, buy, chat)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            width: media.size.width * 0.4 * sfg,
                            height: media.size.height * 0.25 * sfg,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: theme.cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: NFTImageWithPopup(
                              imageUrl: convertIpfs(nft!["graphic"] ?? ""),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: media.size.width * 0.4 * sfg,
                          padding: EdgeInsets.symmetric(
                            vertical: 24 * scaleFactor,
                            horizontal: 20 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make it yours:',
                                style: GoogleFonts.poppins(
                                  color: theme.hintColor,
                                  fontSize: 22 * scaleFactor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                (nft?["price"]?.toString() ?? "-"),
                                style: GoogleFonts.poppins(
                                  fontSize: 32 * scaleFactor,
                                  fontWeight: FontWeight.w600,
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'POL',
                                style: GoogleFonts.poppins(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.w600,
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => handleBuyNow(
                                    context,
                                    nft?["tokenId"]?.toString() ?? '0',
                                    nft?["price"]?.toString() ?? '0',
                                    nft?["quantity"] ?? 1,
                                    contractAddress,
                                    contractAbi,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFFB75CFF),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    (nft?["owner"] != null &&
                                        widget.adminWallet != null &&
                                        nft?["owner"] == widget.adminWallet)
                                        ? 'Re-Mint'
                                        : 'Buy Now',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16 * scaleFactor,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.chat_bubble_outline,
                                      color: theme.hintColor),
                                  label: Text(
                                    'Chat with Owner',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15 * scaleFactor,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Colors.deepPurple.withOpacity(0.15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Chat logic here
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: media.size.width * 0.065 * scaleFactor),
              child: _itemActivityTable(),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper: .mapIndexed extension
extension _MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int, E) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}

class NFTImageWithPopup extends StatelessWidget {
  final String imageUrl;
  const NFTImageWithPopup({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.red),
                ),
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.red),
        ),
      ),
    );
  }
}
