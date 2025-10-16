import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dear_deer_demo/data/app_color.dart';
import 'package:dear_deer_demo/data/font_styles.dart';
import 'calendar_day_box.dart';
import 'calendar_blank_box.dart';
import 'calendar_weekday_header.dart';
import 'calendar_event.dart';

class CalendarView extends StatelessWidget {
  final DateTime monthDate;
  final Function(DateTime) onDayTap;
  final DateTime? selectedDate;
  final DateTime today;
  final Future<List<CalendarEvent>> Function(DateTime) getEventsForDate;

  const CalendarView({
    Key? key,
    required this.monthDate,
    required this.onDayTap,
    this.selectedDate,
    required this.today,
    required this.getEventsForDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final year = monthDate.year;
    final month = monthDate.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sun=0

    List<Widget> boxWidgets = [];

    // 12월일 때만 "지난달 날짜"를 채워 넣기 (테스트 스펙)
    for (int i = 0; i < startWeekday; i++) {
      if (month == 12) {
        final prevMonthLastDay = DateTime(year, month, 0).day;
        final dayNumber = prevMonthLastDay - (startWeekday - i - 1);
        final d = DateTime(year, month - 1, dayNumber);
        final isPast = d.isBefore(DateTime(today.year, today.month, today.day));
        final isToday = _isSame(d, today);
        final isSelected = selectedDate != null && _isSame(d, selectedDate!);
        boxWidgets.add(FutureBuilder<List<CalendarEvent>>(
          future: getEventsForDate(d),
          builder: (_, snap) => CalendarDayBox(
            day: dayNumber,
            isPast: isPast,
            isSelected: isSelected,
            isToday: isToday,
            date: d,
            onTap: (dd) => onDayTap(dd),
            events: snap.data ?? const [],
          ),
        ));
      } else {
        boxWidgets.add(const CalendarBlankBox());
      }
    }

    // 이번달 날짜
    for (int day = 1; day <= lastDay; day++) {
      final d = DateTime(year, month, day);
      final isPast = d.isBefore(DateTime(today.year, today.month, today.day));
      final isToday = _isSame(d, today);
      final isSelected = selectedDate != null && _isSame(d, selectedDate!);

      boxWidgets.add(FutureBuilder<List<CalendarEvent>>(
        future: getEventsForDate(d),
        builder: (_, snap) => CalendarDayBox(
          day: day,
          isPast: isPast,
          isSelected: isSelected,
          isToday: isToday,
          date: d,
          onTap: (dd) => onDayTap(dd),
          events: snap.data ?? const [],
        ),
      ));
    }

    return Padding(
      padding: EdgeInsets.only(left: 33.w, right: 58.5.w),
      child: Column(
        children: [
          SizedBox(height: 115.h),
          Text(
            DateFormat('yyyy.MM').format(monthDate),
            style: FontStyles.C2_reg_24.copyWith(color: AppColors.White),
          ),
          SizedBox(height: 20.h),
          const CalendarWeekdayHeader(),
          SizedBox(
            width: (34.w * 7) + (5.w * 6),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: boxWidgets.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 11.h,
                crossAxisSpacing: 5.w,
                childAspectRatio: 34 / 48,
              ),
              itemBuilder: (context, index) => boxWidgets[index],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSame(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
