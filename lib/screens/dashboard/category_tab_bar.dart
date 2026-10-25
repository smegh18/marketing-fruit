import 'package:flutter/material.dart';

class CategoryTabBar extends StatefulWidget {
  const CategoryTabBar({super.key});

  @override
  State<CategoryTabBar> createState() => _CategoryTabBarState();
}

class _CategoryTabBarState extends State<CategoryTabBar> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Published'),
    Tab(text: 'Pending'),
    Tab(text: 'Draft'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: _tabs,
      isScrollable: true,
      labelColor: Colors.black,
      indicatorColor: Colors.blue,
      unselectedLabelColor: Colors.grey,
    );
  }
}
