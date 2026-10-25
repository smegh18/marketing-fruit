import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/dashboard/admin_landing.dart';


class AdminDashboardScreen extends StatelessWidget {
  final void Function()? onAddNFT;
  final void Function(String txnHash)? onTxnTap;
  final void Function(Map<String, dynamic> nft)? onNftTap;
  final void Function(String role)? onStatCardTap;

  const AdminDashboardScreen({super.key, this.onAddNFT, required this.onTxnTap, this.onNftTap, this.onStatCardTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DashboardPage(
          onStatCardTap: onStatCardTap,
        );
      },
    );
  }
}

