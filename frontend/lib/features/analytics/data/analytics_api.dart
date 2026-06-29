import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/analytics_models.dart';

class AnalyticsApi {
  AnalyticsApi(this._dio);

  final Dio _dio;

  Future<AnalyticsSummary> summary() async {
    final r = await _dio.get('/analytics/summary');
    return AnalyticsSummary.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<GeoStatsItem>> districts() async {
    final r = await _dio.get('/analytics/districts');
    return (r.data as List<dynamic>)
        .map((e) => GeoStatsItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DistrictDetail> district(String slug) async {
    final r = await _dio.get('/analytics/districts/$slug');
    return DistrictDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<LocalBodyDetail> localBody(String slug) async {
    final r = await _dio.get('/analytics/local-bodies/$slug');
    return LocalBodyDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<WardDetail> ward(String slug) async {
    final r = await _dio.get('/analytics/wards/$slug');
    return WardDetail.fromJson(r.data as Map<String, dynamic>);
  }
}

final analyticsApiProvider = Provider<AnalyticsApi>((ref) => AnalyticsApi(ref.watch(dioProvider)));

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) {
  return ref.watch(analyticsApiProvider).summary();
});

final analyticsDistrictsProvider = FutureProvider<List<GeoStatsItem>>((ref) {
  return ref.watch(analyticsApiProvider).districts();
});
