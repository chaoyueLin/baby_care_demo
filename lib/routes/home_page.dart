import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PageView and Custom Components',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: _HomePageState(),
    );
  }
}

class _HomePageState extends StatelessWidget {
  // 显示时间选择器对话框
  Future<void> _showTimePickerDialog(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected time: ${pickedTime.format(context)}')),
      );
    }
  }

  // 构建自定义组件
  Widget _buildCustomComponent(BuildContext context, String label, String imagePath) {
    return GestureDetector(
      onTap: () {
        _showTimePickerDialog(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PageView and Custom Components'),
      ),
      body: Column(
        children: [
          // PageView 部分
          Expanded(
            child: PageView(
              children: [
                Center(child: Text('Today', style: TextStyle(fontSize: 24))),
                Center(child: Text('Yesterday', style: TextStyle(fontSize: 24))),
                Center(child: Text('Tomorrow', style: TextStyle(fontSize: 24))),
              ],
            ),
          ),

          // 底部的四个自定义组件
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCustomComponent(context, 'Breast Milk', 'assets/icons/mother_milk.png'),
                _buildCustomComponent(context, 'Formula', 'assets/icons/formula_milk.png'),
                _buildCustomComponent(context, 'Water', 'assets/icons/water.png'),
                _buildCustomComponent(context, 'Poop', 'assets/icons/poop.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
