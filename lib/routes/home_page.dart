import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:image_pickers/image_pickers.dart';
import 'dart:io';
import '../common/db_provider.dart';
import '../models/baby_care.dart';
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

  final DateTime today = DateTime.now();
  final DateTime startDate = DateTime(2023, 1, 1); // 可以根据需求调整起始日期
  late final int totalDays;
  late final int initialPageIndex;

  DateTime currentDate = DateTime.now();

  List<BabyCare> feedRecords = [];

  @override
  void initState() {
    super.initState();
    totalDays = today.difference(startDate).inDays;
    initialPageIndex = totalDays; // 今天的索引
    _pageController = PageController(initialPage: initialPageIndex);
    loadDataForDate(currentDate);
  }

  DateTime _calculateDate(int index) {
    return startDate.add(Duration(days: index));
  }

  Future<void> loadDataForDate(DateTime date) async {
    int start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    int end = start + Duration(days: 1).inMilliseconds;
    List<BabyCare> data = await DBProvider().getCareByRange(start, end);
    setState(() {
      feedRecords = data;
    });
  }

  void _onPageChanged(int index) {
    DateTime newDate = _calculateDate(index);
    setState(() {
      currentDate = newDate;
    });
    loadDataForDate(currentDate);
  }

  void _showMlSelector(FeedType type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('选择毫升数'),
          content: SizedBox(
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
                    _showTimePicker(type, ml.toString());
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showTimePicker(FeedType type, String ml) {
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
          mush: ml,
        );

        BabyCare inserted = await DBProvider().insertCare(care);

        setState(() {
          feedRecords.add(inserted);
        });
      },
    );
  }

  Future<void> _addPoopRecord() async {
    final selectedImages = await ImagePickers.pickerPaths(
      galleryMode: GalleryMode.image,
      selectCount: 3,
      showGif: false,
      showCamera: true,
      compressSize: 500,
      uiConfig: UIConfig(uiThemeColor: Colors.lightGreen),
      cropConfig: CropConfig(enableCrop: false),
    );

    if (selectedImages.isEmpty) return;

    final imagePaths = selectedImages
        .map((e) => e.path ?? '')
        .where((p) => p.isNotEmpty)
        .toList();
    final mush = imagePaths.join(',');
    _showTimePicker(FeedType.poop, mush);
  }

  void _showPoopImages(List<String> imagePaths) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("便便记录"),
        content: SingleChildScrollView(
          child: Column(
            children: imagePaths
                .map((path) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.file(File(path),
                          width: 300, height: 200, fit: BoxFit.cover),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("关闭"),
          ),
        ],
      ),
    );
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
          Expanded(
            flex: 6,
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalDays + 1,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageDate = _calculateDate(index);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        DateUtil.dateToString(pageDate),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 24,
                        itemBuilder: (context, hourIndex) {
                          final hourRecords = feedRecords.where((record) {
                            DateTime recordTime =
                                DateTime.fromMillisecondsSinceEpoch(
                                    record.date!);
                            return recordTime.year == pageDate.year &&
                                recordTime.month == pageDate.month &&
                                recordTime.day == pageDate.day &&
                                recordTime.hour == hourIndex;
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
                              case FeedType.poop:
                                path = 'assets/icons/poop.png';
                                break;
                            }
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Image.asset(path, height: 24, width: 24),
                            );
                          }).toList();

                          return GestureDetector(
                            onTap: () {
                              List<String> allPoopImagePaths = hourRecords
                                  .where((r) => r.type == FeedType.poop)
                                  .expand((r) => r.mush
                                      .split(',')
                                      .where((p) => p.isNotEmpty))
                                  .toList();
                              if (allPoopImagePaths.isNotEmpty) {
                                _showPoopImages(allPoopImagePaths);
                              } else {
                                int milkTotal = hourRecords
                                    .where((r) => r.type == FeedType.milk)
                                    .fold(
                                        0, (sum, r) => sum + int.parse(r.mush));
                                int formulaTotal = hourRecords
                                    .where((r) => r.type == FeedType.formula)
                                    .fold(
                                        0, (sum, r) => sum + int.parse(r.mush));
                                int waterTotal = hourRecords
                                    .where((r) => r.type == FeedType.water)
                                    .fold(
                                        0, (sum, r) => sum + int.parse(r.mush));

                                String content =
                                    '$hourIndex:00 - ${hourIndex + 1}:00';
                                if (milkTotal > 0)
                                  content += ' 母乳: ${milkTotal}ml,';
                                if (formulaTotal > 0)
                                  content += ' 奶粉: ${formulaTotal}ml,';
                                if (waterTotal > 0)
                                  content += ' 水: ${waterTotal}ml,';
                                if (content.endsWith(','))
                                  content =
                                      content.substring(0, content.length - 1);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(content)),
                                );
                              }
                            },
                            child: Container(
                              height: 50,
                              color: Colors.green[100],
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Text(
                                        hourIndex.toString().padLeft(2, '0') +
                                            ':00',
                                        style: const TextStyle(fontSize: 16)),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                    _addPoopRecord();
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
