import 'package:flutter/material.dart';
import '../core/mention_manager.dart';
import '../models/mention.model.dart';
import '../controllers/mention_input_text_editing.controller.dart';
import '../types/types.dart';
import '../models/mention_word.model.dart';

typedef MentionWidgetBuilder = Widget Function(
  BuildContext context,
  MentionInputTextEditingController controller,
  MentionManager manager,
  MentionState state,
);

/// A Headless widget that handles tracking mentions and exposing the state to a builder.
class MentionInput extends StatefulWidget {
  final List<Mention> mentions;
  final MentionInputTextEditingController? controller;
  final MentionWidgetBuilder builder;
  final FocusNode? focusNode;
  
  /// The keys in MentionData (either 'display' or keys inside 'customData') to search against.
  /// Defaults to ['display'].
  final List<String> searchKeys;

  /// If true, the MentionInput will insert the text of the field that matched the search query.
  /// If false, it will always insert the [MentionData.display] text.
  /// Default is true.
  final bool replaceWithMatchedText;

  const MentionInput({
    super.key,
    required this.mentions,
    this.controller,
    required this.builder,
    this.focusNode,
    this.searchKeys = const ['display'],
    this.replaceWithMatchedText = true,
  });

  @override
  State<MentionInput> createState() => _MentionInputState();
}

class _MentionInputState extends State<MentionInput> {
  late MentionInputTextEditingController _controller;
  late MentionManager _manager;
  late FocusNode _focusNode;
  
  AllMentionWords _allMentionWords = {};

  @override
  void initState() {
    super.initState();
    _manager = MentionManager(
      mentions: widget.mentions,
      searchKeys: widget.searchKeys,
      replaceWithMatchedText: widget.replaceWithMatchedText,
    );
    _controller = widget.controller ?? MentionInputTextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _updateAllMentionWords();
    _controller.addListener(_textListener);
  }
  
  void _updateAllMentionWords() {
    _allMentionWords = {};
    for (var mention in widget.mentions) {
      for (var mentionData in mention.data) {
        // Always register the display field
        _allMentionWords["${mention.triggerAnnotation}${mentionData.display}"] =
            MentionWord(
          style: mention.highlightStyle,
          id: mentionData.id,
          trigger: mention.triggerAnnotation,
        );

        // If replacing with matched text, register all search keys so they get highlighted in the text field too
        if (widget.replaceWithMatchedText) {
          for (var key in widget.searchKeys) {
            if (key != 'display' && mentionData.customData != null && mentionData.customData!.containsKey(key)) {
              final value = mentionData.customData![key]?.toString();
              if (value != null && value.isNotEmpty) {
                _allMentionWords["${mention.triggerAnnotation}$value"] =
                    MentionWord(
                  style: mention.highlightStyle,
                  id: mentionData.id,
                  trigger: mention.triggerAnnotation,
                );
              }
            }
          }
        }
      }
    }
    _controller.allMentionWords = _allMentionWords;
  }

  void _textListener() {
    _manager.updateText(_controller.text, _controller.selection);
  }

  @override
  void didUpdateWidget(covariant MentionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mentions != oldWidget.mentions || 
        widget.searchKeys != oldWidget.searchKeys ||
        widget.replaceWithMatchedText != oldWidget.replaceWithMatchedText) {
      _manager = MentionManager(
        mentions: widget.mentions,
        searchKeys: widget.searchKeys,
        replaceWithMatchedText: widget.replaceWithMatchedText,
      );
      _updateAllMentionWords();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_textListener);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MentionState>(
      valueListenable: _manager,
      builder: (context, state, child) {
        return widget.builder(context, _controller, _manager, state);
      },
    );
  }
}
