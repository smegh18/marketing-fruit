import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/screens/dashboard/web3_helpers_stub.dart'
    if (dart.library.html) 'package:Marketing_Fruit/screens/dashboard/web3_helpers_web.dart';

/// Models for Wallet and Balances
class SimWalletBalance {
  final num coins;
  final num gems;
  final num poly;

  const SimWalletBalance({
    required this.coins,
    required this.gems,
    required this.poly,
  });

  static SimWalletBalance fromRaw(dynamic data) {
    if (data == null) return const SimWalletBalance(coins: 0, gems: 0, poly: 0);

    if (data is num) {
      return SimWalletBalance(coins: data, gems: 0, poly: 0);
    }

    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      num coins = 0;
      num gems = 0;
      num poly = 0;

      if (m['balance'] is Map) {
        final bMap = Map<String, dynamic>.from(m['balance'] as Map);
        coins = _num(bMap['coins']) ?? _num(bMap['balance']) ?? _num(m['coins']) ?? _num(m['balance']) ?? 0;
        gems = _num(bMap['gems']) ?? _num(m['gems']) ?? 0;
        poly = _num(bMap['polyMatic']) ?? _num(bMap['polygon']) ?? _num(bMap['poly']) ?? _num(m['polyMatic']) ?? _num(m['polygon']) ?? 0;
      } else {
        coins = _num(m['coins']) ?? _num(m['balance']) ?? 0;
        gems = _num(m['gems']) ?? 0;
        poly = _num(m['polyMatic']) ?? _num(m['polygon']) ?? _num(m['poly']) ?? 0;
      }

      return SimWalletBalance(coins: coins, gems: gems, poly: poly);
    }

    return const SimWalletBalance(coins: 0, gems: 0, poly: 0);
  }

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }
}

/// Comprehensive Sim Shop Screen supporting both Web and Mobile Layouts
class SimShopScreen extends StatefulWidget {
  final bool isWeb;
  final VoidCallback? onBack;

  const SimShopScreen({
    super.key,
    this.isWeb = false,
    this.onBack,
  });

  @override
  State<SimShopScreen> createState() => _SimShopScreenState();
}

class _SimShopScreenState extends State<SimShopScreen> {
  // Live rates from Firebase
  int? coinsPerGem; // game_finance/row1: coins / gems
  double? gemsPerMatic; // game_finance/row2: gems2 / poly

  StreamSubscription<DatabaseEvent>? _row1Sub;
  StreamSubscription<DatabaseEvent>? _row2Sub;
  StreamSubscription<DatabaseEvent>? _walletSub;

  SimWalletBalance _balance = const SimWalletBalance(coins: 0, gems: 0, poly: 0);
  bool _loadingBalance = true;

  // Scroll controllers & keys
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _buyCoinsSectionKey = GlobalKey();
  final GlobalKey _buyGemsSectionKey = GlobalKey();

  // Custom pack inputs
  final TextEditingController _customCoinsCtrl = TextEditingController();
  final TextEditingController _customGemsForCoinsCtrl = TextEditingController();

  final TextEditingController _customMaticCtrl = TextEditingController();
  final TextEditingController _customGemsForMaticCtrl = TextEditingController();

