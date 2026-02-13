import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  double dynamicHeight(double ratio) =>
      MediaQuery.sizeOf(this).height * ratio;

  double dynamicWidth(double ratio) =>
      MediaQuery.sizeOf(this).width * ratio;

  EdgeInsets get paddingHorizontalDefault =>
      EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(this).width * 0.06);

  EdgeInsets get paddingVerticalDefault =>
      EdgeInsets.symmetric(vertical: MediaQuery.sizeOf(this).height * 0.02);

  double get highValue => 12;
}
