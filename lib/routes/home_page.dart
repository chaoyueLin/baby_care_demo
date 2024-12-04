import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomePageContent();
  }
}

class HomePageContent extends StatelessWidget {
  Future<void> _showTimePickerDialog(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)?.selectedTime(pickedTime.format(context))??"")),
      );
    }
  }

  void _showFormulaMilkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context)?.formula??""),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: 50,
              itemBuilder: (BuildContext context, int index) {
                int value = (index + 1) * 10;
                return ListTile(
                  title: Text('$value ml'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context)?.selectedVolume(value.toString())??"")),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context)?.cancel??""),
            ),
          ],
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
            child: PageView(
              children: [
                Center(child: Text(S.of(context)?.today??"", style: TextStyle(fontSize: 24))),
                Center(child: Text(S.of(context)?.yesterday??"", style: TextStyle(fontSize: 24))),
                Center(child: Text(S.of(context)?.tomorrow??"", style: TextStyle(fontSize: 24))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CustomComponent(
                  label: S.of(context)?.breastMilk??"",
                  imagePath: 'assets/icons/mother_milk.png',
                  onTap: () => _showTimePickerDialog(context),
                ),
                CustomComponent(
                  label: S.of(context)?.formula??"",
                  imagePath: 'assets/icons/formula_milk.png',
                  onTap: () => _showFormulaMilkDialog(context),
                ),
                CustomComponent(
                  label: S.of(context)?.water??"",
                  imagePath: 'assets/icons/water.png',
                  onTap: () => _showTimePickerDialog(context),
                ),
                CustomComponent(
                  label: S.of(context)?.poop??"",
                  imagePath: 'assets/icons/poop.png',
                  onTap: () => _showTimePickerDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomComponent extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onTap;

  const CustomComponent({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}
