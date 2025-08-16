import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:image_pickers/image_pickers.dart';
import 'dart:io';
import '../common/db_provider.dart';
import '../models/baby.dart';
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
  final DateTime startDate = DateTime(2024, 6, 4); // 可按需调整
  late final int totalDays;
  late final int initialPageIndex;

  /// currentDate 表示 PageView 当前选中的日期（仅日期部分有效）
  late DateTime currentDate;

  int? _currentBabyId; // 当前显示的宝宝ID

  /// 数据缓存：以当天 00:00:00 的毫秒数作为 key，value 是那天的记录列表
  final Map<int, List<BabyCare>> _recordsCache = {};

  @override
  void initState() {
    super.initState();
    totalDays = today.difference(startDate).inDays;
    initialPageIndex = totalDays; // 今天的索引
    _pageController = PageController(initialPage: initialPageIndex);

    // 初始 currentDate 为初始页对应的日期（避免依赖 onPageChanged）
    currentDate = _calculateDate(initialPageIndex);

    // 加载当前 babyId 并预加载 initial date 的数据
    _loadCurrentBabyAndData();
  }

  /// 获取当前 babyId 并加载 initial date 的数据
  Future<void> _loadCurrentBabyAndData() async {
    List<Baby>? visibleBabies = await DBProvider().getVisiblePersons();
    if (visibleBabies != null && visibleBabies.isNotEmpty) {
      Baby baby = visibleBabies.firstWhere((b) => b.show == 1, orElse: () => visibleBabies.first);
      _currentBabyId = baby.id;
      await _loadDataForDateIntoCache(currentDate);
      setState(() {}); // 触发 UI 更新（初始页面可能需要显示刚加载的数据）
    }
  }

  DateTime _calculateDate(int index) {
    return startDate.add(Duration(days: index));
  }

  /// 返回当天 00:00:00 的毫秒数（用于缓存 key）
  int _startOfDayMillis(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.millisecondsSinceEpoch;
  }

  /// 从 DB 加载某天的数据并放入缓存（覆盖）
  Future<void> _loadDataForDateIntoCache(DateTime date) async {
    if (_currentBabyId == null) return;
    int start = _startOfDayMillis(date);
    int end = start + Duration(days: 1).inMilliseconds;
    List<BabyCare> data = await DBProvider().getCareByRange(start, end, _currentBabyId ?? 0);
    _recordsCache[start] = data;
  }

  /// 获取缓存中某天的数据（若未缓存则返回空列表）
  List<BabyCare> _getCachedRecordsForDate(DateTime date) {
    final key = _startOfDayMillis(date);
    return _recordsCache[key] ?? [];
  }

  /// 当 PageView 切页时触发：更新 currentDate，若该日期未缓存则加载
  void _onPageChanged(int index) {
    DateTime newDate = _calculateDate(index);
    setState(() {
      currentDate = newDate;
    });

    final key = _startOfDayMillis(newDate);
    if (!_recordsCache.containsKey(key)) {
      // 异步加载并在完成后刷新 UI
      _loadDataForDateIntoCache(newDate).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// 选择 ml（10 ~ 250）并选择时间（时间选择器会使用 currentDate 的日期）
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

  /// 时间选择器：选择时间后插入记录并更新缓存（注意：插入记录会以 currentDate 的日期为基准）
  void _showTimePicker(FeedType type, String mush) {
    // 使用 currentDate 作为日期基础（currentDate 已在切页时设置）
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
          babyId: _currentBabyId ?? 0,
          date: timestamp,
          type: type,
          mush: mush,
        );

        BabyCare inserted = await DBProvider().insertCare(care);

        // 将插入的记录加入对应日期缓存（如果缓存不存在则创建）
        final key = _startOfDayMillis(fullDateTime);
        final list = _recordsCache.putIfAbsent(key, () => []);
        list.add(inserted);

        // 如果当前页面就是插入记录的那天，则刷新 UI。
        if (key == _startOfDayMillis(currentDate)) {
          setState(() {});
        }
      },
    );
  }

  /// 便便记录，允许选择最多 3 张图片，拼接路径并调用时间选择器
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
    if (imagePaths.isEmpty) return;

    final mush = imagePaths.join(','); // 便便用 mush 存储图片路径的逗号连接字符串

    // 使用 time picker 来选择时间（会最终调用插入函数）
    _showTimePicker(FeedType.poop, mush);
  }

  /// 弹出便便图片预览（单独使用的预览），标题颜色为绿色
  void _showPoopImages(List<String> imagePaths) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('便便记录', style: const TextStyle(color: Colors.green)),
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

  /// helper: 根据 hourIndex 与页面日期从缓存中筛选出该小时的记录
  List<BabyCare> _hourRecordsForPageDate(DateTime pageDate, int hourIndex) {
    final all = _getCachedRecordsForDate(pageDate);
    return all.where((record) {
      if (record.date == null) return false;
      DateTime recordTime = DateTime.fromMillisecondsSinceEpoch(record.date!);
      return recordTime.year == pageDate.year &&
          recordTime.month == pageDate.month &&
          recordTime.day == pageDate.day &&
          recordTime.hour == hourIndex;
    }).toList();
  }

  /// 点击小时行时显示 Dialog（标题颜色为绿色）
  void _showHourDetailDialog(DateTime pageDate, int hourIndex, List<BabyCare> hourRecords) {
    // 计算三种液体总量（若没有记录则为 0）
    int milkTotal = hourRecords
        .where((r) => r.type == FeedType.milk)
        .fold(0, (sum, r) {
      final v = int.tryParse(r.mush) ?? 0;
      return sum + v;
    });
    int formulaTotal = hourRecords
        .where((r) => r.type == FeedType.formula)
        .fold(0, (sum, r) {
      final v = int.tryParse(r.mush) ?? 0;
      return sum + v;
    });
    int waterTotal = hourRecords
        .where((r) => r.type == FeedType.water)
        .fold(0, (sum, r) {
      final v = int.tryParse(r.mush) ?? 0;
      return sum + v;
    });

    // 聚合所有便便图片路径
    List<String> allPoopImagePaths = hourRecords
        .where((r) => r.type == FeedType.poop)
        .expand((r) => r.mush.split(',').where((p) => p.isNotEmpty))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        final double dialogWidth = MediaQuery.of(ctx).size.width * 0.8; // 屏幕宽度的 4/5
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: dialogWidth,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题：小时范围，保留绿色字体
                    Text(
                      '${hourIndex.toString().padLeft(2, '0')}:00 - ${(hourIndex + 1).toString().padLeft(2, '0')}:00',
                      style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // 三种液体总量
                    Text('母乳: ${milkTotal} ml', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('奶粉: ${formulaTotal} ml', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('水: ${waterTotal} ml', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),

                    const Divider(),
                    const SizedBox(height: 8),

                    // 便便部分标题
                    const Text('便便:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // 便便图片或提示
                    // 便便图片或提示
                    if (allPoopImagePaths.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('无便便记录'),
                      )
                    else
                      Column(
                        children: allPoopImagePaths.map((path) {
                          return GestureDetector(
                            onTap: () {
                              // 点击缩略图打开单张大图预览（白色背景）
                              showDialog(
                                context: context,
                                builder: (_) {
                                  return Dialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (path.isNotEmpty)
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.9,
                                                maxHeight: MediaQuery.of(context).size.height * 0.7,
                                              ),
                                              child: Image.file(File(path), fit: BoxFit.contain),
                                            ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text(
                                              '关闭',
                                              style: TextStyle(color: Colors.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity, // 占满宽度
                              height: 150,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: path.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(File(path), fit: BoxFit.cover),
                              )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }).toList(),
                      ),


                    const SizedBox(height: 12),
                    // 关闭按钮，靠右
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          '关闭',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
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
              itemCount: totalDays + 1,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final pageDate = _calculateDate(index);

                // 页面构建时从缓存里拿数据（若还没加载，则为空）
                final pageRecords = _getCachedRecordsForDate(pageDate);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        DateUtil.dateToString(pageDate),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: 24,
                        separatorBuilder: (context, index) => Container(
                          height: 1,
                          color: Colors.green, // 分隔条绿色
                        ),
                        itemBuilder: (context, hourIndex) {
                          final hourRecords = _hourRecordsForPageDate(pageDate, hourIndex);

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
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Image.asset(path, height: 24, width: 24),
                            );
                          }).toList();

                          return GestureDetector(
                            onTap: () {
                              _showHourDetailDialog(pageDate, hourIndex, hourRecords);
                            },
                            child: Container(
                              height: 50,
                              color: Colors.white, // 每个小时的背景白色
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                      hourIndex.toString().padLeft(2, '0') + ':00',
                                      style: const TextStyle(fontSize: 16),
                                    ),
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
