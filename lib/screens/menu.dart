import 'package:flutter/material.dart';
import 'package:klockerapp/components/menu_item_design.dart';
import 'package:klockerapp/screens/employee-screens/time_management.dart';
import 'package:klockerapp/utils/custom_theme/text_theme.dart';
import 'package:klockerapp/screens/employee-screens/employees.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Title(
          color: Colors.white,
          child: Text('Menu', style: KAppTextTheme.darkTextTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Employee',
            style: KAppTextTheme.darkTextTheme.headlineMedium,
          ),
        ),
        MenuItemDesign('Employee', Icons.person, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Employees()),
          );
        }),
        MenuItemDesign('Time Management', Icons.timer, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TimeManagement()),
          );
        }),
        MenuItemDesign('HRM', Icons.perm_contact_calendar, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Employees()),
          );
        }),
        SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Finances',
            style: KAppTextTheme.darkTextTheme.headlineMedium,
          ),
        ),
        MenuItemDesign('Finance', Icons.monetization_on, () => {}),
        MenuItemDesign('Company', Icons.business_rounded, () => {}),
        MenuItemDesign('Report', Icons.auto_graph_rounded, () => {}),
        SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Help',
            style: KAppTextTheme.darkTextTheme.headlineMedium,
          ),
        ),
        MenuItemDesign('Support', Icons.add_ic_call_outlined, () => {}),
        MenuItemDesign('Help', Icons.add_comment, () => {}),
      ],
    );
  }
}
