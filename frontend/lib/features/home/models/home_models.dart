class QuoteModel {
  QuoteModel({required this.id, required this.text, this.author});

  final String id;
  final String text;
  final String? author;

  factory QuoteModel.fromJson(Map<String, dynamic> json) => QuoteModel(
        id: json['id'] as String,
        text: json['text'] as String,
        author: json['author'] as String?,
      );
}

class FeedMixInfo {
  FeedMixInfo({
    required this.mode,
    required this.locationBased,
    required this.nearPct,
    required this.surroundingPct,
    required this.keralaPct,
  });

  final String mode;
  final bool locationBased;
  final int nearPct;
  final int surroundingPct;
  final int keralaPct;

  factory FeedMixInfo.fromJson(Map<String, dynamic> json) => FeedMixInfo(
        mode: json['mode'] as String,
        locationBased: json['location_based'] as bool,
        nearPct: json['near_pct'] as int,
        surroundingPct: json['surrounding_pct'] as int,
        keralaPct: json['kerala_pct'] as int,
      );
}

class ReportModel {
  ReportModel({
    required this.id,
    required this.category,
    required this.description,
    this.address,
    this.wardName,
    this.municipalityName,
    this.districtName,
    this.latitude,
    this.longitude,
    required this.status,
    required this.upvoteCount,
    required this.commentCount,
    this.authorName,
    this.imageUrls = const [],
    this.locationTier,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String description;
  final String? address;
  final String? wardName;
  final String? municipalityName;
  final String? districtName;
  final double? latitude;
  final double? longitude;
  final String status;
  final int upvoteCount;
  final int commentCount;
  final String? authorName;
  final List<String> imageUrls;
  final String? locationTier;
  final DateTime createdAt;

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        address: json['address'] as String?,
        wardName: json['ward_name'] as String?,
        municipalityName: json['municipality_name'] as String?,
        districtName: json['district_name'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        status: json['status'] as String,
        upvoteCount: json['upvote_count'] as int,
        commentCount: json['comment_count'] as int,
        authorName: json['author_name'] as String?,
        imageUrls: (json['image_urls'] as List<dynamic>? ?? []).cast<String>(),
        locationTier: json['location_tier'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get locationLabel {
    final parts = [wardName, municipalityName, districtName].whereType<String>().where((e) => e.isNotEmpty);
    return parts.join(' · ');
  }

  String get imageLocationText {
    if (address != null && address!.isNotEmpty) return address!;
    if (locationLabel.isNotEmpty) return locationLabel;
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return 'Kerala';
  }
}

class FeedResponse {
  FeedResponse({
    required this.items,
    required this.total,
    required this.mix,
    this.page = 1,
  });

  final List<ReportModel> items;
  final int total;
  final FeedMixInfo mix;
  final int page;

  factory FeedResponse.fromJson(Map<String, dynamic> json) => FeedResponse(
        items: (json['items'] as List)
            .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        mix: FeedMixInfo.fromJson(json['mix'] as Map<String, dynamic>),
        page: json['page'] as int? ?? 1,
      );
}
