import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/home/presentation/cubit/home_cubit.dart';

Future<DateTime?> showDutyCalendarDialog({
  required BuildContext context,
  required Map<DateTime, DutyLevel> dutyByDate,
  required DateTime focusedMonth,
  DateTime? selectedDate,
  ValueChanged<DateTime>? onMonthChanged,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.white.withValues(alpha: 0.5),
    builder: (_) => DutyCalendarDialog(
      dutyByDate: dutyByDate,
      focusedMonth: focusedMonth,
      selectedDate: selectedDate,
      onMonthChanged: onMonthChanged,
    ),
  );
}

class DutyCalendarDialog extends StatefulWidget {
  const DutyCalendarDialog({
    super.key,
    required this.dutyByDate,
    required this.focusedMonth,
    required this.selectedDate,
    this.onMonthChanged,
  });

  final Map<DateTime, DutyLevel> dutyByDate;
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onMonthChanged;

  @override
  State<DutyCalendarDialog> createState() => _DutyCalendarDialogState();
}

class _DutyCalendarDialogState extends State<DutyCalendarDialog> {
  late DateTime _displayedMonth;
  late DateTime _selectedDay;

  static const List<String> _weekdays = <String>[
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.focusedMonth.year,
      widget.focusedMonth.month,
    );
    _selectedDay = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat('MMMM yyyy').format(_displayedMonth);

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        width: 312.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E7ED)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CalendarHeader(
              title: monthTitle,
              onPrevTap: () => _changeMonth(-1),
              onNextTap: () => _changeMonth(1),
            ),
            SizedBox(height: 16.h),
            _WeekdaysRow(labels: _weekdays),
            SizedBox(height: 4.h),
            _DaysGrid(
              month: _displayedMonth,
              selectedDay: _selectedDay,
              dutyByDate: widget.dutyByDate,
              onDayTap: (day) {
                setState(() {
                  _selectedDay = day;
                });
              },
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF50576B),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 36.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selectedDay),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + offset);
    setState(() {
      _displayedMonth = next;
    });
    widget.onMonthChanged?.call(next);
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.title,
    required this.onPrevTap,
    required this.onNextTap,
  });

  final String title;
  final VoidCallback onPrevTap;
  final VoidCallback onNextTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderButton(icon: Icons.chevron_left_rounded, onTap: onPrevTap),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF323745),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18.sp,
                  color: const Color(0xFF50576B),
                ),
              ],
            ),
          ),
        ),
        _HeaderButton(icon: Icons.chevron_right_rounded, onTap: onNextTap),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFE2E7ED)),
        ),
        child: Icon(icon, size: 20.sp, color: const Color(0xFF323745)),
      ),
    );
  }
}

class _WeekdaysRow extends StatelessWidget {
  const _WeekdaysRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (day) => Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF13151A),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DaysGrid extends StatelessWidget {
  const _DaysGrid({
    required this.month,
    required this.selectedDay,
    required this.dutyByDate,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<DateTime, DutyLevel> dutyByDate;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final firstCell = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final days = List<DateTime>.generate(
      42,
      (index) =>
          DateTime(firstCell.year, firstCell.month, firstCell.day + index),
    );

    return SizedBox(
      width: double.infinity,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: days.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final day = days[index];
          final normalized = DateTime(day.year, day.month, day.day);
          final isInMonth = day.month == month.month;
          final isSelected = _isSameDay(normalized, selectedDay);
          final isToday = _isSameDay(normalized, DateTime.now());
          final duty = dutyByDate[normalized] ?? DutyLevel.off;

          return GestureDetector(
            onTap: () => onDayTap(normalized),
            child: Container(
              margin: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                      color: _resolveDayTextColor(
                        isInMonth: isInMonth,
                        isSelected: isSelected,
                        isToday: isToday,
                      ),
                    ),
                  ),
                  if (isInMonth && !isSelected && duty != DutyLevel.off)
                    Positioned(
                      bottom: 8.h,
                      child: Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          color: _dutyColor(duty),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _resolveDayTextColor({
    required bool isInMonth,
    required bool isSelected,
    required bool isToday,
  }) {
    if (isSelected) {
      return Colors.white;
    }
    if (!isInMonth) {
      return const Color(0xFFBCC4D4);
    }
    if (isToday) {
      return AppColors.primaryColor;
    }
    return const Color(0xFF50576B);
  }

  Color _dutyColor(DutyLevel duty) {
    switch (duty) {
      case DutyLevel.high:
        return AppColors.primaryColor;
      case DutyLevel.low:
        return AppColors.salmonLight;
      case DutyLevel.off:
        return Colors.transparent;
    }
  }
}
