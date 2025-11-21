import 'package:flutter/material.dart';

import '../types/types.dart';

class MentionInputTextEditingController extends TextEditingController {
  AllMentionWords _allMentionWords;
  String? _pattern;

  MentionInputTextEditingController(this._allMentionWords)
      : _pattern = _allMentionWords.keys.isNotEmpty
            ? "(${_allMentionWords.keys.map((key) => RegExp.escape(key)).join('|')})"
            : null;

  set allMentionWords(AllMentionWords mapping) {
    _allMentionWords = mapping;

    _pattern = "(${mapping.keys.map((key) => RegExp.escape(key)).join('|')})";
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
            final mention = _allMentionWords[match[0]!] ??
                _allMentionWords[_allMentionWords.keys.firstWhere((element) {
                  final reg = RegExp(element);

                  return reg.hasMatch(match[0]!);
                })]!;

            children.add(
              TextSpan(
                text: match[0],
                style: style!.merge(mention.style),
              ),
            );
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
