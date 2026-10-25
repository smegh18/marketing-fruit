import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

// Use your Etherscan V2 Key and chainid = 137 for Polygon.
const etherscanApiKey = 'T6KZZ5BM5XYCCMJGQ32X3II4KZEA7TV5EZ';
const etherscanV2ApiBase = 'https://api.etherscan.io/v2/api';
const chainId = 137;

// Helper: nice monospace code-style for addresses/hashes


class TxnDetailScreen extends StatefulWidget {
  final String txnHash;
  final VoidCallback? onClose;
  const TxnDetailScreen({super.key, required this.txnHash, this.onClose});

  @override
  State<TxnDetailScreen> createState() => _TxnDetailScreenState();
}

class _TxnDetailScreenState extends State<TxnDetailScreen> {
  Map<String, dynamic>? txnData; // eth_getTransactionByHash
  Map<String, dynamic>? receiptData; // eth_getTransactionReceipt
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchTxnDetail();
  }

  Future<void> fetchTxnDetail() async {
    setState(() { loading = true; error = null; });
    try {
      print(widget.txnHash);
      final rawTxn = await fetchV2('proxy', {
        'action': 'eth_getTransactionByHash',
        'txhash': widget.txnHash,
      });
      final rawReceipt = await fetchV2('proxy', {
        'action': 'eth_getTransactionReceipt',
        'txhash': widget.txnHash,
      });
      print(rawTxn);
      print(rawReceipt);

      if (rawTxn['result'] == null || rawReceipt['result'] == null) {
        setState(() { error = 'Transaction not found.'; loading = false; });
        return;
      }
      setState(() {
        txnData = rawTxn['result'];
        receiptData = rawReceipt['result'];
        loading = false;
      });
    } catch (e) {
      setState(() { error = 'Failed to load transaction details.'; loading = false; });
    }
  }

  Future<Map<String, dynamic>> fetchV2(String module, Map<String, String> params) async {
    final paramStr = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final url = '$etherscanV2ApiBase?chainid=$chainId&module=$module&$paramStr&apikey=$etherscanApiKey';
    final resp = await http.get(Uri.parse(url));
    print(resp);
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Widget buildDetailRow(String label,Color textColor, Widget value, {Widget? trailing, bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 180, child: Text(label, style: TextStyle(color: textColor))),
          Expanded(child: value),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget buildCopyIcon(String text) => IconButton(
    icon: const Icon(Icons.copy, size: 18, color: Color(0xFF6EE7B7)),
    tooltip: "Copy",
    onPressed: () {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
    },
  );

  String formatEth(String? value, {int decimals = 18, int precision = 6}) {
    if (value == null) return '-';
    final raw = BigInt.tryParse(value) ?? BigInt.zero;
    final formatted = raw / BigInt.from(10).pow(decimals);
    return formatted.toStringAsFixed(precision);
  }

  @override
  Widget build(BuildContext context) {
    // Main colors
    final theme = Theme.of(context);
    final darkBg = theme.cardColor;
    const blockBg = Color(0xFF232344);
    const green = Color(0xFF22D3EE);
    const purple = Color(0xFFA78BFA);
    TextStyle codeStyle = TextStyle(fontFamily: 'monospace', color: Theme.of(context).hintColor, fontSize: 14);

    return Container(
      decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
            ),
         ],
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: darkBg,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: TRANSACTION ACTION
                  Text.rich(
                    TextSpan(children: [
                      WidgetSpan(
                        child: Icon(Icons.sync_alt_rounded, size: 20, color: purple),
                      ),
                      TextSpan(text: "  TRANSACTION ACTION", style: TextStyle(letterSpacing: 2, color: purple, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFF312E81),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Transfer 1 of 1   •   MINT", // Example action
                      style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(),
                  const SizedBox(height: 10),
                  // Section: Transaction Hash
                  buildDetailRow(
                    "Transaction Hash",
                    theme.hintColor,
                    Row(children: [
                      Flexible(child: Text(txnData?['hash'] ?? '-', style: codeStyle)),
                      buildCopyIcon(txnData?['hash'] ?? '-'),
                    ]),
                  ),
                  // Status
                  buildDetailRow(
                    "Status",
                    theme.hintColor,
                    Row(children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text(
                          (receiptData?['status'] == '0x1') ? 'Success' : 'Failed',
                          style: TextStyle(color: (receiptData?['status'] == '0x1') ? Colors.green : Colors.red)
                      ),
                    ]),
                  ),
                  // Block
                  buildDetailRow(
                    "Block",
                    theme.hintColor,
                    Row(
                      children: [
                        Text(int.tryParse(txnData?['blockNumber'] ?? '')?.toString() ?? '-', style: codeStyle),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: purple.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${receiptData?['confirmations'] ?? '-'} Block Confirmations",
                            style: TextStyle(color: purple, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timestamp
                  buildDetailRow(
                    "Timestamp",
                    theme.hintColor,
                    Text("-- UTC", style: codeStyle), // Replace with parsed time if available!
                  ),
                  Divider(),
                  // --- Ad banner area ---
                  // Container(
                  //   margin: const EdgeInsets.symmetric(vertical: 16),
                  //   padding: const EdgeInsets.all(16),
                  //   color: Colors.black26,
                  //   height: 56,
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       Image.network(
                  //         'https://cdn.bc.game/logo.svg', // Placeholder (use your own/ad system)
                  //         width: 32, height: 32, errorBuilder: (_,__,___)=>SizedBox(),
                  //       ),
                  //       const SizedBox(width: 12),
                  //       const Text("BC.GAME 3.2x  WIN 1 BTC    PLAY NOW",
                  //           style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
                  //     ],
                  //   ),
                  // ),
                  // From
                  buildDetailRow(
                    "From",
                    theme.hintColor,
                    Row(children: [
                      Flexible(child: Text(txnData?['from'] ?? '-', style: codeStyle)),
                      buildCopyIcon(txnData?['from'] ?? '-'),
                    ]),
                  ),
                  // Interacted With (To)
                  buildDetailRow(
                    "Interacted With (To)",
                    theme.hintColor,
                    Row(children: [
                      Flexible(child: Text(txnData?['to'] ?? '-', style: codeStyle)),
                      buildCopyIcon(txnData?['to'] ?? '-'),
                    ]),
                  ),
                  Divider(),
                  // ERC-721 Tokens Transferred (if present)
                  if (receiptData != null && receiptData!['logs'] != null)
                    buildDetailRow(
                      "ERC-721 Tokens Transferred",
                      theme.hintColor,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   "Token ID: ...", // Parse log topics if you want full NFT info
                          //   style: codeStyle.copyWith(color: Color(0xFF7DD3FC)),
                          // ),
                          Text("MNFT (MNFT) \nFrom Null: 0x000... To: ${txnData?['to'] ?? '-'}", style: codeStyle.copyWith(fontSize: 13)),
                        ],
                      ),
                      multiLine: true,
                    ),
                  // Value
                  buildDetailRow("Value",theme.hintColor, Text("0 POL (\$0.00)", style: codeStyle)),
                  // Transaction Fee
                  buildDetailRow(
                    "Transaction Fee",
                    theme.hintColor,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 12, child: Image(image: AssetImage('assets/polygon.png'))),
                        SizedBox(width: 6),
                        Text(
                            "${formatEth(receiptData?['gasUsed'])} POL (\$0.0007)",  // Replace with actual value, parsed to match UX
                            style: codeStyle
                        ),
                      ],
                    ),
                  ),
                  // Gas Price
                  buildDetailRow(
                    "Gas Price",
                    theme.hintColor,
                    Text("${formatEth(txnData?['gasPrice'])} Gwei (0.00000026 POL)", style: codeStyle),
                  ),
                  // const Divider(color: Colors.white24, height: 32),
                  // // More Details (expandable)
                  // ExpansionTile(
                  //   tilePadding: EdgeInsets.zero,
                  //   iconColor: purple,
                  //   collapsedIconColor: purple,
                  //   title: Text("+ Click to show more", style: TextStyle(color: purple, fontWeight: FontWeight.w600)),
                  //   children: [
                  //     Padding(
                  //       padding: EdgeInsets.only(left: 16, bottom: 10),
                  //       child: Text("Raw Data:\n${const JsonEncoder.withIndent('  ').convert(txnData)}",
                  //           style: TextStyle(color: theme.hintColor, fontSize: 12)),
                  //     )
                  //   ],
                  // ),
                  // const SizedBox(height: 18),
                  // Private Note
            //       Container(
            //         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            //         decoration: BoxDecoration(
            //           color: blockBg,
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: Text(
            //           "Private Note: To access the Private Note feature, you must be Logged in",
            //           style: TextStyle(color: Colors.white54, fontSize: 13),
            //         ),
            //       ),
            //       const SizedBox(height: 8),
            //       // Footer note
            //       const Padding(
            //         padding: EdgeInsets.only(top: 8),
            //         child: Text("A transaction is a cryptographically signed instruction that changes the blockchain state...",
            //             style: TextStyle(color: Colors.white38, fontSize: 12)),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    ])));
  }
}
