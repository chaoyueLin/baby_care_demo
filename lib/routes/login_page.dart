import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dtp;
import '../common/db_provider.dart';
import '../models/baby.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = "男"; // 默认选择男
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    // 根据当前主题模式设置日期选择器的主题
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    dtp.DatePicker.showDatePicker(
      context,
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
      ),
    );
  }

  Future<void> _submit() async {
    String name = _nameController.text.trim();

    if (name.isEmpty || _selectedDate == null) {
      Fluttertoast.showToast(
        msg:  "请输入完整信息",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    int sexValue = _selectedGender == "男" ? 1 : 0; // 1 = 男, 0 = 女

    // 创建 Baby 对象
    Baby newBaby = Baby(
        name: name,
        sex: sexValue,
        birthdate: _selectedDate!,
        show: 1
    );

    // 插入数据库
    await DBProvider().insertPerson(newBaby);

    // 跳转到主页面
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 点击空白处关闭键盘
      child: Scaffold(
        appBar: AppBar(
          title: Text('登录'),
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
                              labelText: "名字",
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
                                "性别",
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
                                    value: "男",
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
                                    "男",
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                              // 女
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: "女",
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
                                    "女",
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
                                  ? "选择生日"
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
                      child: const Text(
                        "提交",
                        style: TextStyle(
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