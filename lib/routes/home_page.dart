import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

import '../models/baby_care.dart';
import '../common/db_provider.dart';
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
  final int initialPage = 10000;
  final DateTime today = DateTime.now();
  DateTime currentDate = DateTime.now();
  int _currentPageIndex = 10000;

  List<BabyCare> feedRecords = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: initialPage);
    loadDataForDate(currentDate);
  }

  DateTime _calculateDate(int pageIndex) {
    int offset = pageIndex - initialPage;
    return today.add(Duration(days: offset));
  }

  Future<void> loadDataForDate(DateTime date) async {
    int targetDate = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    List<BabyCare> list = await DBProvider().getCareByDate(targetDate);
    setState(() {
      feedRecords = list;
    });
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
      onConfirm: (time) async {
        DateTime fullDateTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          time.hour,
          time.minute,
        );

        int timestamp = fullDateTime.millisecondsSinceEpoch;

        BabyCare care = BabyCare(
          date: timestamp,
          type: type,
          mush: ml.toString(),
        );

        BabyCare inserted = await DBProvider().insertCare(care);

        setState(() {
          feedRecords.add(inserted);
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
                loadDataForDate(currentDate);
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
                          final hourRecords = feedRecords.where((record) {
                            DateTime time = DateTime.fromMillisecondsSinceEpoch(record.date!);
                            return time.year == pageDate.year &&
                                time.month == pageDate.month &&
                                time.day == pageDate.day &&
                                time.hour == listIndex;
                          }).toList();

                          final iconWidgets = hourRecords.map((record) {
                            String path;
                            switch (record.type) {
                              case FeedType.milk:
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
                              int milkTotal = hourRecords
                                  .where((r) => r.type == FeedType.milk)
                                  .fold(0, (sum, r) => sum + int.parse(r.mush));
                              int formulaTotal = hourRecords
                                  .where((r) => r.type == FeedType.formula)
                                  .fold(0, (sum, r) => sum + int.parse(r.mush));
                              int waterTotal = hourRecords
                                  .where((r) => r.type == FeedType.water)
                                  .fold(0, (sum, r) => sum + int.parse(r.mush));

                              String content = '${listIndex}:00 - ${listIndex + 1}:00';
                              if (milkTotal > 0) content += ' 母乳: ${milkTotal}ml,';
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
                  onTap: () => _showMlSelector(FeedType.milk),
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
