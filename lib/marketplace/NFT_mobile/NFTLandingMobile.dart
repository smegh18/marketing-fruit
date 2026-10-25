import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/marketplace/NFT_Profile.dart';
import 'package:Marketing_Fruit/marketplace/NFT_mobile/NFTdetailmobile.dart';
import 'package:Marketing_Fruit/marketplace/NFT_mobile/TrendingSectionMobile.dart';
import 'package:Marketing_Fruit/marketplace/NFT_mobile/nftmarketplacemobile.dart';
import 'package:Marketing_Fruit/marketplace/NFT_mobile/subscribewidgetmobile.dart';
import 'package:Marketing_Fruit/marketplace/NFT_mobile/topcreatorsmobile.dart';
import 'BrowseCategoreisMobile.dart';
import 'NFTLadningMobileHeroSection.dart'; // Update import path as needed

class NFTLandingMobilePage extends StatefulWidget {
  const NFTLandingMobilePage({super.key});

  @override
  State<NFTLandingMobilePage> createState() => _NFTLandingMobilePageState();
}

class _NFTLandingMobilePageState extends State<NFTLandingMobilePage> {
  bool marketplace = false;
  bool nftProfile = false;
  String nftid = "";
  void _navigateToMarketplace(BuildContext context) {
    setState(() {
      marketplace = true;
      nftProfile = false;
    });
  }

  void _onNFTTap(String nftId) {
    print(nftId);
    setState(() {
      marketplace = true;
      nftProfile = true;
      nftid = nftId;
    });
  }

  @override
  Widget build(BuildContext context) {
    nftProfile ? print("NFT ID: $nftid") : print("None");
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: SafeArea(
        child: marketplace ? nftProfile ?  NFTDetailMobileScreen(nftId: nftid,onTxnTap: _onNFTTap,) : NFTMarketplaceMobilePage(onNFTTap: _onNFTTap,) : SingleChildScrollView(
          child: Column(
            children: [
              NFTMobileHeroSection(
                onGetStarted: () => _navigateToMarketplace(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: TrendingSectionMobile(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: TopCreatorsMobile(onViewRankings: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NftProfileScreen()),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: BrowseCategoriesMobile(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: SubscribeWidgetMobile(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
