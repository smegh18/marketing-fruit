// web3_helpers_web.dart
import 'dart:convert';
import 'dart:js_util' as jsu; // ⬅️ to JS-ify ABI for ethers
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:url_launcher/url_launcher.dart';

/// --- ABI (full, unfiltered) ---
const String _contractAbiJson = '''
[
  {"inputs":[{"internalType":"string","name":"defaultUri","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},
  {"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"balance","type":"uint256"},{"internalType":"uint256","name":"needed","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ERC1155InsufficientBalance","type":"error"},
  {"inputs":[{"internalType":"address","name":"approver","type":"address"}],"name":"ERC1155InvalidApprover","type":"error"},
  {"inputs":[{"internalType":"uint256","name":"idsLength","type":"uint256"},{"internalType":"uint256","name":"valuesLength","type":"uint256"}],"name":"ERC1155InvalidArrayLength","type":"error"},
  {"inputs":[{"internalType":"address","name":"operator","type":"address"}],"name":"ERC1155InvalidOperator","type":"error"},
  {"inputs":[{"internalType":"address","name":"receiver","type":"address"}],"name":"ERC1155InvalidReceiver","type":"error"},
  {"inputs":[{"internalType":"address","name":"sender","type":"address"}],"name":"ERC1155InvalidSender","type":"error"},
  {"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"address","name":"owner","type":"address"}],"name":"ERC1155MissingApprovalForAll","type":"error"},
  {"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"OwnableInvalidOwner","type":"error"},
  {"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"OwnableUnauthorizedAccount","type":"error"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":false,"internalType":"uint256","name":"qty","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"totalPrice","type":"uint256"}],"name":"Bought","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Delisted","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":false,"internalType":"string","name":"newUri","type":"string"},{"indexed":false,"internalType":"uint256","name":"newPrice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"newValidity","type":"uint256"}],"name":"Edited","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":true,"internalType":"address","name":"creator","type":"address"},{"indexed":false,"internalType":"uint256","name":"qty","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"price","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"validity","type":"uint256"}],"name":"Minted","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"indexed":false,"internalType":"uint256[]","name":"values","type":"uint256[]"}],"name":"TransferBatch","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"TransferSingle","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"value","type":"string"},{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"URI","type":"event"},
  {"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"address[]","name":"accounts","type":"address[]"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"}],"name":"balanceOfBatch","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"quantity","type":"uint256"}],"name":"buy","outputs":[],"stateMutability":"payable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"delistNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"string","name":"newUri","type":"string"},{"internalType":"uint256","name":"newPriceWei","type":"uint256"},{"internalType":"uint256","name":"newValidity","type":"uint256"}],"name":"editNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"infoOf","outputs":[{"internalType":"address","name":"creator","type":"address"},{"internalType":"string","name":"uri","type":"string"},{"internalType":"uint256","name":"priceWei","type":"uint256"},{"internalType":"uint256","name":"validity","type":"uint256"},{"internalType":"bool","name":"isListed","type":"bool"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"string","name":"uri_","type":"string"},{"internalType":"uint256","name":"quantity","type":"uint256"},{"internalType":"uint256","name":"priceWei","type":"uint256"},{"internalType":"uint256","name":"validity","type":"uint256"}],"name":"mintNFT","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[],"name":"nextTokenId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"priceWei","type":"uint256"},{"internalType":"uint256","name":"validity","type":"uint256"}],"name":"relistNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"internalType":"uint256[]","name":"values","type":"uint256[]"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeBatchTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"uri","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}
]
''';

/// Parsed + JS-ified ABI for ethers.js (prevents "invalid fragment object")
final dynamic _jsAbi =
jsu.jsify(jsonDecode(_contractAbiJson) as List<dynamic>);

