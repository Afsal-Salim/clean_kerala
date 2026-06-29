class AnalyticsSummary {
  AnalyticsSummary({
    required this.totalReports,
    required this.pending,
    required this.closed,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) => AnalyticsSummary(
        totalReports: json['total_reports'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        closed: json['closed'] as int? ?? 0,
      );

  final int totalReports;
  final int pending;
  final int closed;
}

class GeoStatsItem {
  GeoStatsItem({
    required this.level,
    required this.name,
    required this.slug,
    required this.totalReports,
    required this.pending,
    required this.closed,
  });

  factory GeoStatsItem.fromJson(Map<String, dynamic> json) => GeoStatsItem(
        level: json['level'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        totalReports: json['total_reports'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        closed: json['closed'] as int? ?? 0,
      );

  final String level;
  final String name;
  final String slug;
  final int totalReports;
  final int pending;
  final int closed;
}

class DistrictDetail {
  DistrictDetail({
    required this.name,
    required this.slug,
    required this.totalReports,
    required this.pending,
    required this.closed,
    required this.localBodies,
  });

  factory DistrictDetail.fromJson(Map<String, dynamic> json) => DistrictDetail(
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        totalReports: json['total_reports'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        closed: json['closed'] as int? ?? 0,
        localBodies: (json['local_bodies'] as List<dynamic>? ?? [])
            .map((e) => GeoStatsItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String name;
  final String slug;
  final int totalReports;
  final int pending;
  final int closed;
  final List<GeoStatsItem> localBodies;
}

class LocalBodyDetail {
  LocalBodyDetail({
    required this.name,
    required this.slug,
    required this.districtName,
    required this.totalReports,
    required this.pending,
    required this.closed,
    required this.wards,
  });

  factory LocalBodyDetail.fromJson(Map<String, dynamic> json) => LocalBodyDetail(
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        districtName: json['district_name'] as String? ?? '',
        totalReports: json['total_reports'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        closed: json['closed'] as int? ?? 0,
        wards: (json['wards'] as List<dynamic>? ?? [])
            .map((e) => GeoStatsItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String name;
  final String slug;
  final String districtName;
  final int totalReports;
  final int pending;
  final int closed;
  final List<GeoStatsItem> wards;
}

class WardDetail {
  WardDetail({
    required this.name,
    required this.slug,
    required this.municipalityName,
    required this.districtName,
    required this.totalReports,
    required this.pending,
    required this.closed,
  });

  factory WardDetail.fromJson(Map<String, dynamic> json) => WardDetail(
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        municipalityName: json['municipality_name'] as String? ?? '',
        districtName: json['district_name'] as String? ?? '',
        totalReports: json['total_reports'] as int? ?? 0,
        pending: json['pending'] as int? ?? 0,
        closed: json['closed'] as int? ?? 0,
      );

  final String name;
  final String slug;
  final String municipalityName;
  final String districtName;
  final int totalReports;
  final int pending;
  final int closed;
}

enum AnalyticsLevel { state, district, localBody, ward }

class AnalyticsViewState {
  const AnalyticsViewState({
    this.level = AnalyticsLevel.state,
    this.districtSlug,
    this.localBodySlug,
    this.wardSlug,
    this.title = 'Kerala',
  });

  final AnalyticsLevel level;
  final String? districtSlug;
  final String? localBodySlug;
  final String? wardSlug;
  final String title;

  AnalyticsViewState drillDistrict(String slug, String name) => AnalyticsViewState(
        level: AnalyticsLevel.district,
        districtSlug: slug,
        title: name,
      );

  AnalyticsViewState drillLocalBody(String slug, String name) => AnalyticsViewState(
        level: AnalyticsLevel.localBody,
        districtSlug: districtSlug,
        localBodySlug: slug,
        title: name,
      );

  AnalyticsViewState drillWard(String slug, String name) => AnalyticsViewState(
        level: AnalyticsLevel.ward,
        districtSlug: districtSlug,
        localBodySlug: localBodySlug,
        wardSlug: slug,
        title: name,
      );

  AnalyticsViewState pop() {
    switch (level) {
      case AnalyticsLevel.ward:
        return AnalyticsViewState(
          level: AnalyticsLevel.localBody,
          districtSlug: districtSlug,
          localBodySlug: localBodySlug,
          title: localBodySlug ?? 'Local body',
        );
      case AnalyticsLevel.localBody:
        return AnalyticsViewState(
          level: AnalyticsLevel.district,
          districtSlug: districtSlug,
          title: districtSlug ?? 'District',
        );
      case AnalyticsLevel.district:
        return const AnalyticsViewState();
      case AnalyticsLevel.state:
        return this;
    }
  }
}
