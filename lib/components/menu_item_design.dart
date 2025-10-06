import 'package:flutter/material.dart';

class MenuItemDesign extends StatelessWidget {
  late String itemTitle;
  late IconData itemIcon;
  MenuItemDesign(this.itemTitle, this.itemIcon) {}

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(itemIcon),
      title: Text(itemTitle),
      trailing: Icon(Icons.navigate_next),
    );
  }
}