/// Buy flow for ERC-1155 `buy(uint256 tokenId, uint256 quantity)` (payable)
Future<void> handleBuyNow(
    BuildContext context,
    String tokenId,
    String priceWei,
    int maxAvailable,
    String contractAddress,
    List<dynamic> contractAbi,
    ) async {
  int selectedQty = 1;

  // Quantity dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      int tempQty = 1;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Proceed to Buy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How many editions would you like to buy?'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: tempQty > 1 ? () => setState(() => tempQty--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$tempQty',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: tempQty < maxAvailable
                        ? () => setState(() => tempQty++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                selectedQty = tempQty;
                Navigator.pop(ctx, true);
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
    },
  );

  if (confirmed != true) return;

  if (!Ethereum.isSupported) {
    await showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('MetaMask Not Found'),
        content: Text('Please install MetaMask to complete the purchase.'),
      ),
    );
    return;
  }

  try {
    // 1) Connect
    await ethereum!.requestAccount();

    // 2) Provider/Signer
    final provider = Web3Provider(ethereum!);
    final signer = provider.getSigner();

    // 3) Parse values
    final token = BigInt.tryParse(tokenId) ?? BigInt.zero;
    final unitPrice = BigInt.tryParse(priceWei) ?? BigInt.zero;
    final qty = BigInt.from(selectedQty);
    final totalValue = unitPrice * qty;

    // 4) Contract (use JS-ified ABI)
    final contract = Contract(
      contractAddress.trim(),
      _jsAbi, // <- important
      signer,
    );

    // 5) Send tx
    print(token);
    print(qty);
    print(totalValue);
    final tx = await contract.send(
      'buy',
      [token, qty],
      TransactionOverride(value: totalValue),
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: Text('Transaction submitted!\nHash: ${tx.hash}'),
      ),
    );
  } catch (e) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
      ),
    );
  }
}

/// Buy Gems using Polygon MATIC through crypto wallet (MetaMask via flutter_web3)
Future<String?> buyGemsWithCryptoWallet({
  required BuildContext context,
  required int maticAmount,
  required int gemsAmount,
  String recipientAddress = '0xb65BF8a2416EEd21C31A067F771A4Cf65059FaCE',
}) async {
  if (!Ethereum.isSupported) {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2129),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFFF59E0B)),
            SizedBox(width: 10),
            Text('MetaMask Extension Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please install the MetaMask browser extension to complete your purchase using Polygon MATIC.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14171E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Purchase Details:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gems to Receive:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('+$gemsAmount Gems', style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount to Pay:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('$maticAmount MATIC', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Network:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const Text('Polygon (137)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'simulate'),
            child: const Text('Simulate Tx (Dev Mode)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, 'install'),
            child: const Text('Install MetaMask'),
          ),
        ],
      ),
    );

    if (choice == 'install') {
      final installUrl = Uri.parse('https://metamask.io/download/');
      if (await canLaunchUrl(installUrl)) {
        await launchUrl(installUrl, mode: LaunchMode.externalApplication);
      }
      return null;
    } else if (choice == 'simulate') {
      final mockHash = '0x${List.generate(64, (i) => 'abcdef0123456789'[(DateTime.now().microsecondsSinceEpoch + i * 7) % 16]).join()}';
      return mockHash;
    }
    return null;
  }

  try {
    // 1) Connect
    await ethereum!.requestAccount();

    // 2) Provider/Signer
    final provider = Web3Provider(ethereum!);
    final signer = provider.getSigner();

    // 3) Parse values (in Wei)
    final totalWei = BigInt.from(maticAmount) * BigInt.from(10).pow(18);

    // 4) Send native transaction to recipient
    final tx = await signer.sendTransaction(
      TransactionRequest(
        to: recipientAddress.trim(),
        value: totalWei,
      ),
    );

    return tx.hash;
  } catch (e) {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E2129),
          title: const Text('Transaction Error', style: TextStyle(color: Colors.white)),
          content: Text(e.toString(), style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFFA855F7))),
            ),
          ],
        ),
      );
    }
    return null;
  }
}
