import 'package:flutter/material.dart';
import 'utils/create_shift_screen.dart';

class ManageShiftsScreen extends StatefulWidget {
  const ManageShiftsScreen({super.key});

  @override
  State<ManageShiftsScreen> createState() => _ManageShiftsScreenState();
}

class _ManageShiftsScreenState extends State<ManageShiftsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Shifts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateShiftScreen()),
                );
              },
              child: Text("Add Shift", style: TextStyle(color: Colors.white)),
            ),
          ),
          TableExample([
            TimeOfDay(hour: 9, minute: 0),
            TimeOfDay(hour: 17, minute: 0),
          ], "Morning Shift"),
        ],
      ),
    );
  }
}

class AddShiftScreen {
  const AddShiftScreen();
}

class TableExample extends StatelessWidget {
  TableExample(this._timeOfDay, this.nameOfShift, {super.key});

  List<TimeOfDay> _timeOfDay = List<TimeOfDay>.filled(2, TimeOfDay.now());
  final String nameOfShift;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: Colors.green,
        width: 1.0,
        borderRadius: BorderRadius.circular(5),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        const TableRow(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Name', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Time Range', textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Actions', textAlign: TextAlign.center),
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(nameOfShift, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${_timeOfDay[0].format(context)} - ${_timeOfDay[1].format(context)}",
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 30,
              children: <Widget>[
                Icon(Icons.edit),
                Icon(Icons.delete, color: Colors.red),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
