import 'package:dear_deer_demo/data/app_color.dart';
import 'package:dear_deer_demo/data/font_styles.dart';
import 'package:dear_deer_demo/view/calendar/calendar_edit_event.dart';
import 'package:dear_deer_demo/view/calendar/calendar_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CalendarBottomSheet extends StatefulWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent) onDeleteEvent;

  /// original, updated 를 같이 보내 날짜 이동에도 대응
  final void Function(CalendarEvent original, CalendarEvent updated)
      onEditEvent;

  const CalendarBottomSheet({
    Key? key,
    required this.date,
    required this.events,
    required this.onDeleteEvent,
    required this.onEditEvent,
  }) : super(key: key);

  @override
  State<CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<CalendarBottomSheet> {
  late List<CalendarEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = List.of(widget.events);
    _sort();
  }

  void _sort() {
    _events.sort((a, b) => (kCategoryPriority[a.category] ?? 99)
        .compareTo(kCategoryPriority[b.category] ?? 99));
  }

  void _handleDelete(CalendarEvent event) {
    setState(() {
      _events.removeWhere((e) => e.id == event.id);
    });
    widget.onDeleteEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('d.').format(widget.date);
    final String weekDay = DateFormat('E', 'ko').format(widget.date);
    final int dDayCount =
        DateTime(widget.date.year, 12, 25).difference(widget.date).inDays;

    final baseHeight = 266.h;
    final perEventHeight = 35.h;
    final eventCount = _events.length;
    final calculatedHeight = baseHeight + (perEventHeight * eventCount);
    final finalHeight = calculatedHeight > 620.h ? 620.h : calculatedHeight;

    return FractionallySizedBox(
      child: Container(
        height: finalHeight,
        padding: const EdgeInsets.only(top: 15, left: 30, right: 30),
        decoration: const BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$formattedDate $weekDay",
                    style:
                        FontStyles.B1_bold_15.copyWith(color: AppColors.Black)),
                Text("D-${dDayCount >= 0 ? dDayCount : 0}",
                    style:
                        FontStyles.B1_bold_15.copyWith(color: AppColors.Black)),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: _events.isEmpty
                  ? Text(
                      "등록된 일정이 없습니다.",
                      style:
                          FontStyles.B1_reg_16.copyWith(color: AppColors.G_03),
                    )
                  : ListView.separated(
                      itemCount: _events.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Divider(
                            color: AppColors.G_03, thickness: 1, height: 1),
                      ),
                      itemBuilder: (_, i) {
                        final e = _events[i];
                        return GestureDetector(
                          onTap: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) => EditEventSheet(
                                initialDate: e.date,
                                originalEvent: e,
                              ),
                            );

                            if (result == 'deleted') {
                              _handleDelete(e);
                            } else if (result is CalendarEvent) {
                              setState(() {
                                final idx =
                                    _events.indexWhere((x) => x.id == e.id);
                                if (idx != -1) _events[idx] = result;
                                _sort();
                              });
                              widget.onEditEvent(e, result); // ← 원본/수정본 동시 전달
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 5.w,
                                height: 40.h,
                                margin: EdgeInsets.only(right: 10.w, top: 2.h),
                                decoration: BoxDecoration(
                                  color: e.categoryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title,
                                        style: FontStyles.B1_reg_15.copyWith(
                                            color: AppColors.Black)),
                                    SizedBox(height: 4.h),
                                    Text(e.memo,
                                        style: FontStyles.S1_reg_12.copyWith(
                                            color: AppColors.Black)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
