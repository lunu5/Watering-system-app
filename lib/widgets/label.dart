import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final label;
  Label(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: const [
            Colors.black87,
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: Text(
        label,
        style: const TextStyle(fontSize: 26, color: Colors.white),
        textAlign: TextAlign.center,
        softWrap: true,
        overflow: TextOverflow.fade,
      ),
    );
  }
}
