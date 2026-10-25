import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_NFT.dart';
import 'nft_helpers_mobile.dart'
if (dart.library.html) 'nft_helpers_web.dart';

// --- Constants ---
const v2ApiKey = 'T6KZZ5BM5XYCCMJGQ32X3II4KZEA7TV5EZ';
const walletAddress = '0xb65BF8a2416EEd21C31A067F771A4Cf65059FaCE';
const v2BaseUrl = 'https://api.etherscan.io/v2/api';
const chainId = 137; // Polygon mainnet

class NFTOverviewSection extends StatefulWidget {
  final VoidCallback? onAddNFT;
  final void Function(String txnHash)? onTxnTap;
  final void Function(Map<String, dynamic> nft)? onNftTap;
  const NFTOverviewSection(
      {super.key, this.onAddNFT, this.onTxnTap, this.onNftTap});

  @override
  State<NFTOverviewSection> createState() => _NFTOverviewSectionState();
}

class _NFTOverviewSectionState extends State<NFTOverviewSection> {
  int selectedTab = 0; // 0: Transactions, 1: NFT Transfers, 2: Assets
  Map<String, dynamic>? overviewData;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> nftTransfers = [];
  bool isLoading = true;
  bool tabLoading = false;
  String? error;
  bool downloadingCsv = false;

  @override
  void initState() {
    super.initState();
    loadOverviewAndTransactions();
  }

