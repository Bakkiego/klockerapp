import 'package:flutter/material.dart';

class MenuExpansionTile extends StatelessWidget {
  List<MenuExpansionOBJ> itemTitles = [];
  String dropdown_menu_title;
  IconData icon;
  MenuExpansionTile(this.itemTitles, this.dropdown_menu_title, this.icon);

  List<Widget> get _buildTiles {
    return itemTitles.map((item) {
      return ListTile(
        title: Text(item.title),
        onTap: item.onTap,
        trailing: const Icon(Icons.arrow_right),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text("$dropdown_menu_title"),
      leading: Icon(icon),
      children: _buildTiles,
    );
  }
}

class MenuExpansionOBJ {
  late final String title;
  late final VoidCallback onTap;

  MenuExpansionOBJ({required this.title, required this.onTap});
}
