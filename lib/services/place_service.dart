import 'package:google_place/google_place.dart' as gp;

class PlaceService {
  final String apiKey;
  late gp.GooglePlace googlePlace;
  List<gp.AutocompletePrediction> startPredictions = [];
  List<gp.AutocompletePrediction> destinationPredictions = [];

  PlaceService({required this.apiKey}) {
    googlePlace = gp.GooglePlace(apiKey);
  }

  void searchPlaces(String query, void Function(List<gp.AutocompletePrediction>) updatePredictions) async {
    if (query.isNotEmpty) {
      final result = await googlePlace.autocomplete.get(query);
      if (result != null && result.predictions != null) {
        updatePredictions(result.predictions!);
      }
    } else {
      updatePredictions([]);
    }
  }

  Future<gp.DetailsResponse?> getPlaceDetails(String placeId) async {
    return await googlePlace.details.get(placeId);
  }
}