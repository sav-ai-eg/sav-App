import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension SizedBoxExtension on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble().h);
  SizedBox get horizontalSpace => SizedBox(width: toDouble().w);
}
