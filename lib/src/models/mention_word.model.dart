
import 'package:flutter/material.dart';

class MentionWord {
  MentionWord({
    required this.trigger,
    this.style,
    this.id,
  });

  TextStyle? style;
  String? id;
  String trigger;
}
