import 'package:flutter/material.dart';
import '../types/types.dart';
import '../models/mention_word.model.dart';

class MentionInputTextEditingController extends TextEditingController {
  AllMentionWords _allMentionWords = {};
  String? _pattern;
  
  /// If true, when the user presses backspace and the deletion intersects a mention,
  /// the entire mention is deleted at once. Default is false.
  final bool deleteFullMention;

  /// A custom builder for rendering mentions as inline spans (e.g. for chips with an X button).
  /// If provided, this overrides the default [TextSpan] behavior.
  final InlineSpan Function(String matchedText, MentionWord mention)? customSpanBuilder;

  MentionInputTextEditingController({
    AllMentionWords? mapping,
    this.deleteFullMention = false,
    this.customSpanBuilder,
  }) {
    if (mapping != null) {
      allMentionWords = mapping;
    }
  }

  set allMentionWords(AllMentionWords mapping) {
    _allMentionWords = mapping;
    
    if (mapping.isNotEmpty) {
      // Sort keys by length descending to match longest multi-character triggers/displays first
      final keys = mapping.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
      _pattern = "(${keys.map((key) => RegExp.escape(key)).join('|')})";
    } else {
      _pattern = null;
    }
  }

  @override
  set value(TextEditingValue newValue) {
    if (deleteFullMention && _pattern != null && newValue.text.length < text.length) {
      // Find deleted range
      int deletedStart = newValue.selection.baseOffset;
      if (deletedStart < 0) {
        deletedStart = value.selection.baseOffset - (text.length - newValue.text.length);
      }
      int deletedEnd = deletedStart + (text.length - newValue.text.length);

      if (deletedStart >= 0) {
        final regExp = RegExp(_pattern!);
        final matches = regExp.allMatches(text);

        for (final match in matches) {
          // If the deletion intersects with a mention
          if (deletedEnd > match.start && deletedStart < match.end) {
            // Remove the entire mention
            final newText = text.replaceRange(match.start, match.end, '');
            super.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: match.start),
            );
            return;
          }
        }
      }
    }
    
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan(
      {BuildContext? context, TextStyle? style, bool? withComposing}) {
    var children = <InlineSpan>[];

    if (_pattern == null || _pattern == '()') {
      children.add(TextSpan(text: text, style: style));
    } else {
      text.splitMapJoin(
        RegExp('$_pattern'),
        onMatch: (Match match) {
          if (_allMentionWords.isNotEmpty) {
            final matchedText = match[0]!;
            final mention = _allMentionWords[matchedText] ??
                _allMentionWords[_allMentionWords.keys.firstWhere((element) {
                  final reg = RegExp(element);
                  return reg.hasMatch(matchedText);
                })]!;

            if (customSpanBuilder != null) {
              children.add(customSpanBuilder!(matchedText, mention));
            } else {
              children.add(
                TextSpan(
                  text: matchedText,
                  style: style!.merge(mention.style),
                ),
              );
            }
          }

          return '';
        },
        onNonMatch: (String text) {
          children.add(TextSpan(text: text, style: style));
          return '';
        },
      );
    }

    return TextSpan(style: style, children: children);
  }
}
