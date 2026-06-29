import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/guest_location_prefs.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/home_api.dart';
import '../models/home_models.dart';

final guestLocationProvider = FutureProvider<GuestLocation?>((ref) async {
  return GuestLocationPrefs.load();
});

final feedProvider = FutureProvider.autoDispose<FeedResponse>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final guestLoc = await ref.watch(guestLocationProvider.future);

  double? lat;
  double? lng;
  String? ward;
  String? municipality;
  String? district;

  if (user?.hasHomeLocation == true) {
    lat = user!.homeLatitude;
    lng = user.homeLongitude;
    ward = user.homeWard;
    municipality = user.homeMunicipality;
    district = user.homeDistrict;
  } else if (guestLoc?.isSet == true) {
    lat = guestLoc!.latitude;
    lng = guestLoc.longitude;
    ward = guestLoc.ward;
    municipality = guestLoc.municipality;
    district = guestLoc.district;
  }

  return ref.watch(homeApiProvider).feed(
        lat: lat,
        lng: lng,
        ward: ward,
        municipality: municipality,
        district: district,
      );
});

final randomQuoteProvider = FutureProvider.autoDispose<QuoteModel>((ref) async {
  return ref.watch(homeApiProvider).randomQuote();
});
