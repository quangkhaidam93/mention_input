import 'package:flutter/services.dart';

class MentionInputFormatter implements TextInputFormatter {
  final List<String> mentionWords;
  final String? pattern;

  MentionInputFormatter(this.mentionWords)
      : pattern = mentionWords.isNotEmpty
            ? "(${mentionWords.map((key) => RegExp.escape(key)).join('|')})"
            : null;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (pattern == null) return newValue;

    // Check if text was deleted
    if (newValue.text.length < oldValue.text.length) {
      final regExp = RegExp(pattern!);
      final matches = regExp.allMatches(oldValue.text);

      // Find the range of the deleted text
      int deletedStart = newValue.selection.baseOffset;
      if (deletedStart < 0) {
          deletedStart = oldValue.selection.baseOffset - (oldValue.text.length - newValue.text.length);
      }
      int deletedEnd = deletedStart + (oldValue.text.length - newValue.text.length);

      // Check if this deletion intersects with any mention in the old text
      for (final match in matches) {
        // If the deletion happened inside a mention or at the end of a mention
        if (deletedEnd > match.start && deletedStart < match.end) {
          // This mention was tampered with! Remove the whole mention.
          // The new text should have the entire match removed.
          final newText = oldValue.text.replaceRange(match.start, match.end, '');
          
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: match.start),
          );
        }
      }
    }

    return newValue;
  }
}
