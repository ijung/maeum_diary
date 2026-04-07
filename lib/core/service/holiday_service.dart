import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:maeum_diary/core/utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 대한민국 공휴일 서비스 — 싱글턴
///
/// 공공데이터포탈 한국천문연구원_특일 정보 API를 사용해
/// 연도별 공휴일 날짜를 가져오고 로컬에 캐시한다.
///
/// API 키는 빌드/실행 시 --dart-define=HOLIDAY_API_KEY=발급키 로 주입한다.
class HolidayService {
    static final HolidayService instance = HolidayService._();
    HolidayService._();

    // API 키: 프로젝트 루트 .env 파일의 HOLIDAY_API_KEY 값을 사용한다.
    static String get _apiKey => dotenv.maybeGet('HOLIDAY_API_KEY') ?? '';

    static const String _baseUrl =
        'https://apis.data.go.kr/B090041/openapi/service'
        '/SpcdeInfoService/getRestDeInfo';

    static String _cacheKey(int year) => 'holiday_cache_$year';

    /// [year]년 공휴일 날짜 Set<'yyyy-MM-dd'>를 반환한다.
    ///
    /// 캐시가 있으면 캐시를 반환하고, 없으면 API를 호출한다.
    /// API 실패 또는 API 키 미설정 시 빈 Set을 반환해 앱 정상 동작을 보장한다.
    Future<Set<String>> getHolidaysForYear(int year) async {
        final cached = await _loadFromCache(year);
        if (cached != null) return cached;

        if (_apiKey.isEmpty) return {};

        try {
            final holidays = await _fetchFromApi(year);
            // 빈 결과는 캐시하지 않는다.
            // API 오류·파싱 실패로 빈 Set이 반환된 경우 다음 실행 시 재시도해야 한다.
            if (holidays.isNotEmpty) {
                await _saveToCache(year, holidays);
            }
            return holidays;
        } catch (_) {
            return {};
        }
    }

    Future<Set<String>?> _loadFromCache(int year) async {
        final prefs = await SharedPreferences.getInstance();
        final json = prefs.getString(_cacheKey(year));
        if (json == null) return null;
        final set = (jsonDecode(json) as List).cast<String>().toSet();
        // 빈 Set은 유효한 캐시로 취급하지 않는다 (API 재시도 허용)
        return set.isEmpty ? null : set;
    }

    Future<void> _saveToCache(int year, Set<String> holidays) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey(year), jsonEncode(holidays.toList()));
    }

    Future<Set<String>> _fetchFromApi(int year) async {
        final uri = Uri.parse(_baseUrl).replace(queryParameters: {
            'serviceKey': _apiKey,
            'solYear': year.toString(),
            'numOfRows': '100',
            'pageNo': '1',
            '_type': 'json',
        });

        final response = await http.get(uri);
        if (response.statusCode != 200) return {};

        final body = jsonDecode(response.body);
        final items = body['response']?['body']?['items']?['item'];
        if (items == null) return {};

        // API는 결과가 1개일 때 List가 아닌 단일 Map을 반환한다
        final itemList = items is List ? items : [items];

        final result = <String>{};
        for (final item in itemList) {
            if (item['isHoliday'] != 'Y') continue;
            final locdate = item['locdate'].toString(); // 예: "20250101"
            final date = DateTime(
                int.parse(locdate.substring(0, 4)),
                int.parse(locdate.substring(4, 6)),
                int.parse(locdate.substring(6, 8)),
            );
            result.add(toDateKey(date));
        }
        return result;
    }
}
