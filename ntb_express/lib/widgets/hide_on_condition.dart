import 'package:flutter/material.dart';

class HideOnCondition extends StatelessWidget {
  final bool hideOn;
  final Widget child;

  HideOnCondition({@required this.hideOn, @required this.child});

  @override
  Widget build(BuildContext context) {
    return hideOn ? SizedBox() : child;
  }
}
