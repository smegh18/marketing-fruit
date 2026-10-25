import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

// --- ABI-encode buy(uint256,uint256) for MetaMask calldatahex ---
String abiEncodeBuyCallData(BigInt tokenId, BigInt quantity) {
  const selector = 'cf27a9f4';
  String padTo64(String inputHex) => inputHex.padLeft(64, '0');
  final tokenIdHex = padTo64(tokenId.toRadixString(16));
  final quantityHex = padTo64(quantity.toRadixString(16));
  return '0x$selector$tokenIdHex$quantityHex';
}

Web3App? _wcClient;
SessionData? _wcSession;

// --- Main Buy Now Handler with WalletConnect V2 ---
Future<void> handleBuyNow(
    BuildContext context,
    dynamic tokenIdRaw,
    String priceWeiStr,
    int maxAvailable,
    String contractAddress,
    List<dynamic> contractAbi,
    ) async {
  int selectedQty = 1;

  // 1. Prompt user for quantity
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
                      style: Theme.of(context).textTheme.headlineSmall,
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

  final tokenId = BigInt.tryParse(tokenIdRaw.toString()) ?? BigInt.zero;
  final quantity = BigInt.from(selectedQty);
  final pricePerItem = BigInt.tryParse(priceWeiStr) ?? BigInt.zero;
  final totalValue = pricePerItem * quantity;

  // 3. ABI-encode buy() calldata
  final calldataHex = abiEncodeBuyCallData(tokenId, quantity);

  // 4. Value in hex for MetaMask param
  final valueHex = "0x${totalValue.toRadixString(16)}";
  final to = contractAddress.trim();

  // 5. Connect via WalletConnect
  try {
    if (_wcClient == null) {
      _wcClient = await Web3App.createInstance(
        // IMPORTANT: Replace with your actual Project ID from cloud.walletconnect.com
        projectId: 'c6b9e24f1cf19c03e0e6cea20327da85',
        metadata: const PairingMetadata(
          name: 'Marketing Fruit',
          description: 'NFT Marketplace',
          url: 'https://marketingfruit.com',
          icons: ['https://marketingfruit.com/icon.png'],
          redirect: Redirect(
            native: 'marketingfruit://',
            universal: 'https://marketingfruit.com',
          ),
        ),
      );
    }

    if (_wcSession == null) {
      final ConnectResponse res = await _wcClient!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:1', 'eip155:137'], // Adjust for your network (e.g. Ethereum/Polygon)
            methods: ['eth_sendTransaction', 'personal_sign'],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final uri = res.uri;
      if (uri != null) {
        final link = 'metamask://wc?uri=${Uri.encodeComponent(uri.toString())}';
        if (await canLaunchUrl(Uri.parse(link))) {
          await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
        } else {
          await showDialog(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text('MetaMask Not Found'),
              content: Text('Please install MetaMask and try again.'),
            ),
          );
          return;
        }
      }
      // Wait for user to approve the session in their wallet
      _wcSession = await res.session.future;
    }

    final namespace = _wcSession!.namespaces['eip155'];
    if (namespace == null || namespace.accounts.isEmpty) {
      throw Exception('No accounts connected');
    }
    
    // account string is formatted like eip155:1:0x123...
    final account = namespace.accounts.first.split(':').last;
    final chainId = namespace.accounts.first.split(':').sublist(0, 2).join(':');

    final tx = {
      'from': account,
      'to': to,
      'data': calldataHex,
      'value': valueHex,
    };

    // Open MetaMask again to prompt the transaction signature
    final link = 'metamask://';
    if (await canLaunchUrl(Uri.parse(link))) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    }

    // Send the transaction request
    final hash = await _wcClient!.request(
      topic: _wcSession!.topic,
      chainId: chainId,
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [tx],
      ),
    );
    
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: Text('Transaction submitted!\nHash: $hash'),
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

/// Buy Gems using Polygon MATIC through crypto wallet (MetaMask via WalletConnect V2)
Future<String?> buyGemsWithCryptoWallet({
  required BuildContext context,
  required int maticAmount,
  required int gemsAmount,
  String recipientAddress = '0xb65BF8a2416EEd21C31A067F771A4Cf65059FaCE',
}) async {
  final totalWei = BigInt.from(maticAmount) * BigInt.from(10).pow(18);
  final valueHex = "0x${totalWei.toRadixString(16)}";
  final to = recipientAddress.trim();

  try {
    if (_wcClient == null) {
      _wcClient = await Web3App.createInstance(
        projectId: 'c6b9e24f1cf19c03e0e6cea20327da85',
        metadata: const PairingMetadata(
          name: 'Marketing Fruit',
          description: 'Sim Shop & NFT Marketplace',
          url: 'https://marketingfruit.com',
          icons: ['https://marketingfruit.com/icon.png'],
          redirect: Redirect(
            native: 'marketingfruit://',
            universal: 'https://marketingfruit.com',
          ),
        ),
      );
    }

    if (_wcSession == null) {
      final ConnectResponse res = await _wcClient!.connect(
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:137', 'eip155:1'], // Polygon Mainnet first
            methods: ['eth_sendTransaction', 'personal_sign'],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final uri = res.uri;
      if (uri != null) {
        final link = 'metamask://wc?uri=${Uri.encodeComponent(uri.toString())}';
        final canLaunch = await canLaunchUrl(Uri.parse(link));
        if (canLaunch) {
          await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
        } else {
          if (!context.mounted) return null;
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
                  Text('MetaMask App Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To complete your crypto purchase on Polygon network, please connect with the MetaMask mobile app.',
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
          } else {
            return null;
          }
        }
      }
      _wcSession = await res.session.future;
    }

    final namespace = _wcSession!.namespaces['eip155'];
    if (namespace == null || namespace.accounts.isEmpty) {
      throw Exception('No accounts connected from MetaMask');
    }

    final account = namespace.accounts.first.split(':').last;
    final chainId = namespace.accounts.first.split(':').sublist(0, 2).join(':');

    final tx = {
      'from': account,
      'to': to,
      'value': valueHex,
      'data': '0x',
    };

    // Open MetaMask again to prompt the transaction signature
    final link = 'metamask://';
    if (await canLaunchUrl(Uri.parse(link))) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    }

    // Send the transaction request
    final hash = await _wcClient!.request(
      topic: _wcSession!.topic,
      chainId: chainId,
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [tx],
      ),
    );

    return hash?.toString();
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
