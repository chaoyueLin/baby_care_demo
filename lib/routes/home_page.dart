import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

import '../utils/date_util.dart';
import '../widget/custom_tab_button.dart';

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
  DateTime currentDate = DateTime.now(); // 当前日期
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: initialPage);
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

  void _showTimePicker() {
    DatePicker.showTimePicker(
      context,
      showSecondsColumn: false, // 只显示小时和分钟
      currentTime: currentDate, // 默认当前时间
      onConfirm: (time) {
        setState(() {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(DateUtil.dateToString(time,format: 'yyyy-MM-dd HH:mm:ss'))));
        });
      },
    );
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
                currentDate = _calculateDate(index);
                return Column(
                  children: [
                    // 日期标题
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        DateUtil.dateToString(currentDate),
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
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
                            color: listIndex.isEven
                                ? Colors.blue[100]
                                : Colors.blue[200],
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
                  label: S.of(context)?.breastMilk ?? "breastMilk",
                  iconPath: 'assets/icons/mother_milk.png',
                  onTap: () {
                    _showTimePicker();
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.formula ?? "formula",
                  iconPath: 'assets/icons/formula_milk.png',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('奶粉按钮被点击')));
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.water ?? "water",
                  iconPath: 'assets/icons/water.png',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('水按钮被点击')));
                  },
                ),
                CustomTabButton(
                  label: S.of(context)?.poop ?? "poop",
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
