import 'package:flutter/material.dart';
import '../core/mention_matcher.dart';
import 'mention_data.model.dart';

class Mention {
  Mention({
    required this.triggerAnnotation,
    this.data = const [],
    this.highlightStyle,
    MentionMatcher? matcher,
  }) : matcher = matcher ?? StringSimilarityMatcher();

  final String triggerAnnotation;
  final List<MentionData> data;
  final TextStyle? highlightStyle;

  /// The matcher to use for fuzzy search. Defaults to StringSimilarityMatcher.
  final MentionMatcher matcher;
}
