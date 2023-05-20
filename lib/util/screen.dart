import 'package:flutter/material.dart';

double screenAwareHeight(double size, BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  double drawingHeight = mediaQuery.size.height - mediaQuery.padding.top;
  return size * drawingHeight;
}

double screenAwareWidth(double size, BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  double drawingWidth = mediaQuery.size.width -
      (mediaQuery.padding.left + mediaQuery.padding.right);
  return size * drawingWidth;
}

