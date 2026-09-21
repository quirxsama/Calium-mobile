import 'package:dio/dio.dart';
import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/calendar/data/models/calendar_day_model.dart';

abstract class CalendarRemoteDataSource {
  Future<List<CalendarDayModel>> getCalendar();
}

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  const CalendarRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  List<CalendarDayModel> _parseCalendar(dynamic data) {
    if (data is Map<String, dynamic>) {
      final listData = data['data'];
      if (listData is List) {
        return listData
            .map((d) => CalendarDayModel.fromJson(d as Map<String, dynamic>))
            .where((d) => d.items.isNotEmpty)
            .toList();
      }
    }
    if (data is List) {
      return data
          .map((d) => CalendarDayModel.fromJson(d as Map<String, dynamic>))
          .where((d) => d.items.isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  Future<List<CalendarDayModel>> getCalendar() async {
    try {
      // 1. Try Calium proxy FIRST (Cloudflare bypass & reliable)
      try {
        final response = await _dioClient.get('/api/anizium/calendar');
        final parsed = _parseCalendar(response.data);
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}

      // 2. Direct Anizium API fallback
      try {
        final directDio = Dio(
          BaseOptions(
            headers: {
              'User-Agent': ApiConstants.userAgent,
              'Referer': ApiConstants.referer,
              'Origin': ApiConstants.origin,
              'CF-Control': ApiConstants.cfControl,
              'User-Session': ApiConstants.userSession,
            },
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
        final response = await directDio.get('${ApiConstants.aniziumApiBaseUrl}/page/calendar');
        final parsed = _parseCalendar(response.data);
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}

      // 3. Fallback to /api/anizium/schedule or return empty safe list
      try {
        final response = await _dioClient.get('/api/anizium/schedule');
        final parsed = _parseCalendar(response.data);
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}

      return [];
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Yayın takvimi yüklenemedi: $e');
    }
  }
}
