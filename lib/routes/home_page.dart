import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

import '../utils/date_util.dart';
import '../widget/custom_tab_button.dart';

enum FeedType { breastMilk, formula, water }

class FeedRecord {
  final DateTime time;
  final int ml;
  final FeedType type;

  FeedRecord({required this.time, required this.ml, required this.type});
}

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
  final DateTime today = DateTime.now();
  DateTime currentDate = DateTime.now();
  int _currentPageIndex = 10000;

  List<FeedRecord> feedRecords = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: initialPage);
  }

  DateTime _calculateDate(int pageIndex) {
    int offset = pageIndex - initialPage;
    return today.add(Duration(days: offset));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showMlSelector(FeedType type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('选择毫升数'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: 25,
              itemBuilder: (context, index) {
                int ml = (index + 1) * 10;
                return ListTile(
                  title: Text('$ml ml'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showTimePicker(type, ml);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showTimePicker(FeedType type, int ml) {
    DatePicker.showTimePicker(
      context,
      showSecondsColumn: false,
      currentTime: currentDate,
      onConfirm: (time) {
        setState(() {
          feedRecords.add(FeedRecord(time: time, ml: ml, type: type));
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                  currentDate = _calculateDate(index);
                });
              },
              itemBuilder: (context, index) {
                final pageDate = _calculateDate(index);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        DateUtil.dateToString(pageDate),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 24,
                        itemBuilder: (context, listIndex) {
                          final hourRecords = feedRecords.where((record) =>
                          record.time.year == pageDate.year &&
                              record.time.month == pageDate.month &&
                              record.time.day == pageDate.day &&
                              record.time.hour == listIndex
                          ).toList();

                          final iconWidgets = hourRecords.map((record) {
                            String path;
                            switch (record.type) {
                              case FeedType.breastMilk:
                                path = 'assets/icons/mother_milk.png';
                                break;
                              case FeedType.formula:
                                path = 'assets/icons/formula_milk.png';
                                break;
                              case FeedType.water:
                                path = 'assets/icons/water.png';
                                break;
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Image.asset(path, height: 24, width: 24),
                            );
                          }).toList();

                          return GestureDetector(
                            onTap: () {
                              int breastMilkTotal = hourRecords
                                  .where((r) => r.type == FeedType.breastMilk)
                                  .fold(0, (sum, r) => sum + r.ml);
                              int formulaTotal = hourRecords
                                  .where((r) => r.type == FeedType.formula)
                                  .fold(0, (sum, r) => sum + r.ml);
                              int waterTotal = hourRecords
                                  .where((r) => r.type == FeedType.water)
                                  .fold(0, (sum, r) => sum + r.ml);

                              String content = '${listIndex}:00 - ${listIndex + 1}:00';
                              if (breastMilkTotal > 0) content += ' 母乳: ${breastMilkTotal}ml,';
                              if (formulaTotal > 0) content += ' 奶粉: ${formulaTotal}ml,';
                              if (waterTotal > 0) content += ' 水: ${waterTotal}ml,';
                              if (content.endsWith(',')) content = content.substring(0, content.length - 1);

                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(content))
                              );
                            },
                            child: Container(
                              height: 50,
                              color: Colors.green[100],
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text('${listIndex.toString().padLeft(2, '0')}:00', style: TextStyle(fontSize: 16)),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: iconWidgets,
                                    ),
                                  ),
                                ],
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
          Container(
            height: 100,
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomTabButton(
                  label: S.of(context)?.breastMilk ?? "breastMilk",
                  iconPath: 'assets/icons/mother_milk.png',
                  onTap: () => _showMlSelector(FeedType.breastMilk),
                ),
                CustomTabButton(
                  label: S.of(context)?.formula ?? "formula",
                  iconPath: 'assets/icons/formula_milk.png',
                  onTap: () => _showMlSelector(FeedType.formula),
                ),
                CustomTabButton(
                  label: S.of(context)?.water ?? "water",
                  iconPath: 'assets/icons/water.png',
                  onTap: () => _showMlSelector(FeedType.water),
                ),
                CustomTabButton(
                  label: S.of(context)?.poop ?? "poop",
                  iconPath: 'assets/icons/poop.png',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('便便按钮被点击')),
                    );
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
