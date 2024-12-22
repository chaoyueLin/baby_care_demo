import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomePageContent();
  }
}

class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  late PageController _pageController;
  final int initialPage = 10000; // 设置初始页面索引
  final DateTime today = DateTime.now(); // 当前日期

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: initialPage);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  DateTime _calculateDate(int pageIndex) {
    int offset = pageIndex - initialPage; // 根据页面索引计算日期偏移
    return today.add(Duration(days: offset));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 顶部的日期视图部分
          Expanded(
            flex: 6, // 占据 6/10 的屏幕高度
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                DateTime date = _calculateDate(index);
                return Column(
                  children: [
                    // 日期标题
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _formatDate(date),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // 日期对应的 ListView
                    Expanded(
                      child: ListView.builder(
                        itemCount: 24,
                        itemBuilder: (context, listIndex) {
                          return Container(
                            height: 50,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: listIndex.isEven ? Colors.blue[100] : Colors.blue[200],
                            child: Center(
                              child: Text(
                                'Item ${listIndex + 1}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // 底部固定的 tab 按钮部分
          Container(
            height: 100, // 固定高度
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomTabButton(
                  label: "母乳",
                  iconPath: 'assets/icons/mother_milk.png',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('母乳按钮被点击')));
                  },
                ),
                CustomTabButton(
                  label: "奶粉",
                  iconPath: 'assets/icons/formula_milk.png',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('奶粉按钮被点击')));
                  },
                ),
                CustomTabButton(
                  label: "水",
                  iconPath: 'assets/icons/water.png',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('水按钮被点击')));
                  },
                ),
                CustomTabButton(
                  label: "便便",
                  iconPath: 'assets/icons/poop.png',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('便便按钮被点击')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTabButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;

  const CustomTabButton({
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
