import 'package:flutter/material.dart';
import 'package:ntbexpress/util/app_state.dart';

class AppProvider extends InheritedWidget {
  final AppState state;
  const AppProvider({
    Key key,
    @required Widget child,
    @required this.state,
  })  : assert(child != null),
        super(key: key, child: child);

  static AppProvider of(BuildContext context) {
    return context?.dependOnInheritedWidgetOfExactType<AppProvider>();
  }

  @override
  bool updateShouldNotify(AppProvider old) {
    return true;
  }
}