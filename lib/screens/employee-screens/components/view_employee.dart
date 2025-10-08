import 'package:flutter/material.dart';

class ViewEmployee extends StatelessWidget {
  const ViewEmployee({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    hintText: "Employee name",
                    trailing: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.filter_list_outlined, size: 35),
              ),
            ],
          ),
          Center(child: Text("EMPLOYEES")),
        ],
      ),
    );
  }
}
