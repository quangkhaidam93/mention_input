import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mention.model.dart';
import '../models/mention_data.model.dart';

class MentionState {
  final bool isSuggestionVisible;
  final List<MentionData> suggestions;
  final Mention? activeMention;
  final String activeQuery;
  final int activeStartIndex;
  final int activeEndIndex;

  const MentionState({
    this.isSuggestionVisible = false,
    this.suggestions = const [],
    this.activeMention,
    this.activeQuery = '',
    this.activeStartIndex = -1,
    this.activeEndIndex = -1,
  });

  MentionState copyWith({
    bool? isSuggestionVisible,
    List<MentionData>? suggestions,
    Mention? activeMention,
    String? activeQuery,
    int? activeStartIndex,
    int? activeEndIndex,
  }) {
    return MentionState(
      isSuggestionVisible: isSuggestionVisible ?? this.isSuggestionVisible,
      suggestions: suggestions ?? this.suggestions,
      activeMention: activeMention ?? this.activeMention,
      activeQuery: activeQuery ?? this.activeQuery,
      activeStartIndex: activeStartIndex ?? this.activeStartIndex,
      activeEndIndex: activeEndIndex ?? this.activeEndIndex,
    );
  }
}

class MentionManager extends ValueNotifier<MentionState> {
  final List<Mention> mentions;
  final List<String> searchKeys;
  final bool replaceWithMatchedText;
  
  final Map<String, String> _matchedTexts = {};

  MentionManager({
    required List<Mention> mentions,
    this.searchKeys = const ['display'],
    this.replaceWithMatchedText = true,
  }) : mentions = List.from(mentions), super(const MentionState()) {
    // Sort mentions by trigger length descending so longer triggers are checked first
    this.mentions.sort((a, b) => b.triggerAnnotation.length.compareTo(a.triggerAnnotation.length));
  }

  void updateText(String text, TextSelection selection) {
    if (text.isEmpty || selection.baseOffset <= 0) {
      _hideSuggestions();
      return;
    }

    final cursorPos = selection.baseOffset;
    var leftPos = cursorPos - 1;
    var rightPos = cursorPos - 1;

    var gotWord = false;

    while (!gotWord) {
      final leftChar = text[leftPos];
      final rightChar = rightPos < text.length ? text[rightPos] : ' ';

      var gotStartIdxOfWord = (leftChar == " " || leftChar == "\n" || leftPos == 0);
      var gotEndIdxOfWord = (rightChar == " " || rightChar == "\n" || rightPos == text.length - 1);

      gotWord = gotStartIdxOfWord && gotEndIdxOfWord;

      if (!gotStartIdxOfWord) leftPos = max(0, leftPos - 1);
      if (!gotEndIdxOfWord) rightPos = min(text.length - 1, rightPos + 1);
    }

    final startIdxOfWord = (leftPos == 0 && text[leftPos] != " " && text[leftPos] != "\n") ? 0 : leftPos;
    final endIdxOfWord = rightPos + 1;

    final selectingWord = text.substring(startIdxOfWord, endIdxOfWord).trimLeft();
    
    // Calculate accurate offset for the trimmed word
    int trimmedStartIdx = startIdxOfWord;
    while (trimmedStartIdx < endIdxOfWord && (text[trimmedStartIdx] == " " || text[trimmedStartIdx] == "\n")) {
      trimmedStartIdx++;
    }
    
    if (selectingWord.isEmpty) {
      _hideSuggestions();
      return;
    }

    for (var mention in mentions) {
      if (selectingWord.toLowerCase().startsWith(mention.triggerAnnotation.toLowerCase())) {
        final query = selectingWord.substring(mention.triggerAnnotation.length);

        final List<MentionData> matchedData = [];
        _matchedTexts.clear();
        for (final data in mention.data) {
          final matchedText = mention.matcher.match(query, data, searchKeys);
          if (matchedText != null) {
            matchedData.add(data);
            _matchedTexts[data.id] = matchedText;
          }
        }

        if (matchedData.isNotEmpty) {
          value = value.copyWith(
            isSuggestionVisible: true,
            suggestions: matchedData,
            activeMention: mention,
            activeQuery: query,
            activeStartIndex: trimmedStartIdx,
            activeEndIndex: endIdxOfWord,
          );
          return;
        }
      }
    }

    _hideSuggestions();
  }

  void _hideSuggestions() {
    if (value.isSuggestionVisible) {
      value = value.copyWith(isSuggestionVisible: false, suggestions: const [], activeMention: null);
    }
  }

  void addMention(TextEditingController controller, MentionData data) {
    if (value.activeMention == null) return;
    
    final trigger = value.activeMention!.triggerAnnotation;
    final currentText = controller.text;
    
    String replaceText = data.display;
    if (replaceWithMatchedText && _matchedTexts.containsKey(data.id)) {
      replaceText = _matchedTexts[data.id]!;
    }
    
    // Replace text from activeStartIndex to activeEndIndex
    final newText = currentText.replaceRange(
      value.activeStartIndex, 
      value.activeEndIndex, 
      "$trigger$replaceText "
    );
    
    controller.text = newText;
    
    // Update cursor position
    final newCursorPos = value.activeStartIndex + trigger.length + replaceText.length + 1;
    controller.selection = TextSelection.fromPosition(TextPosition(offset: newCursorPos));
    
    _hideSuggestions();
  }
}
