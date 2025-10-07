import 'package:flutter/material.dart';

class MenuItemDesign extends StatelessWidget {
  late String itemTitle;
  late IconData itemIcon;
  late VoidCallback onTap;
  MenuItemDesign(this.itemTitle, this.itemIcon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(),
      leading: Icon(itemIcon),
      title: Text(itemTitle),
      trailing: Icon(Icons.navigate_next),
    );
  }
}
