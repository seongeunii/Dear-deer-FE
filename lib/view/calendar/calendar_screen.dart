import 'package:dear_deer_demo/data/today_ex.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:dear_deer_demo/view/calendar/calendar_event.dart';
import 'package:dear_deer_demo/view/calendar/calendar_add_event.dart';
import 'package:dear_deer_demo/view/calendar/calendar_bottom_sheet.dart';
import 'package:dear_deer_demo/view/calendar/calendar_view.dart';
import 'package:dear_deer_demo/data/events_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final int currentYear;
  late final List<DateTime> months;
  final PageController _pageController = PageController(initialPage: 0);

  final Map<String, List<CalendarEvent>> _store = {};
  late final EventsRepository repo;

  DateTime? _selectedDate;
  final DateTime _today = fakeToday;

  String _genId() {
    final r = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${r.nextInt(1 << 32)}';
  }

  @override
  void initState() {
    super.initState();
    currentYear = fakeToday.year;
    months = [DateTime(currentYear, 11), DateTime(currentYear, 12)];
    _selectedDate = _today;

    // 원격 저장소로 교체: baseUrl은 스웨거 서버 주소
    repo = RemoteEventsRepository(baseUrl: 'https://<YOUR-SERVER-DOMAIN>');
  }

  Future<List<CalendarEvent>> _getEventsForDate(DateTime date) {
    return repo.listByDate(date);
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddEvent(
        initialDate: _selectedDate ?? _today,
        onAddEvent: (date, title, memo, category) async {
          final e = CalendarEvent(
            id: _genId(),
            title: title,
            memo: memo,
            category: category,
            date: date,
          );
          await repo.create(e);
          if (!mounted) return;
          Navigator.pop(context);
          _showBottom(date);
          setState(() {});
        },
      ),
    );
  }

  void _showBottom(DateTime date) async {
    setState(() => _selectedDate = date);
    final events = await repo.listByDate(date);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CalendarBottomSheet(
        date: date,
        events: events,
        onDeleteEvent: (event) async {
          await repo.delete(event);
          if (!mounted) return;
          Navigator.pop(context);
          _showBottom(date);
          setState(() {});
        },
        onEditEvent: (original, updated) async {
          await repo.update(updated, oldDate: original.date);
          if (!mounted) return;
          Navigator.pop(context); // close bottom
          _showBottom(updated.date); // reopen for possibly moved date
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: _openAdd,
        child: const Icon(Icons.add, size: 40, color: Color(0xFFA14E4A)),
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: months.length,
          itemBuilder: (context, index) => FutureBuilder<List<CalendarEvent>>(
            future: _getEventsForDate(months[index]), // just to warm cache
            builder: (_, __) => CalendarView(
              monthDate: months[index],
              today: _today,
              selectedDate: _selectedDate,
              getEventsForDate: _getEventsForDate,
              onDayTap: _showBottom,
            ),
          ),
        ),
      ),
    );
  }
}