  String? _coinsError;
  String? _gemsError;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? (kDebugMode ? '6wlOwtK3bMfhrSs7qsq6CXSwp083' : '');
  }

  @override
  void initState() {
    super.initState();
    _listenRates();
    _listenWallet();
  }

  @override
  void dispose() {
    _row1Sub?.cancel();
    _row2Sub?.cancel();
    _walletSub?.cancel();
    _scrollController.dispose();
    _customCoinsCtrl.dispose();
    _customGemsForCoinsCtrl.dispose();
    _customMaticCtrl.dispose();
    _customGemsForMaticCtrl.dispose();
    super.dispose();
  }

  void _listenRates() {
    // Row 1: Coins / Gems ratio
    final r1 = FirebaseDatabase.instance.ref("game_finance/row1");
    _row1Sub = r1.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey("coins") && data.containsKey("gems")) {
        final coins = (data["coins"] as num).toDouble();
        final gems = (data["gems"] as num).toDouble();
        if (gems > 0) {
          setState(() {
            coinsPerGem = (coins / gems).round();
            _recalcCustomCoins();
          });
        }
      }
    });

    // Row 2: Gems / Poly ratio
    final r2 = FirebaseDatabase.instance.ref("game_finance/row2");
    _row2Sub = r2.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey("gems2") && data.containsKey("poly")) {
        final gems = (data["gems2"] as num).toDouble();
        final poly = (data["poly"] as num).toDouble();
        if (poly > 0) {
          setState(() {
            gemsPerMatic = gems / poly;
            _recalcCustomGems();
          });
        }
      }
    });
  }

  void _listenWallet() {
    final uid = _uid;
    if (uid.isEmpty) {
      setState(() => _loadingBalance = false);
      return;
    }

    final ref = FirebaseDatabase.instance.ref('wallet/$uid');
    _walletSub = ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      setState(() {
        _balance = SimWalletBalance.fromRaw(data);
        _loadingBalance = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loadingBalance = false);
    });
  }

  int _calcCoinsForGems(int gems) {
    final rate = coinsPerGem ?? 10;
    return (gems * rate).clamp(1, 999999999);
  }

  int _calcGemsForMatic(int matic) {
    final rate = gemsPerMatic ?? 15.0;
    return (matic * rate).ceil().clamp(1, 999999999);
  }

  void _recalcCustomCoins() {
    final coins = int.tryParse(_customCoinsCtrl.text.trim()) ?? 0;
    if (coins <= 0 || coinsPerGem == null || coinsPerGem == 0) {
      _customGemsForCoinsCtrl.text = '';
      return;
    }
    final gems = (coins / coinsPerGem!).ceil();
    _customGemsForCoinsCtrl.text = '$gems';
  }

  void _recalcCustomGems() {
    final matic = int.tryParse(_customMaticCtrl.text.trim()) ?? 0;
    if (matic <= 0 || gemsPerMatic == null || gemsPerMatic == 0) {
      _customGemsForMaticCtrl.text = '';
      return;
    }
    final gems = (matic * gemsPerMatic!).ceil();
    _customGemsForMaticCtrl.text = '$gems';
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  String _fmtNumber(num n) {
    if (n.abs() >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n.abs() >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
  }

  // --- Purchase / Exchange Execution ---
  Future<void> _executeExchangeGemsForCoins({
    required int gemsSpent,
    required int coinsReceived,
    required String packTitle,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) {
      _showToast("Please sign in to make simulator purchases.", isError: true);
      return;
    }

    if (_balance.gems < gemsSpent) {
      _showToast(
        "Insufficient gems (${_balance.gems} available, $gemsSpent needed). Buy gems below!",
        isError: true,
      );
      _scrollToKey(_buyGemsSectionKey);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: "Exchange Gems for Coins",
      spendText: "$gemsSpent Gems",
      receiveText: "+$coinsReceived Game Coins",
      spendIcon: Icons.diamond_outlined,
      receiveIcon: Icons.monetization_on_outlined,
      spendColor: const Color(0xFFA855F7),
      receiveColor: const Color(0xFF10B981),
    );

    if (confirmed != true) return;

    try {
      final ref = FirebaseDatabase.instance.ref('wallet/$uid');
      final newGems = _balance.gems - gemsSpent;
      final newCoins = _balance.coins + coinsReceived;

      await ref.update({
        'gems': newGems,
        'coins': newCoins,
        'balance': {
          'coins': newCoins,
          'gems': newGems,
          'polyMatic': _balance.poly,
        },
      });

      // Record transaction
      await FirebaseDatabase.instance.ref('wallet/$uid/transactions').push().set({
        'title': 'Bought $packTitle ($coinsReceived Coins)',
        'type': 'coins_exchange',
        'gemsSpent': gemsSpent,
        'coinsReceived': coinsReceived,
        'timestamp': ServerValue.timestamp,
      });

      if (!mounted) return;
      _showToast("Successfully exchanged $gemsSpent gems for $coinsReceived coins!");
    } catch (e) {
      if (!mounted) return;
      _showToast("Exchange failed: $e", isError: true);
    }
  }

  Future<void> _executeBuyGemsWithMatic({
    required int maticSpent,
    required int gemsReceived,
    required String packTitle,
  }) async {
    final uid = _uid;
    if (uid.isEmpty) {
      _showToast("Please sign in to make simulator purchases.", isError: true);
      return;
    }

    const adminWallet = '0xb65BF8a2416EEd21C31A067F771A4Cf65059FaCE';

    final confirmed = await _showConfirmDialog(
      title: "Buy Simulator Gems via Crypto",
      spendText: "$maticSpent MATIC",
      receiveText: "+$gemsReceived Gems",
      spendIcon: Icons.currency_bitcoin,
      receiveIcon: Icons.diamond_outlined,
      spendColor: const Color(0xFF3B82F6),
      receiveColor: const Color(0xFFA855F7),
      extraInfo: "This transaction will be signed and submitted on Polygon Mainnet via your connected MetaMask crypto wallet (Developer API).",
      recipientAddress: adminWallet,
    );

    if (confirmed != true) return;

    // Show loading modal while MetaMask connects and signs
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2129),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFA855F7)),
              const SizedBox(height: 18),
              Text(
                "Connecting to MetaMask...",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "Please approve and sign the transaction in your MetaMask wallet on Polygon network.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    String? txHash;
    try {
      txHash = await buyGemsWithCryptoWallet(
        context: context,
        maticAmount: maticSpent,
        gemsAmount: gemsReceived,
        recipientAddress: adminWallet,
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // close loading
      }
      _showToast("Wallet error: $e", isError: true);
      return;
    }

    // Dismiss loading dialog
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (txHash == null) {
      // Transaction was cancelled or aborted
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref('wallet/$uid');
      final newGems = _balance.gems + gemsReceived;

      await ref.update({
        'gems': newGems,
        'balance': {
          'coins': _balance.coins,
          'gems': newGems,
          'polyMatic': _balance.poly,
        },
      });

      // Record transaction with real txHash
      await FirebaseDatabase.instance.ref('wallet/$uid/transactions').push().set({
        'title': 'Purchased $packTitle ($gemsReceived Gems)',
        'type': 'gems_purchase_crypto',
        'maticSpent': maticSpent,
        'gemsReceived': gemsReceived,
        'txHash': txHash,
        'network': 'Polygon Mainnet (137)',
        'recipient': adminWallet,
        'timestamp': ServerValue.timestamp,
      });

      if (!mounted) return;
      _showCryptoSuccessDialog(
        packTitle: packTitle,
        maticSpent: maticSpent,
        gemsReceived: gemsReceived,
        txHash: txHash,
      );
    } catch (e) {
      if (!mounted) return;
      _showToast("Database update error: $e", isError: true);
    }
  }

  void _showCryptoSuccessDialog({
    required String packTitle,
    required int maticSpent,
    required int gemsReceived,
    required String txHash,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2129),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              "Transaction Confirmed!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              "+$gemsReceived Gems added to your wallet",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14171E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Paid via MetaMask:", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                      Text("$maticSpent MATIC", style: GoogleFonts.poppins(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Transaction Hash:", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          txHash,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.copy, size: 14, color: Colors.white54),
                        tooltip: "Copy Hash",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: txHash));
                          _showToast("Transaction hash copied to clipboard!");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF60A5FA),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: Text("Polygonscan", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      final url = Uri.parse("https://polygonscan.com/tx/$txHash");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("Done", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String spendText,
    required String receiveText,
    required IconData spendIcon,
    required IconData receiveIcon,
    required Color spendColor,
    required Color receiveColor,
    String? extraInfo,
    String? recipientAddress,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2129),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14171E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: spendColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(spendIcon, color: spendColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("You spend", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                          Text(spendText, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.arrow_downward, color: Colors.white30, size: 18),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: receiveColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(receiveIcon, color: receiveColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("You receive", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                          Text(receiveText, style: GoogleFonts.poppins(color: receiveColor, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (extraInfo != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          "MetaMask Developer API",
                          style: GoogleFonts.poppins(color: const Color(0xFF60A5FA), fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extraInfo,
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                    ),
                    if (recipientAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Official Wallet: $recipientAddress",
                        style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Proceed to Wallet", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800 && !widget.isWeb;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171E),
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: widget.onBack,
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  )
                : null),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sim Shop",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Simulator Currency & Economy",
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          // Quick Balance Badges in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _buildQuickBadge(
                  icon: Icons.monetization_on,
                  color: const Color(0xFF10B981),
                  text: _loadingBalance ? '...' : _fmtNumber(_balance.coins),
                  onTap: () => _scrollToKey(_buyCoinsSectionKey),
                ),
                const SizedBox(width: 8),
                _buildQuickBadge(
                  icon: Icons.diamond,
                  color: const Color(0xFFA855F7),
                  text: _loadingBalance ? '...' : _fmtNumber(_balance.gems),
                  onTap: () => _scrollToKey(_buyGemsSectionKey),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : 32.0,
            vertical: 20.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live Wallet Balance Header
                  _buildWalletCards(isMobile),
                  const SizedBox(height: 28),

                  // 2. Buy Game Currency (Coins with Gems)
                  _buildBuyCoinsSection(isMobile),
                  const SizedBox(height: 32),

                  // 3. Buy Gems (Gems with MATIC)
                  _buildBuyGemsSection(isMobile),
                  const SizedBox(height: 32),

                  // 4. Recent Activity & Transactions
                  _buildRecentTransactionsSection(isMobile),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBadge({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 1. WALLET BALANCE CARDS =================
  Widget _buildWalletCards(bool isMobile) {
    final cards = [
      _BalanceCardItem(
        title: "Game Currency",
        symbol: "Coins",
        value: _loadingBalance ? "..." : _fmtNumber(_balance.coins),
        icon: Icons.monetization_on,
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        actionLabel: "Exchange Coins",
        onAction: () => _scrollToKey(_buyCoinsSectionKey),
      ),
      _BalanceCardItem(
        title: "Simulator Gems",
        symbol: "Gems",
        value: _loadingBalance ? "..." : _fmtNumber(_balance.gems),
        icon: Icons.diamond,
        gradient: const LinearGradient(
          colors: [Color(0xFF6B21A8), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        actionLabel: "Get Gems",
        onAction: () => _scrollToKey(_buyGemsSectionKey),
      ),
      _BalanceCardItem(
        title: "Polygon MATIC",
        symbol: "MATIC",
        value: _loadingBalance ? "..." : _fmtNumber(_balance.poly),
        icon: Icons.currency_bitcoin,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        actionLabel: "Crypto Top-Up",
        onAction: () => _scrollToKey(_buyGemsSectionKey),
      ),
    ];

    if (isMobile) {
      // Mobile: Swipeable horizontal card list with peek
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final c = cards[i];
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.72,
              child: _buildBalanceCardWidget(c),
            );
          },
        ),
      );
    }

    // Web: 3 cards row
    return Row(
      children: cards.map((c) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              height: 145,
              child: _buildBalanceCardWidget(c),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceCardWidget(_BalanceCardItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: item.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item.value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.symbol,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: item.onAction,
            child: Row(
              children: [
                Text(
                  item.actionLabel,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. BUY GAME CURRENCY (COINS) =================
  Widget _buildBuyCoinsSection(bool isMobile) {
    final rate = coinsPerGem ?? 10;
    final rateLabel = "1 gem ≈ $rate coins";

    final bundles = [
      {'title': 'Starter Pack', 'gems': 99,  'badge': 'STARTER',   'icon': Icons.stars,             'badgeColor': const Color(0xFF3B82F6)},
      {'title': 'Value Pack',   'gems': 199, 'badge': 'POPULAR',   'icon': Icons.bolt,              'badgeColor': const Color(0xFFF59E0B)},
      {'title': 'Pro Pack',     'gems': 399, 'badge': 'BEST DEAL', 'icon': Icons.diamond,           'badgeColor': const Color(0xFFA855F7)},
      {'title': 'Ultra Pack',   'gems': 599, 'badge': 'MAX COINS', 'icon': Icons.workspace_premium, 'badgeColor': const Color(0xFFEF4444)},
    ].map((b) {
      final gems = b['gems'] as int;
      final coins = _calcCoinsForGems(gems);
      return {
        ...b,
        'coins': coins,
      };
    }).toList();

    return Container(
      key: _buyCoinsSectionKey,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.monetization_on, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Buy Game Currency",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Exchange gems for simulator coins",
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              // Live relation pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.4)),
                ),
                child: Text(
                  rateLabel,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFA855F7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bundles Layout: 2-column Grid on mobile, 4-column Row on web
          if (isMobile)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bundles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.98,
              ),
              itemBuilder: (context, i) {
                final b = bundles[i];
                return _buildBundleCard(
                  title: b['title'] as String,
                  badge: b['badge'] as String,
                  badgeColor: b['badgeColor'] as Color,
                  icon: b['icon'] as IconData,
                  amountText: '+${b['coins']} Coins',
                  priceText: '${b['gems']} Gems',
                  accentColor: const Color(0xFF10B981),
                  onTap: () => _executeExchangeGemsForCoins(
                    gemsSpent: b['gems'] as int,
                    coinsReceived: b['coins'] as int,
                    packTitle: b['title'] as String,
                  ),
                );
              },
            )
          else
            Row(
              children: bundles.map((b) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildBundleCard(
                      title: b['title'] as String,
                      badge: b['badge'] as String,
                      badgeColor: b['badgeColor'] as Color,
                      icon: b['icon'] as IconData,
                      amountText: '+${b['coins']} Coins',
                      priceText: '${b['gems']} Gems',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => _executeExchangeGemsForCoins(
                        gemsSpent: b['gems'] as int,
                        coinsReceived: b['coins'] as int,
                        packTitle: b['title'] as String,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),

          // Custom Pack Calculator (No Spacer, responsive & zero overflow)
          _buildCustomCoinsCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildCustomCoinsCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D212A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune, color: Color(0xFF10B981), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                "Custom Coin Exchange",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                "Enter custom coin amount",
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inputs Row / Column
          if (isMobile)
            Column(
              children: [
                _buildNumberField(
                  controller: _customCoinsCtrl,
                  label: "Coins desired",
                  hint: "e.g. 1500",
                  icon: Icons.monetization_on,
                  iconColor: const Color(0xFF10B981),
                  onChanged: (_) {
                    if (_coinsError != null) setState(() => _coinsError = null);
                    setState(_recalcCustomCoins);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.swap_vert, color: Colors.white38, size: 20),
                ),
                _buildNumberField(
                  controller: _customGemsForCoinsCtrl,
                  label: "Gems needed (≈)",
                  hint: "—",
                  icon: Icons.diamond,
                  iconColor: const Color(0xFFA855F7),
                  isReadOnly: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _customCoinsCtrl,
                    label: "Coins desired",
                    hint: "e.g. 1500",
                    icon: Icons.monetization_on,
                    iconColor: const Color(0xFF10B981),
                    onChanged: (_) {
                      if (_coinsError != null) setState(() => _coinsError = null);
                      setState(_recalcCustomCoins);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.arrow_forward, color: Colors.white38, size: 20),
                ),
                Expanded(
                  child: _buildNumberField(
                    controller: _customGemsForCoinsCtrl,
                    label: "Gems needed (≈)",
                    hint: "—",
                    icon: Icons.diamond,
                    iconColor: const Color(0xFFA855F7),
                    isReadOnly: true,
                  ),
                ),
              ],
            ),

          if (_coinsError != null) ...[
            const SizedBox(height: 6),
            Text(_coinsError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11)),
          ],

          const SizedBox(height: 14),

          // Quick preset buttons (+500, +1000, +5000)
          Row(
            children: [
              Text("Quick: ", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
              _buildPresetChip("+500", 500, () {
                final cur = int.tryParse(_customCoinsCtrl.text) ?? 0;
                _customCoinsCtrl.text = '${cur + 500}';
                _recalcCustomCoins();
              }),
              _buildPresetChip("+1k", 1000, () {
                final cur = int.tryParse(_customCoinsCtrl.text) ?? 0;
                _customCoinsCtrl.text = '${cur + 1000}';
                _recalcCustomCoins();
              }),
              _buildPresetChip("+5k", 5000, () {
                final cur = int.tryParse(_customCoinsCtrl.text) ?? 0;
                _customCoinsCtrl.text = '${cur + 5000}';
                _recalcCustomCoins();
              }),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  final coins = int.tryParse(_customCoinsCtrl.text.trim()) ?? 0;
                  final gems = int.tryParse(_customGemsForCoinsCtrl.text.trim()) ?? 0;
                  if (coins <= 0 || gems <= 0) {
                    setState(() => _coinsError = "Please enter an amount of coins.");
                    return;
                  }
                  _executeExchangeGemsForCoins(
                    gemsSpent: gems,
                    coinsReceived: coins,
                    packTitle: "Custom Pack ($coins Coins)",
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: Text("Exchange", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. BUY GEMS (GEMS WITH MATIC) =================
  Widget _buildBuyGemsSection(bool isMobile) {
    final rate = gemsPerMatic ?? 15.0;
    final rateLabel = "1 MATIC ≈ ${(rate % 1 == 0 ? rate.toInt() : rate.toStringAsFixed(1))} gems";

    final bundles = [
      {'title': 'Starter Gems', 'matic': 99,  'badge': 'STARTER',   'icon': Icons.stars,             'badgeColor': const Color(0xFF3B82F6)},
      {'title': 'Value Gems',   'matic': 199, 'badge': 'POPULAR',   'icon': Icons.bolt,              'badgeColor': const Color(0xFFF59E0B)},
      {'title': 'Pro Gems',     'matic': 399, 'badge': 'HIGH VALUE','icon': Icons.diamond,           'badgeColor': const Color(0xFFA855F7)},
      {'title': 'Ultra Gems',   'matic': 799, 'badge': 'MEGA VAULT','icon': Icons.workspace_premium, 'badgeColor': const Color(0xFFEC4899)},
    ].map((b) {
      final matic = b['matic'] as int;
      final gems = _calcGemsForMatic(matic);
      return {
        ...b,
        'gems': gems,
      };
    }).toList();

    return Container(
      key: _buyGemsSectionKey,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.diamond, color: Color(0xFFA855F7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Buy Simulator Gems",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Top up gems using MATIC cryptocurrency",
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              // Live relation pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                ),
                child: Text(
                  rateLabel,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF60A5FA),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bundles Layout: 2-column Grid on mobile, 4-column Row on web
          if (isMobile)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bundles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.98,
              ),
              itemBuilder: (context, i) {
                final b = bundles[i];
                return _buildBundleCard(
                  title: b['title'] as String,
                  badge: b['badge'] as String,
                  badgeColor: b['badgeColor'] as Color,
                  icon: b['icon'] as IconData,
                  amountText: '+${b['gems']} Gems',
                  priceText: '${b['matic']} MATIC',
                  accentColor: const Color(0xFFA855F7),
                  onTap: () => _executeBuyGemsWithMatic(
                    maticSpent: b['matic'] as int,
                    gemsReceived: b['gems'] as int,
                    packTitle: b['title'] as String,
                  ),
                );
              },
            )
          else
            Row(
              children: bundles.map((b) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildBundleCard(
                      title: b['title'] as String,
                      badge: b['badge'] as String,
                      badgeColor: b['badgeColor'] as Color,
                      icon: b['icon'] as IconData,
                      amountText: '+${b['gems']} Gems',
                      priceText: '${b['matic']} MATIC',
                      accentColor: const Color(0xFFA855F7),
                      onTap: () => _executeBuyGemsWithMatic(
                        maticSpent: b['matic'] as int,
                        gemsReceived: b['gems'] as int,
                        packTitle: b['title'] as String,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),

          // Custom Pack Calculator for Gems
          _buildCustomGemsCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildCustomGemsCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D212A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune, color: Color(0xFFA855F7), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                "Custom Gems Pack",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                "Enter MATIC amount to convert",
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inputs Row / Column
          if (isMobile)
            Column(
              children: [
                _buildNumberField(
                  controller: _customMaticCtrl,
                  label: "MATIC to spend",
                  hint: "e.g. 100",
                  icon: Icons.currency_bitcoin,
                  iconColor: const Color(0xFF3B82F6),
                  onChanged: (_) {
                    if (_gemsError != null) setState(() => _gemsError = null);
                    setState(_recalcCustomGems);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.swap_vert, color: Colors.white38, size: 20),
                ),
                _buildNumberField(
                  controller: _customGemsForMaticCtrl,
                  label: "Gems received (≈)",
                  hint: "—",
                  icon: Icons.diamond,
                  iconColor: const Color(0xFFA855F7),
                  isReadOnly: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _customMaticCtrl,
                    label: "MATIC to spend",
                    hint: "e.g. 100",
                    icon: Icons.currency_bitcoin,
                    iconColor: const Color(0xFF3B82F6),
                    onChanged: (_) {
                      if (_gemsError != null) setState(() => _gemsError = null);
                      setState(_recalcCustomGems);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.arrow_forward, color: Colors.white38, size: 20),
                ),
                Expanded(
                  child: _buildNumberField(
                    controller: _customGemsForMaticCtrl,
                    label: "Gems received (≈)",
                    hint: "—",
                    icon: Icons.diamond,
                    iconColor: const Color(0xFFA855F7),
                    isReadOnly: true,
                  ),
                ),
              ],
            ),

          if (_gemsError != null) ...[
            const SizedBox(height: 6),
            Text(_gemsError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11)),
          ],

          const SizedBox(height: 14),

          // Quick preset buttons (+50, +100, +250)
          Row(
            children: [
              Text("Quick: ", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
              _buildPresetChip("+50", 50, () {
                final cur = int.tryParse(_customMaticCtrl.text) ?? 0;
                _customMaticCtrl.text = '${cur + 50}';
                _recalcCustomGems();
              }),
              _buildPresetChip("+100", 100, () {
                final cur = int.tryParse(_customMaticCtrl.text) ?? 0;
                _customMaticCtrl.text = '${cur + 100}';
                _recalcCustomGems();
              }),
              _buildPresetChip("+250", 250, () {
                final cur = int.tryParse(_customMaticCtrl.text) ?? 0;
                _customMaticCtrl.text = '${cur + 250}';
                _recalcCustomGems();
              }),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {
                  final matic = int.tryParse(_customMaticCtrl.text.trim()) ?? 0;
                  final gems = int.tryParse(_customGemsForMaticCtrl.text.trim()) ?? 0;
                  if (matic <= 0 || gems <= 0) {
                    setState(() => _gemsError = "Please enter an amount of MATIC.");
                    return;
                  }
                  _executeBuyGemsWithMatic(
                    maticSpent: matic,
                    gemsReceived: gems,
                    packTitle: "Custom Gems ($gems Gems)",
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: Text("Buy Gems", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Reusable Field & Chip Builders ---
  Widget _buildBundleCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required String amountText,
    required String priceText,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Badge
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            // Amount
            Text(
              amountText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            // Price Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.4)),
              ),
              child: Text(
                priceText,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    bool isReadOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isReadOnly ? const Color(0xFF14171E) : const Color(0xFF111318),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReadOnly ? Colors.white12 : iconColor.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isReadOnly,
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                  style: GoogleFonts.poppins(
                    color: isReadOnly ? iconColor : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= 4. RECENT TRANSACTIONS / ACTIVITY =================
  Widget _buildRecentTransactionsSection(bool isMobile) {
    final uid = _uid;
    if (uid.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history, color: Color(0xFF60A5FA), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isMobile ? 17 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Simulator currency exchanges & crypto purchases",
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('wallet/$uid/transactions')
                .limitToLast(8)
                .onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFFA855F7), strokeWidth: 2),
                  ),
                );
              }

              final data = snapshot.data?.snapshot.value;
              if (data == null || data is! Map) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: Text(
                    "No transactions recorded yet.",
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                  ),
                );
              }

              final entries = data.entries.toList()
                ..sort((a, b) {
                  final tA = (a.value is Map && (a.value as Map)['timestamp'] != null) ? ((a.value as Map)['timestamp'] as num) : 0;
                  final tB = (b.value is Map && (b.value as Map)['timestamp'] != null) ? ((b.value as Map)['timestamp'] as num) : 0;
                  return tB.compareTo(tA);
                });

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 16),
                itemBuilder: (context, i) {
                  final item = Map<String, dynamic>.from(entries[i].value as Map);
                  final title = item['title']?.toString() ?? 'Simulator Transaction';
                  final type = item['type']?.toString() ?? '';
                  final isCrypto = type.contains('crypto');
                  final txHash = item['txHash']?.toString();
                  final ts = item['timestamp'] is num ? item['timestamp'] as num : 0;
                  final dateStr = ts > 0
                      ? DateFormat('MMM d, yyyy • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ts.toInt()))
                      : '';

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCrypto ? const Color(0xFFA855F7) : const Color(0xFF10B981)).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCrypto ? Icons.diamond : Icons.monetization_on,
                          color: isCrypto ? const Color(0xFFA855F7) : const Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (dateStr.isNotEmpty)
                              Text(
                                dateStr,
                                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                      if (txHash != null && txHash.isNotEmpty)
                        InkWell(
                          onTap: () async {
                            final url = Uri.parse("https://polygonscan.com/tx/$txHash");
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                            ),
                            child: Text(
                              "Tx ↗",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF60A5FA),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String text, int value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _BalanceCardItem {
  final String title;
  final String symbol;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final String actionLabel;
  final VoidCallback onAction;

  _BalanceCardItem({
    required this.title,
    required this.symbol,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.actionLabel,
    required this.onAction,
  });
}
