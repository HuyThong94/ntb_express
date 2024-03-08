extension NumberParsing on String {
  int parseInt() {
    try {
      return int.parse(this);
    } catch (e) {
      return 0;
    }
  }

  double parseDouble() {
    try {
      return double.parse(this);
    } catch (e) {
      return 0;
    }
  }
}

extension NumberExtension on num {
  bool get isInt => (this % 1) == 0;
}