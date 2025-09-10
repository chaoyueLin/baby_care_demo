import 'package:baby_care_demo/utils/date_util.dart';
import 'package:baby_care_demo/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

import '../common/db_provider.dart';
import '../models/baby.dart';
import '../utils/theme_mode_notifier.dart';
import '../utils/baby_notifier.dart';
import 'care_page.dart';
import 'data_page.dart';
import 'setting_page.dart';
import 'grow_page.dart';
import 'add_baby_page.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({Key? key}) : super(key: key);

  @override
  _DrawerPageState createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;
  int _selectedBabyIndex = 0;
  List<Baby> _babies = [];
  bool _isLoading = true;

  // Page configuration（注意：care 页用 KeyedSubtree 包一层动态 Key）
  late List<PageConfig> _pageConfigs = [
    PageConfig(Icons.home, 'care', () => KeyedSubtree(key: UniqueKey(), child: CarePage())),
    PageConfig(Icons.analytics, 'recent', () => KeyedSubtree(key: UniqueKey(), child: DataPage())),
    PageConfig(Icons.trending_up, 'grow', () => KeyedSubtree(key: UniqueKey(), child: GrowPage())),
    PageConfig(Icons.settings, 'setting', () =>  SettingsPage(onDeleted: () {
      _loadBabies();
    },)),
  ];


  List<Widget> get _pages => _pageConfigs.map((config) => config.pageBuilder()).toList();

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  Future<void> _loadBabies() async {
    try {
      final babies = await DBProvider().queryAllPersons();
      _babies = babies ?? [];


      if (_babies.isNotEmpty) {
        final idx = _babies.indexWhere((b) => (b.show ?? 0) == 1);
        _selectedBabyIndex = idx >= 0 ? idx : 0;

        // 同步到全局 BabyNotifier（可选，但推荐）
        final current = _babies[_selectedBabyIndex];
        if (mounted) {
          context.read<BabyNotifier>().setBaby(current);
        }
      }

      _isLoading = false;



      if (mounted) setState(() {});
    } catch (e) {
      _isLoading = false;
      if (mounted) setState(() {});
      debugPrint('Error loading babies: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    final DateTime now = DateTime.now();
    const Duration exitTimeWindow = Duration(seconds: 2);

    if (_lastPressedAt == null || now.difference(_lastPressedAt!) > exitTimeWindow) {
      _lastPressedAt = now;
      _showExitToast();
      return false;
    }

    SystemNavigator.pop();
    return true;
  }

  void _showExitToast() {

    ToastUtil.showToast(S.of(context)?.exitPrompt ?? "Press again to exit");
  }

  String _getCurrentPageTitle() {
    final localizations = S.of(context);
    switch (_currentIndex) {
      case 0: return localizations?.care ?? "Care";
      case 1: return localizations?.recent ?? "Data";
      case 2: return localizations?.grow ?? "Grow";
      case 3: return localizations?.setting ?? "Settings";
      default: return "BabyCare";
    }
  }


// 修改 DrawerPage 中的导航方法
  void _navigateToLogin() async {
    // 导航到 AddBabyPage 并等待返回结果
    final result = await Navigator.pushNamed(context, '/addBaby');

    // 如果返回结果表示有数据更新，则刷新宝宝列表
    if (result == true && mounted) {
      await _loadBabies(); // 重新加载宝宝列表
    }
  }

  Baby? get currentBaby {
    if (_babies.isNotEmpty && _selectedBabyIndex < _babies.length) {
      return _babies[_selectedBabyIndex];
    }
    return null;
  }

  Future<void> _switchToBaby(int index) async {
    if (index < 0 || index >= _babies.length) return;
    final baby = _babies[index];
    if (baby.id == null) return;

    try {
      // --- 更新 DB：把该 baby 的 show 设为 1，其它设为 0 ---
      // 建议在 DBProvider 中实现 setActiveBaby(int babyId)
      // （若没有此方法，可参考下方“DBProvider 建议实现”）
      await DBProvider().setActiveBaby(baby.id!);

      // 本地状态与全局状态同步
      _selectedBabyIndex = index;
      if (mounted) {
        // 同步到全局 BabyNotifier（可选，但有利于其他页面联动）
        context.read<BabyNotifier>().setBaby(baby);
      }

      // --- 强制 CarePage 重建：让它走 initState 按 show==1 重新拉取 ---
      _pageConfigs = [
        PageConfig(Icons.home, 'care', () => KeyedSubtree(key: UniqueKey(), child: CarePage())),
        PageConfig(Icons.analytics, 'recent', () => KeyedSubtree(key: UniqueKey(), child: DataPage())),
        PageConfig(Icons.trending_up, 'grow', () => KeyedSubtree(key: UniqueKey(), child: GrowPage())),
        PageConfig(Icons.settings, 'setting', () =>  SettingsPage(onDeleted: () {
            _loadBabies();
        },)),
      ];


      if (mounted) setState(() {});
      Navigator.pop(context); // 关闭 Drawer
    } catch (e) {
      debugPrint('Switch baby failed: $e');
      ToastUtil.showToast('Switch baby failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getCurrentPageTitle()),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 2,
        ),
        drawer: _buildDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          if (!_isLoading) _buildBabyListSection(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _pageConfigs.length,
              itemBuilder: (context, index) => _buildDrawerItem(index),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(color: Colors.lightGreen),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "BabyCare",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  S.of(context)?.babyGrowthRecord ??"Baby Growth Record",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                    Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBabyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "No babies added yet",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // 修改 _buildBabyCard 方法
  Widget _buildBabyCard(int index) {
    final baby = _babies[index];
    final isSelected = _selectedBabyIndex == index;

    return Container(
      width: 180, // 宽度改为原来的两倍
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _switchToBaby(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            )
                : Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [

              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(_formatSex(baby)),
              ),
              const SizedBox(width: 12),
              // 右边的信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 名字
                    Text(
                      baby.name ?? 'Unnamed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 生日
                    Text(
                      _formatBirthday(baby.birthdate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 添加格式化生日的辅助方法
  String _formatBirthday(DateTime date) {
    return DateUtil.dateToString(date);
  }

  String _formatSex(Baby baby) {
    if(baby.sex==1){
        return 'M';
    }
    return 'F';
  }

// 同时修改 _buildBabyListSection 中的高度
  Widget _buildBabyListSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context)?.babies ??"My Babies",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100, // 保持现有高度，或者可以稍微调整为 110
            child: _babies.isEmpty
                ? _buildEmptyBabyState()
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _babies.length + 1,
              itemBuilder: (context, index) {
                if (index == _babies.length) {
                  return _buildAddBabyButton();
                }
                return _buildBabyCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBabyButton() {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: _navigateToLogin,
        child: Container(
          decoration: BoxDecoration(
            color:
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.add,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index) {
    final config = _pageConfigs[index];
    final localizations = S.of(context);
    final isSelected = _currentIndex == index;

    String title;
    switch (index) {
      case 0:
        title = localizations?.care ?? "Care";
        break;
      case 1:
        title = localizations?.recent ?? "Data";
        break;
      case 2:
        title = localizations?.grow ?? "Grow";
        break;
      case 3:
        title = localizations?.setting ?? "Settings";
        break;
      default:
        title = "Unknown";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          config.icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor:
        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () => _navigateToPage(index),
      ),
    );
  }

  void _navigateToPage(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
    Navigator.pop(context);
  }
}

class PageConfig {
  final IconData icon;
  final String keyStr;
  final Widget Function() pageBuilder;

  PageConfig(this.icon, this.keyStr, this.pageBuilder);
}
