import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dear_deer_demo/data/app_color.dart';
import 'package:dear_deer_demo/data/font_styles.dart';
import 'calendar_event.dart';

class CalendarDayBox extends StatelessWidget {
  final int day;
  final bool isPast;
  final bool isSelected;
  final bool isToday;
  final DateTime date;
  final void Function(DateTime) onTap;
  final List<CalendarEvent> events;

  const CalendarDayBox({
    Key? key,
    required this.day,
    required this.isPast,
    required this.isSelected,
    required this.isToday,
    required this.date,
    required this.onTap,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 정렬: 전역 우선순위 사용
    final sorted = List<CalendarEvent>.from(events)
      ..sort((a, b) => (kCategoryPriority[a.category] ?? 99)
          .compareTo(kCategoryPriority[b.category] ?? 99));

    final isChristmas = (date.month == 12 && date.day == 25);

    return GestureDetector(
      onTap: () => onTap(date),
      child: Container(
        width: 34.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Stack(
          children: [
            // 지난 날짜 반투명 오버레이
            if (isPast)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C6D4D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ),

            // 상단 바 (선택: 빨강 / 오늘: 회색)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 7.h,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.mainRed
                      : (isToday ? AppColors.G_04 : Colors.transparent),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6.r),
                    topRight: Radius.circular(6.r),
                  ),
                ),
              ),
            ),

            // 날짜 텍스트
            Align(
              alignment: const Alignment(0, -0.35),
              child: Text(
                '$day',
                style: FontStyles.C1_bold_14.copyWith(
                  color: isChristmas ? AppColors.mainRed : AppColors.G_07,
                ),
              ),
            ),

            // 이벤트 점 3개까지
            Positioned(
              left: 0,
              right: 0,
              bottom: 5.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...sorted.take(3).toList().asMap().entries.map((entry) {
                    return Container(
                      width: 5.w,
                      height: 5.w,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        color: kCategoryColors[entry.value.category] ??
                            Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),

                  // 4개 이상: 오른쪽 반원 그라데이션
                  if (sorted.length >= 4)
                    Padding(
                      padding: EdgeInsets.only(left: 3.w),
                      child: SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: kCategoryColors[sorted[3].category] ??
                                    Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 3.w,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(2.5.w),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
