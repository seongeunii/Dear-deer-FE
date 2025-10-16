import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:dear_deer_demo/view/calendar/calendar_event.dart';

abstract class EventsRepository {
  Future<List<CalendarEvent>> listByDate(DateTime date);
  Future<void> create(CalendarEvent event);
  Future<void> update(CalendarEvent event, {required DateTime oldDate});
  Future<void> delete(CalendarEvent event);
}

/// 인메모리 로컬 저장소(필요 시 여전히 사용 가능)
class LocalEventsRepository implements EventsRepository {
  final Map<String, List<CalendarEvent>> _store;
  LocalEventsRepository(this._store);

  String _k(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<CalendarEvent>> listByDate(DateTime date) async {
    final List<CalendarEvent> list = <CalendarEvent>[
      ...(_store[_k(date)] ?? const <CalendarEvent>[])
    ];
    list.sort((a, b) => (kCategoryPriority[a.category] ?? 99)
        .compareTo(kCategoryPriority[b.category] ?? 99));
    return list;
  }

  @override
  Future<void> create(CalendarEvent event) async {
    final k = _k(event.date);
    final List<CalendarEvent> list = _store[k] ?? <CalendarEvent>[];
    list.add(event);
    list.sort((a, b) => (kCategoryPriority[a.category] ?? 99)
        .compareTo(kCategoryPriority[b.category] ?? 99));
    _store[k] = list;
  }

  @override
  Future<void> update(CalendarEvent event, {required DateTime oldDate}) async {
    final oldK = _k(oldDate);
    _store[oldK]?.removeWhere((e) => e.id == event.id);
    await create(event); // 새 날짜에 추가(+정렬)
  }

  @override
  Future<void> delete(CalendarEvent event) async {
    final k = _k(event.date);
    _store[k]?.removeWhere((e) => e.id == event.id);
  }
}

/// 🔗 Swagger 연동 저장소
class RemoteEventsRepository implements EventsRepository {
  final String baseUrl;
  final http.Client _client;

  RemoteEventsRepository({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // 스웨거 포맷에 맞게 날짜 문자열화
  final DateFormat _dateOnly = DateFormat('yyyy-MM-dd');

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse(baseUrl).replace(path: path, queryParameters: q);

  CalendarEvent _fromDailyJson(Map<String, dynamic> j) {
    // API -> UI 카테고리 문자열 치환
    final apiCat = (j['category'] ?? '') as String;
    final uiCat = kApiToUiCategory[apiCat] ?? '기타';

    // 날짜: ISO Z → DateTime
    final dt = DateTime.tryParse(j['date'] ?? '')?.toLocal() ?? DateTime.now();

    return CalendarEvent(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      memo: j['memo']?.toString() ?? '',
      category: uiCat,
      date: dt,
    );
  }

  @override
  Future<List<CalendarEvent>> listByDate(DateTime date) async {
    // GET /schedules/daily?date=YYYY-MM-DD
    final uri = _u('/schedules/daily', {
      'date': _dateOnly.format(date),
    });

    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('GET /schedules/daily failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    if (body is! List) return <CalendarEvent>[];

    final List<CalendarEvent> list = body
        .whereType<Map<String, dynamic>>()
        .map(_fromDailyJson)
        .toList()
      ..sort((a, b) => (kCategoryPriority[a.category] ?? 99)
          .compareTo(kCategoryPriority[b.category] ?? 99));

    return list;
  }

  @override
  Future<void> create(CalendarEvent event) async {
    // POST /schedules
    // body: { title, memo, category("APPOINTMENT"...), date:"yyyy-MM-dd" }
    final uri = _u('/schedules');
    final apiCategory = kUiToApiCategory[event.category] ?? 'ETC';
    final payload = {
      'title': event.title,
      'memo': event.memo,
      'category': apiCategory,
      'date': _dateOnly.format(event.date), // 스웨거가 date-only 예시
    };

    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201) {
      throw Exception('POST /schedules failed (${res.statusCode}) ${res.body}');
    }
    // 응답에 id 포함 → 필요하면 파싱해서 로컬 캐시 반영 가능
  }

  @override
  Future<void> update(CalendarEvent event, {required DateTime oldDate}) async {
    // PATCH /schedules/{id}
    final uri = _u('/schedules/${event.id}');
    final apiCategory = kUiToApiCategory[event.category] ?? 'ETC';
    // 스웨거 예시: date는 ISO 문자열 (Z 포함). 서버 기준에 따라 조정.
    final payload = {
      'title': event.title,
      'memo': event.memo,
      'category': apiCategory,
      'date': event.date.toUtc().toIso8601String(),
    };

    final res = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 404) {
      throw Exception('PATCH /schedules/${event.id} not found');
    }
    if (res.statusCode != 200) {
      throw Exception(
          'PATCH /schedules/${event.id} failed (${res.statusCode}) ${res.body}');
    }
  }

  @override
  Future<void> delete(CalendarEvent event) async {
    // DELETE /schedules/{id}
    final uri = _u('/schedules/${event.id}');
    final res = await _client.delete(uri);

    if (res.statusCode == 404) {
      throw Exception('DELETE /schedules/${event.id} not found');
    }
    if (res.statusCode != 204) {
      throw Exception(
          'DELETE /schedules/${event.id} failed (${res.statusCode})');
    }
  }

  // ✅ 필요 시: 월별 점/인디케이터 최적화 (지금 UI는 daily를 여러 번 호출)
  Future<List<_MonthlyMini>> monthly(int year, int month) async {
    // GET /schedules/monthly?year=YYYY&month=M
    final uri = _u('/schedules/monthly', {
      'year': '$year',
      'month': '$month',
    });

    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) return <_MonthlyMini>[];

    final body = jsonDecode(res.body);
    if (body is! List) return <_MonthlyMini>[];

    return body
        .whereType<Map<String, dynamic>>()
        .map((j) {
          final apiCat = (j['category'] ?? '') as String;
          final uiCat = kApiToUiCategory[apiCat] ?? '기타';
          final dt = DateTime.tryParse(j['date'] ?? '')?.toLocal();
          return _MonthlyMini(
            id: j['id']?.toString() ?? '',
            category: uiCat,
            date: dt,
          );
        })
        .where((e) => e.date != null)
        .toList();
  }
}

class _MonthlyMini {
  final String id;
  final String category; // UI 라벨
  final DateTime? date; // 하루용
  _MonthlyMini({required this.id, required this.category, required this.date});
}
