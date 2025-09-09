import 'package:baby_care_demo/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dtp;
import '../common/db_provider.dart';
import '../models/baby.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

class AddBabyPage extends StatefulWidget {
  @override
  _AddBabyPageState createState() => _AddBabyPageState();
}

class _AddBabyPageState extends State<AddBabyPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = "Male"; // 默认选择男
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    // 根据当前主题模式设置日期选择器的主题
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    dtp.DatePicker.showDatePicker(
      context,
      locale: _mapLocaleToPickerLocale(Localizations.localeOf(context)),
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        setState(() {
          _selectedDate = date;
        });
      },
      currentTime: _selectedDate ?? DateTime.now(),
      theme: dtp.DatePickerTheme(
        backgroundColor: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
        headerColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.lightGreen,
        doneStyle: TextStyle(
          color: isDarkMode ? Colors.lightGreenAccent : Colors.white,
          fontSize: 16,
        ),
        cancelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.white,
          fontSize: 16,
        ),
        itemStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : const Color(0xFF2D2D2D),
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final s = S.of(context);
    String name = _nameController.text.trim();

    if (name.isEmpty || _selectedDate == null) {
      ToastUtil.showToast(s?.pleaseEnterCompleteInformation ?? 'Please enter complete information');
      return;
    }

    int sexValue = _selectedGender == "Male" ? 1 : 0; // 1 = 男, 0 = 女

    // 检查数据库是否已有重复宝宝
    List<Baby>? allBabies = await DBProvider().queryAllPersons();
    bool duplicateExists = allBabies?.any((baby) =>
    baby.name == name &&
        baby.sex == sexValue &&
        baby.birthdate.year == _selectedDate!.year &&
        baby.birthdate.month == _selectedDate!.month &&
        baby.birthdate.day == _selectedDate!.day) ?? false;

    if (duplicateExists) {
      ToastUtil.showToast(s?.thisBabyAlreadyExists ?? 'This baby already exists');
      return;
    }

    try {

      if (allBabies != null && allBabies.isNotEmpty) {
        for (Baby baby in allBabies) {
          if (baby.id != null) {
            await DBProvider().clearAllShow();
          }
        }
      }

      // 创建新宝宝，设置 show 为 1（成为活跃宝宝）
      Baby newBaby = Baby(
          name: name,
          sex: sexValue,
          birthdate: _selectedDate!,
          show: 1
      );

      // 插入数据库
      await DBProvider().insertPerson(newBaby);


      if (Navigator.canPop(context)) {
        // 如果是从 DrawerPage 导航过来的，返回并传递更新标志
        Navigator.pop(context, true);
      } else {
        // 如果是应用启动时直接进入的，导航到主页
        Navigator.pushReplacementNamed(context, '/main');
      }

      // 成功提示
      ToastUtil.showToast(s?.babyAddedSuccessfully ?? 'Baby added successfully!');

    } catch (e) {
      debugPrint('Error adding baby: $e');
      ToastUtil.showToast(s?.failedToAddBaby ?? 'Failed to add baby');
    }
  }


  dtp.LocaleType _mapLocaleToPickerLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'zh': // 中文
        return dtp.LocaleType.zh;
      default:   // 默认英文
        return dtp.LocaleType.en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 点击空白处关闭键盘
      child: Scaffold(
        appBar: AppBar(
          title: Text(s?.addBabyInformation ?? 'Add Baby Information'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 2,
        ),
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300), // 限制最大宽度
              child: Column(
                mainAxisSize: MainAxisSize.min, // 改为最小尺寸
                children: [
                  // 输入框容器，小巧精致
                  Container(
                    padding: const EdgeInsets.all(16), // 减小内边距
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 名字输入框 - 小巧版
                        SizedBox(
                          width: 200, // 固定宽度
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center, // 文字居中
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: s?.name ?? "Name",
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.lightGreenAccent
                                    : Colors.lightGreen,
                                fontSize: 12,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.lightGreenAccent.withOpacity(0.3)
                                      : Colors.lightGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.lightGreenAccent
                                      : Colors.lightGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 性别选择 - 小巧版
                        Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s?.gender ?? "Gender",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 男
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: "Male",
                                    groupValue: _selectedGender,
                                    activeColor: isDarkMode
                                        ? Colors.lightGreenAccent
                                        : Colors.lightGreen,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    s?.male ?? "Male",
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                              // 女
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: "Female",
                                    groupValue: _selectedGender,
                                    activeColor: isDarkMode
                                        ? Colors.lightGreenAccent
                                        : Colors.lightGreen,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    s?.female ?? "Female",
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 出生日期选择按钮 - 小巧版
                        SizedBox(
                          width: 180, // 固定较小宽度
                          height: 36,  // 固定较小高度
                          child: ElevatedButton(
                            onPressed: _selectDate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Colors.lightGreenAccent
                                  : Colors.lightGreen,
                              foregroundColor: isDarkMode
                                  ? Colors.black
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? (s?.selectBirthday ?? "Select Birthday")
                                  : "${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 提交按钮 - 小巧版
                  SizedBox(
                    width: 120, // 固定较小宽度
                    height: 40,  // 固定较小高度
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.lightGreenAccent
                            : Colors.lightGreen,
                        foregroundColor: isDarkMode
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        s?.submit ?? "Submit",
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}