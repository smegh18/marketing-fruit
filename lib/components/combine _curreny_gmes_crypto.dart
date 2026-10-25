import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Existing components
import 'package:Marketing_Fruit/components/financial_forcast.dart';
import 'package:Marketing_Fruit/components/financial_forecasts_graphs.dart';
import 'package:Marketing_Fruit/components/financial_summary.dart';
import 'package:Marketing_Fruit/components/transaction_history.dart';
import 'package:Marketing_Fruit/components/buy_game_currency.dart';
import 'package:Marketing_Fruit/components/buy_gems.dart';
import 'package:Marketing_Fruit/components/polygon_matic_card.dart';

// Local cards
import 'game_currency_card.dart';
import 'gems_card.dart';

class WalletBalance {
  final num coins;
  final num gems;
  final num poly;

  const WalletBalance({required this.coins, required this.gems, required this.poly});

  static WalletBalance fromMap(Map<dynamic, dynamic> map) {
    final m = Map<String, dynamic>.from(map);
    final coins = _num(m['coins']) ?? _num(m['balance']) ?? 0;
    final gems = _num(m['gems']) ?? 0;
    final poly = _num(m['polyMatic']) ?? _num(m['polygon']) ?? _num(m['poly']) ?? 0;
    return WalletBalance(coins: coins, gems: gems, poly: poly);
  }

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }
}

class WalletRepository {
  final FirebaseDatabase db;
  final String uid;
  WalletRepository({required this.db, required this.uid});

  DatabaseReference get _ref => db.ref('wallet/$uid/balance');

  Stream<WalletBalance> streamBalance() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        return WalletBalance.fromMap(data);
      }
      if (data is num) {
        return WalletBalance(coins: data, gems: 0, poly: 0);
      }
      if (data is String) {
        final n = num.tryParse(data) ?? 0;
        return WalletBalance(coins: n, gems: 0, poly: 0);
      }
      return const WalletBalance(coins: 0, gems: 0, poly: 0);
    });
  }
}

class CurrencyGemsCryptoRow extends StatefulWidget {
  final double cardHeight;
  final EdgeInsets padding;

  const CurrencyGemsCryptoRow({
    super.key,
    this.cardHeight = 160,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<CurrencyGemsCryptoRow> createState() => _CurrencyGemsCryptoRowState();
}

class _CurrencyGemsCryptoRowState extends State<CurrencyGemsCryptoRow> {
  // Keys for scrolling to sections
  final GlobalKey _buyGameCurrencyKey = GlobalKey();
  final GlobalKey _buyGemsKey = GlobalKey();

  void _scrollToKey(GlobalKey key, {double alignment = 0.0}) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: alignment,
      );
    }
  }

  void _scrollToBuyGameCurrency() => _scrollToKey(_buyGameCurrencyKey, alignment: 0.0);
  void _scrollToBuyGems() => _scrollToKey(_buyGemsKey, alignment: 0.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Resolve UID: prefer current user; fall back only in debug
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? (kDebugMode ? '6wlOwtK3bMfhrSs7qsq6CXSwp083' : '');
    final repo = WalletRepository(db: FirebaseDatabase.instance, uid: uid);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double innerWidth = w - widget.padding.horizontal;

        const double gap = 8.0;
        late double cardWidth;
        late MainAxisAlignment rowAlign;

        if (w >= 900) {
          cardWidth = (innerWidth - (2 * gap)) / 3;
          rowAlign = MainAxisAlignment.start;
        } else if (w >= 600) {
          cardWidth = (innerWidth - gap) / 2;
          rowAlign = MainAxisAlignment.start;
        } else {
          cardWidth = innerWidth;
          rowAlign = MainAxisAlignment.start;
        }

        String fmt(num n, {bool kSuffix = true}) {
          if (kSuffix && n.abs() >= 1000) {
            final k = n / 1000;
            final s = k.toStringAsFixed(k % 1 == 0 ? 0 : 1);
            return '$s' 'k';
          }
          final isInt = n % 1 == 0;
          return isInt ? n.toInt().toString() : n.toStringAsFixed(1);
        }

        return Container(
          color: theme.cardColor,
          child: Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Finance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: widget.cardHeight,
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      scrollbars: false,
                    ),
                    child: StreamBuilder<WalletBalance>(
                      stream: repo.streamBalance(),
                      builder: (context, snapshot) {
                        final hasError = snapshot.hasError;
                        final hasData = snapshot.hasData;
                        final loading = snapshot.connectionState == ConnectionState.waiting && !hasData;
                        final balance = snapshot.data ?? const WalletBalance(coins: 0, gems: 0, poly: 0);

                        if (hasError) {
                          return Center(
                            child: Text(
                              'Unable to load balances',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const PageScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: w),
                            child: Row(
                              mainAxisAlignment: rowAlign,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: GameCurrencyCard(
                                    balanceText: loading ? '...' : fmt(balance.coins, kSuffix: true),
                                    height: widget.cardHeight,
                                    onBuyNow: _scrollToBuyGameCurrency,
                                  ),
                                ),
                                const SizedBox(width: gap),
                                SizedBox(
                                  width: cardWidth,
                                  child: GemsCard(
                                    balanceText: loading ? '...' : fmt(balance.gems, kSuffix: false),
                                    height: widget.cardHeight,
                                    onBuyMore: _scrollToBuyGems,
                                  ),
                                ),
                                const SizedBox(width: gap),
                                SizedBox(
                                  width: cardWidth,
                                  child: PolyMaticCard(
                                    balanceText: loading ? '...' : fmt(balance.poly, kSuffix: false),
                                    height: widget.cardHeight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  color: theme.cardColor,
                  child: FinancialSummarySection(width: w),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  color: theme.cardColor,
                  child: FinancialForecastSection(width: w),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  color: theme.cardColor,
                  child: FinancialPerformanceGraphs(width: w),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  color: theme.cardColor,
                  child: TransactionHistorySection(width: w),
                ),

                const SizedBox(height: 32),

                Container(
                  key: _buyGameCurrencyKey, // scroll target for Game Currency
                  width: double.infinity,
                  color: theme.cardColor,
                  child: BuyGameCurrencySection(width: w),
                ),

                const SizedBox(height: 32),

                Container(
                  key: _buyGemsKey, // scroll target for Gems
                  width: double.infinity,
                  color: theme.cardColor,
                  child: BuyGemsSection(width: w),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
