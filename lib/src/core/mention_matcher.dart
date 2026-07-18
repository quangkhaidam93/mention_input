import 'package:string_similarity/string_similarity.dart';
import '../models/mention_data.model.dart';
import '../utils/string_utils.dart';

abstract class MentionMatcher {
  /// Returns the matched string if a match is found, otherwise returns null.
  String? match(String query, MentionData data, List<String> searchKeys);
}

class StringSimilarityMatcher implements MentionMatcher {
  final double threshold;

  StringSimilarityMatcher({this.threshold = 0.3});

  @override
  String? match(String query, MentionData data, List<String> searchKeys) {
    if (query.isEmpty) {
      if (searchKeys.isNotEmpty) {
        if (searchKeys.first == 'display') return data.display;
        if (data.customData?.containsKey(searchKeys.first) == true) {
          return data.customData![searchKeys.first]?.toString();
        }
      }
      return data.display;
    }

    final normalizedQuery = normalizeString(query);

    for (final key in searchKeys) {
      String? value;
      if (key == 'display') {
        value = data.display;
      } else if (data.customData != null && data.customData!.containsKey(key)) {
        value = data.customData![key]?.toString();
      }

      if (value != null) {
        final normalizedValue = normalizeString(value);
        if (normalizedValue.contains(normalizedQuery)) {
            return value;
        }
        
        final similarity = normalizedValue.similarityTo(normalizedQuery);
        if (similarity >= threshold) {
          return value;
        }
      }
    }

    return null;
  }
}
