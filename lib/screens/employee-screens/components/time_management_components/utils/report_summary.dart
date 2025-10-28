import 'package:flutter/material.dart';

class SummaryContainer extends StatelessWidget {
  const SummaryContainer(
    this.sumIcon,
    this.sumValue,
    this.sumTitle, {
    super.key,
  });

  final String sumTitle;
  final int sumValue;
  final IconData sumIcon;

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
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              sumValue.toString(),
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