  Future<void> loadOverviewAndTransactions() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final overview = await fetchOverview();
      final txnsRaw = await fetchTransactions();
      // transactions: all
      // nftTransfers: only Mints & Transfers where the wallet is recipient
      setState(() {
        overviewData = overview;
        transactions = txnsRaw;
        nftTransfers = txnsRaw
            .where((tx) =>
        tx['method'] == 'Mint NFT' ||
            tx['to'].toString().toLowerCase() ==
                walletAddress.toLowerCase())
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Tab switching: reload data for transactions/nft transfers for freshness
  Future<void> handleTabChange(int tab) async {
    setState(() {
      selectedTab = tab;
      tabLoading = true;
      error = null;
    });
    if (tab == 0 || tab == 1) {
      try {
        final txnsRaw = await fetchTransactions();
        setState(() {
          transactions = txnsRaw;
          nftTransfers = txnsRaw
              .where((tx) =>
          tx['method'] == 'Mint NFT' ||
              tx['to'].toString().toLowerCase() ==
                  walletAddress.toLowerCase())
              .toList();
          tabLoading = false;
        });
      } catch (e) {
        setState(() {
          error = e.toString();
          tabLoading = false;
        });
      }
    } else {
      setState(() {
        tabLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchOverview() async {
    const polContract = '0xF1Ef28A571d62af56ea37956aA8a6FBBAA95ed55';
    final polBalanceUrl =
        '$v2BaseUrl?chainid=$chainId&module=account&action=balance'
        '&address=$walletAddress'
        '&tag=latest'
        '&apikey=$v2ApiKey';

    final resp = await http.get(Uri.parse(polBalanceUrl));
    final data = json.decode(resp.body);

    final BigInt raw = BigInt.tryParse(data['result'] ?? '0') ?? BigInt.zero;
    final polDecimal = 18;
    final balance = raw / BigInt.from(10).pow(polDecimal);
    final value = balance.toDouble() * 0.02;

    return {
      'pol_balance': balance.toStringAsFixed(6),
      'pol_value': value.toStringAsFixed(2),
      'wallet_address': walletAddress,
    };
  }

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final nftTxUrl =
        '$v2BaseUrl?chainid=$chainId&module=account&action=token1155tx&address=$walletAddress&page=1&offset=100&sort=desc&apikey=$v2ApiKey';
    final response = await http.get(Uri.parse(nftTxUrl));
    final body = json.decode(response.body);

    if (body['status'] != '1') return [];
    List txArr = body['result'];
    return txArr.map<Map<String, dynamic>>((tx) {
      final isMint = tx['from'].toString().toLowerCase() ==
          '0x0000000000000000000000000000000000000000' ||
          tx['to'].toString().toLowerCase() == walletAddress.toLowerCase();
      return {
        'txn_hash': tx['hash'],
        'method': isMint ? 'Mint NFT' : 'Transfer',
        'block': tx['blockNumber'],
        'age': DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(tx['timeStamp'] ?? '0')! * 1000,
        ))
            .inDays
            .toString(),
        'from': tx['from'].toString()
            .compareTo('0x0000000000000000000000000000000000000000') ==
            0
            ? '0x00000000....00000000000000000000000000'
            : tx['from'],
        'to': tx['to'],
        'amount': '0',
        'token_fee': '0.00334', // Demo fee value
      };
    }).toList();
  }

  void handleDownloadCsv(List<Map<String, dynamic>> data) {
    setState(() => downloadingCsv = true);
    downloadCsv(data);
    setState(() => downloadingCsv = false);
  }

  void handleOpenMetamaskExtension() {
    openMetamaskExtension();
  }

  Widget _tabChip(
      String label, bool selected, int tab, ThemeData theme, Color activeColor, Color bgColor) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(color: selected ? theme.hintColor : theme.hintColor)),
      selected: selected,
      selectedColor: activeColor,
      backgroundColor: bgColor,
      onSelected: (_) => handleTabChange(tab),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final chipColor = theme.scaffoldBackgroundColor;
    final activeChipColor = const Color(0xFF7C7CB8);

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Card
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Overview",
                                style: TextStyle(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("POL BALANCE",
                                style: TextStyle(
                                    fontSize: 13, color: theme.hintColor)),
                            Text(
                              overviewData?['pol_balance'] ?? '--',
                              style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: theme.hintColor),
                            ),
                            const SizedBox(height: 10),
                            Text("POL VALUE",
                                style: TextStyle(
                                    fontSize: 13, color: theme.hintColor)),
                            Text(
                              "\$${overviewData?['pol_value'] ?? '--'}",
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.greenAccent.shade700),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Wallet Address",
                                style: TextStyle(
                                    color: theme.hintColor, fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    walletAddress,
                                    style: TextStyle(
                                        color: theme.hintColor,
                                        fontFamily: 'monospace',
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: handleOpenMetamaskExtension,
                                  tooltip: "Open in MetaMask",
                                  icon: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.amber,
                                      size: 26),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Chips/Tabs
                Row(
                  children: [
                    _tabChip("Transactions", selectedTab == 0, 0, theme, activeChipColor, chipColor),
                    const SizedBox(width: 12),
                    _tabChip("NFT Transfers", selectedTab == 1, 1, theme, activeChipColor, chipColor),
                    const SizedBox(width: 12),
                    _tabChip("Assets", selectedTab == 2, 2, theme, activeChipColor, chipColor),
                  ],
                ),
                const SizedBox(height: 22),
                // Tab Body
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: isLoading || tabLoading
                      ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50.0),
                        child: CircularProgressIndicator(),
                      ))
                      : error != null
                      ? Text("Error: $error",
                      style: const TextStyle(color: Colors.red))
                      : selectedTab == 2
                      ? AddNFT(
                    onAddNFT: widget.onAddNFT,
                    onNftTap: widget.onNftTap,
                  )
                      : ((selectedTab == 0 ? transactions : nftTransfers)
                      .isEmpty)
                      ? Text("No data.",
                      style:
                      TextStyle(color: theme.hintColor))
                      : Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Text(
                              selectedTab == 0
                                  ? "Transactions"
                                  : "NFT Transfers",
                              style: TextStyle(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor:
                              theme.hintColor,
                            ),
                            onPressed: downloadingCsv
                                ? null
                                : () {
                              final data =
                              selectedTab == 0
                                  ? List<
                                  Map<String,
                                      dynamic>>.from(
                                  transactions)
                                  : List<
                                  Map<String,
                                      dynamic>>.from(
                                  nftTransfers);
                              handleDownloadCsv(data);
                            },
                            icon: Icon(Icons.download,
                                color: theme.hintColor),
                            label: const Text(
                                "Download Page Data"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection:
                          Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(
                                  label: Text(
                                      "Txn Hash",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                              DataColumn(
                                  label: Text(
                                      "Method",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                              DataColumn(
                                  label: Text(
                                      "Block",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                              DataColumn(
                                  label: Text(
                                      "Age",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                              DataColumn(
                                  label: Text(
                                      "From",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                              DataColumn(
                                  label: Text(
                                      "To",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                              DataColumn(
                                  label: Text(
                                      "Amount",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                              DataColumn(
                                  label: Text(
                                      "Token Fee",
                                      style: TextStyle(
                                          color:
                                          Colors
                                              .black))),
                            ],
                            rows: ((selectedTab == 0
                                ? transactions
                                : nftTransfers))
                                .map<DataRow>((tx) =>
                                DataRow(cells: [
                                  DataCell(
                                    InkWell(
                                      onTap: () =>
                                          widget.onTxnTap
                                              ?.call(tx[
                                          'txn_hash']),
                                      child: Text(
                                        (tx['txn_hash']
                                            .toString()
                                            .length >=
                                            8
                                            ? "${tx['txn_hash']
                                            .toString()
                                            .substring(
                                            0,
                                            8)}..."
                                            : tx['txn_hash']
                                            .toString()),
                                        style: const TextStyle(
                                            color: Colors
                                                .blue,
                                            fontFamily:
                                            'monospace',
                                            decoration:
                                            TextDecoration
                                                .underline),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(
                                      tx['method'] ?? '',
                                      style: TextStyle(
                                          color: theme
                                              .hintColor))),
                                  DataCell(Text(
                                      tx['block'] ?? '',
                                      style: TextStyle(
                                          color: theme
                                              .hintColor))),
                                  DataCell(Text(
                                      tx['age'] +
                                          " days ago",
                                      style: TextStyle(
                                          color: theme
                                              .hintColor))),
                                  DataCell(Text(
                                      tx['from'] ?? '',
                                      style: TextStyle(
                                          color: theme
                                              .hintColor))),
                                  DataCell(Text(
                                      tx['to'] ?? '',
                                      style: TextStyle(
                                          color: theme
                                              .hintColor))),
                                  DataCell(Text(
                                      tx['amount'] ?? '',
                                      style: TextStyle(
                                          color: theme
                                              .hintColor))),
                                  DataCell(Text(
                                      tx['token_fee'] ??
                                          '',
                                      style: TextStyle(
                                          color: theme
                                              .hintColor))),
                                ]))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
