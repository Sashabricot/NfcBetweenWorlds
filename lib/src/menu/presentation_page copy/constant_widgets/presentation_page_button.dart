import 'package:flutter/material.dart';

class PresentationPageButton extends StatelessWidget {
  const PresentationPageButton({
    super.key,
    required this.widget,
    required this.text,
  });

  final Widget widget;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: ((context) => widget)));
      },
      child: Container(
        alignment: .centerLeft,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: .all(color: Colors.black),
          borderRadius: .circular(8),
          color: Colors.white,
        ),
        height: 52,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Text(text, style: TextStyle(fontWeight: .bold, fontSize: 18)),
      ),
    );
  }
}
