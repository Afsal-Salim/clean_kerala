import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api/api_client.dart';
import '../models/captured_photo.dart';
import '../models/home_models.dart';

class HomeApi {
  HomeApi(this._dio);

  final Dio _dio;

  Future<QuoteModel> randomQuote() async {
    final response = await _dio.get('/quotes/random');
    return QuoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FeedResponse> feed({
    int page = 1,
    double? lat,
    double? lng,
    String? ward,
    String? municipality,
    String? district,
  }) async {
    final response = await _dio.get('/reports', queryParameters: {
      'page': page,
      'limit': 20,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (ward != null && ward.isNotEmpty) 'ward': ward,
      if (municipality != null && municipality.isNotEmpty) 'municipality': municipality,
      if (district != null && district.isNotEmpty) 'district': district,
    });
    return FeedResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> createReport({
    required String category,
    required String description,
    double? latitude,
    double? longitude,
    String? address,
    String? wardName,
    String? municipalityName,
    String? districtName,
    required List<CapturedPhoto> images,
  }) async {
    final form = FormData.fromMap({
      'category': category,
      'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null && address.isNotEmpty) 'address': address,
      if (wardName != null && wardName.isNotEmpty) 'ward_name': wardName,
      if (municipalityName != null && municipalityName.isNotEmpty) 'municipality_name': municipalityName,
      if (districtName != null && districtName.isNotEmpty) 'district_name': districtName,
      'image_metadata': jsonEncode(images.map((p) => p.toMetadataJson()).toList()),
    });

    for (final photo in images) {
      final name = photo.file.path.split('/').last;
      form.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(
            photo.file.path,
            filename: name,
            contentType: MediaType('image', 'jpeg'),
          ),
        ),
      );
    }

    final response = await _dio.post('/reports', data: form);
    return (response.data as Map<String, dynamic>)['id'] as String;
  }
}

final homeApiProvider = Provider<HomeApi>((ref) => HomeApi(ref.watch(dioProvider)));
