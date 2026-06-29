import 'package:shared_preferences/shared_preferences.dart';

class GuestLocationPrefs {
  static const _lat = 'guest_lat';
  static const _lng = 'guest_lng';
  static const _ward = 'guest_ward';
  static const _municipality = 'guest_municipality';
  static const _district = 'guest_district';

  static Future<GuestLocation?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_lat);
    final lng = prefs.getDouble(_lng);
    final ward = prefs.getString(_ward);
    final municipality = prefs.getString(_municipality);
    final district = prefs.getString(_district);
    if (lat == null && lng == null && ward == null && municipality == null && district == null) {
      return null;
    }
    return GuestLocation(
      latitude: lat,
      longitude: lng,
      ward: ward,
      municipality: municipality,
      district: district,
    );
  }

  static Future<void> save(GuestLocation loc) async {
    final prefs = await SharedPreferences.getInstance();
    if (loc.latitude != null) {
      await prefs.setDouble(_lat, loc.latitude!);
    } else {
      await prefs.remove(_lat);
    }
    if (loc.longitude != null) {
      await prefs.setDouble(_lng, loc.longitude!);
    } else {
      await prefs.remove(_lng);
    }
    if (loc.ward != null && loc.ward!.isNotEmpty) {
      await prefs.setString(_ward, loc.ward!);
    } else {
      await prefs.remove(_ward);
    }
    if (loc.municipality != null && loc.municipality!.isNotEmpty) {
      await prefs.setString(_municipality, loc.municipality!);
    } else {
      await prefs.remove(_municipality);
    }
    if (loc.district != null && loc.district!.isNotEmpty) {
      await prefs.setString(_district, loc.district!);
    } else {
      await prefs.remove(_district);
    }
  }
}

class GuestLocation {
  GuestLocation({this.latitude, this.longitude, this.ward, this.municipality, this.district});

  final double? latitude;
  final double? longitude;
  final String? ward;
  final String? municipality;
  final String? district;

  bool get isSet =>
      latitude != null || longitude != null || (ward?.isNotEmpty ?? false) || (municipality?.isNotEmpty ?? false) || (district?.isNotEmpty ?? false);

  String get label {
    final parts = [ward, municipality, district].whereType<String>().where((e) => e.isNotEmpty);
    return parts.join(' · ');
  }
}
