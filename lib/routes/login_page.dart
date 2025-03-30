import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dtp;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = "男"; // 默认选择男
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
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
      locale: dtp.LocaleType.zh,
    );
  }

  Future<void> _submit() async {
    String name = _nameController.text.trim();

    if (name.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("请输入完整信息")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", name);
    await prefs.setString("gender", _selectedGender);
    await prefs.setString("birthdate", _selectedDate!.toIso8601String());

    Navigator.pushReplacementNamed(context, '/main'); // 跳转主页面
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 点击空白处关闭键盘
      child: Scaffold(
        appBar: AppBar(title: Text("输入信息")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "名字"),
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 20),

              // 性别选择
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("性别: "),
                  Row(
                    children: [
                      Radio(
                        value: "男",
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value.toString();
                          });
                        },
                      ),
                      Text("男"),
                    ],
                  ),
                  Row(
                    children: [
                      Radio(
                        value: "女",
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value.toString();
                          });
                        },
                      ),
                      Text("女"),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),

              // 出生日期选择
              ElevatedButton(
                onPressed: _selectDate,
                child: Text(_selectedDate == null
                    ? "选择出生日期"
                    : "出生日期: ${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}"),
              ),

              SizedBox(height: 30),
              ElevatedButton(onPressed: _submit, child: Text("提交")),
            ],
          ),
        ),
      ),
    );
  }
}
