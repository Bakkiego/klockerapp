import 'package:flutter/material.dart';

class LeaveSummary extends StatefulWidget {
  LeaveSummary();

  @override
  State<LeaveSummary> createState() => _LeaveSummaryState();
}

class _LeaveSummaryState extends State<LeaveSummary> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Leave Summary',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.left,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            spacing: 20,
            children: [
              SummaryContainer(Icons.person, 20, "Requests"),
              SummaryContainer(Icons.check, 15, 'Approved'),
              SummaryContainer(Icons.close, 5, 'Rejected'),
            ],
          ),
        ),
      ],
    );
  }
}

class SummaryContainer extends StatelessWidget {
  SummaryContainer(
    @required this.sumIcon,
    @required this.sumValue,
    @required this.sumTitle,
  );

  late String sumTitle;
  late int sumValue;
  late IconData sumIcon;

  late String sumValueString = sumValue.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightGreenAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      width: 105,
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: Colors.green,
              child: Icon(sumIcon),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 10.0),
            child: Text(
              sumTitle,
              style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              sumValueString,
              style: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
