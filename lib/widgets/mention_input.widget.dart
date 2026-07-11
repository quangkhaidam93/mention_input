part of mention_input;

// ignore: constant_identifier_names
const DEFAULT_ITEM_HEIGHT = 40.0;

enum SuggestionAlignment {
  top,
  bottom,
}

// ignore: must_be_immutable
class MentionInput extends StatefulWidget {
  // Properties for Suggestion Container
  Color? suggestionContainerColor;
  EdgeInsetsGeometry? suggestionContainerPadding;
  EdgeInsetsGeometry? suggestionContainerMargin;
  Decoration? suggestionContainerDecoration;
  SuggestionAlignment suggestionAlignment;
  BorderRadius? suggestionContainerBorderRadius;

  // Properties for Suggestion Item
  double itemHeight;
  bool? dividerBetweenItems;
  Widget Function(int index, MentionData data, int highlightIndex)? itemBuilder;

  // Properties for Text Field Container
  EdgeInsetsGeometry? textFieldContainerPadding;
  Color? textFieldContainerColor;
  BorderRadius? textFieldContainerBorderRadius;
  Decoration? textFieldContainerDecoration;

  // Properties for Text Field
  String? placeHolder;
  bool? autoFocus;
  bool clearTextAfterSent;
  double leftInputMargin;
  double rightInputMargin;
  List<Widget>? leftWidgets;
  List<Widget>? rightWidgets;
  bool shouldHideLeftWidgets;
  bool shouldHideRightWidgets;
  Function(String value)? onChanged;
  Color? cursorColor;
  TextInputType? keyboardType;
  int? minLines;
  int? maxLines;
  int? maxLength;
  TextStyle? style;
  TextAlign? textAlign;
  TextAlignVertical? textAlignVertical;
  TextCapitalization? textCapitalization;
  TextDirection? textDirection;
  bool? submitByEnter;
  ScrollController? suggestionScrollController;
  bool autoHandleArrowKeys;

  // Data properties
  List<Mention> mentions;

  // Controller
  MentionInputController? controller;

  // Send Button
  Function? onSend;
  bool hasSendButton;
  Widget? sendIcon;

  MentionInput(
      {super.key,
      required this.mentions,
      this.controller,
      this.suggestionContainerColor,
      this.suggestionContainerPadding,
      this.suggestionContainerMargin,
      this.suggestionContainerDecoration,
      this.suggestionContainerBorderRadius,
      this.suggestionAlignment = SuggestionAlignment.top,
      this.placeHolder,
      this.autoFocus,
      this.clearTextAfterSent = true,
      this.leftWidgets,
      this.rightWidgets,
      this.leftInputMargin = 8,
      this.rightInputMargin = 8,
      this.itemHeight = DEFAULT_ITEM_HEIGHT,
      this.dividerBetweenItems = true,
      this.onSend,
      this.hasSendButton = true,
      this.textFieldContainerBorderRadius,
      this.textFieldContainerColor,
      this.textFieldContainerDecoration,
      this.textFieldContainerPadding,
      this.sendIcon,
      this.itemBuilder,
      this.shouldHideLeftWidgets = false,
      this.shouldHideRightWidgets = false,
      this.onChanged,
      this.cursorColor,
      this.keyboardType,
      this.minLines,
      this.maxLines,
      this.maxLength,
      this.style,
      this.textAlign,
      this.textAlignVertical,
      this.textCapitalization,
      this.textDirection,
      this.submitByEnter,
      this.suggestionScrollController,
      this.autoHandleArrowKeys = false});

  @override
  State<MentionInput> createState() => _MentionInputState();
}

class _MentionInputState extends State<MentionInput> {
  bool isSuggestionsVisible = false;
  late MentionInputTextEditingController _controller;
  List<MentionData> suggestionList = [];
  SelectionWord? selectionWord;
  late FocusNode focusNode;
  AllMentionWords allMentionWords = {};
  late String allTriggerAnnotations;
  bool shouldShowSendButton = false;
  int currentMentionIndex = 0;

  void updateAllMentionWords() {
    for (var mention in widget.mentions) {
      for (var mentionWord in mention.data) {
        allMentionWords["${mention.triggerAnnotation}${mentionWord.display}"] =
            MentionWord(
          style: mention.highlightStyle,
          id: mentionWord.id,
          trigger: mention.triggerAnnotation,
        );
      }
    }
  }

  void showSuggestions() {
    setState(() {
      isSuggestionsVisible = true;
    });
  }

  void hideSuggestions() {
    setState(() {
      isSuggestionsVisible = false;
    });
  }

  void _suggestionListener() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        shouldShowSendButton = true;
      });
    } else {
      setState(() {
        shouldShowSendButton = false;
      });
    }

    widget.onChanged?.call(_controller.text);

    final cursorPos = _controller.selection.baseOffset;
    final fullText = _controller.text;

    if (fullText.isNotEmpty && cursorPos > 0) {
      var leftPos = cursorPos - 1;
      var rightPos = cursorPos - 1;

      var gotWord = false;

      while (!gotWord) {
        final leftChar = fullText[leftPos];
        final rightChar = fullText[rightPos];

        var gotStartIdxOfWord = (leftChar == " " || leftPos == 0);
        var gotEndIdxOfWord =
            (rightChar == " " || rightPos == fullText.length - 1);

        gotWord = gotStartIdxOfWord && gotEndIdxOfWord;

        if (!gotStartIdxOfWord) leftPos = max(0, leftPos - 1);
        if (!gotEndIdxOfWord) {
          rightPos = min(fullText.length - 1, rightPos + 1);
        }
      }

      final startIdxOfWord =
          leftPos == 0 && fullText[leftPos] != " " ? 0 : leftPos;
      final endIdxOfWord = rightPos + 1;

      final selectingWord =
          fullText.substring(startIdxOfWord, endIdxOfWord).trim();

      if (selectingWord
          .toLowerCase()
          .startsWith(RegExp(allTriggerAnnotations))) {
        final currentAnnotation = selectingWord[0];
        final word = selectingWord.substring(1);

        // TODO: Maybe implement debounce below this line

        suggestionList = widget.mentions
            .firstWhere(
                (mention) => mention.triggerAnnotation == currentAnnotation)
            .data
            .where((mentionData) {
              final query = _normalizeString(word);
              if (query.isEmpty) return true;

              final display = _normalizeString(mentionData.display);
              return display.contains(query);
            })
            .toList();

        currentMentionIndex = 0;

        if (suggestionList.isNotEmpty) {
          selectionWord = SelectionWord(
              text: selectingWord,
              startIdx: startIdxOfWord,
              endIdx: endIdxOfWord);
          showSuggestions();
        } else {
          hideSuggestions();
        }
      } else {
        hideSuggestions();
      }
    } else {
      hideSuggestions();
    }
  }

  void addMention(String replaceText) {
    if (selectionWord == null) return;

    final annotation = selectionWord!.text[0];
    _controller.text = _controller.value.text.replaceRange(
        selectionWord!.startIdx == 0 ? 0 : selectionWord!.startIdx + 1,
        selectionWord!.endIdx,
        "$annotation$replaceText ");

    final startIdx =
        selectionWord!.startIdx == 0 ? 1 : selectionWord!.startIdx + 2;

    final currentCursor = startIdx + replaceText.length + 1;

    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: currentCursor));

    focusNode.requestFocus();

    selectionWord = null;
  }

  void onArrowDownKeyPressed() {
    if (currentMentionIndex < suggestionList.length - 1) {
      widget.suggestionScrollController!.animateTo(
          widget.suggestionScrollController!.offset + widget.itemHeight,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut);

      setState(() {
        currentMentionIndex = currentMentionIndex + 1;
      });
    } else {
      widget.suggestionScrollController!.animateTo(0,
          duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);

      setState(() {
        currentMentionIndex = 0;
      });
    }
  }

  void onArrowUpKeyPressed() {
    if (currentMentionIndex == 0) {
      return;
    }

    widget.suggestionScrollController!.animateTo(
        widget.suggestionScrollController!.offset - widget.itemHeight,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut);

    setState(() {
      currentMentionIndex = currentMentionIndex - 1;
    });
  }

  @override
  void initState() {
    super.initState();

    updateAllMentionWords();

    _controller = MentionInputTextEditingController(allMentionWords);

    _controller.addListener(_suggestionListener);

    if (widget.controller != null) {
      widget.controller!.clearText = () {
        _controller.clear();
      };

      widget.controller!.getText = () {
        return _controller.text;
      };

      widget.controller!.focusInput = () {
        focusNode.requestFocus();
      };

      widget.controller!.insertNewLine = () {
        final text = _controller.text;
        final selection = _controller.selection;

        // More robust check to prevent double newlines
        // Check if cursor is at a newline or if previous character is newline
        if (selection.start > 0 && text[selection.start - 1] == '\n') {
          return;
        }

        // Also check if we're at the start of a line (after a newline)
        if (selection.start < text.length && text[selection.start] == '\n') {
          return;
        }

        // Additional check: if selection has range and contains newlines
        if (selection.start != selection.end) {
          final selectedText = text.substring(selection.start, selection.end);
          if (selectedText.contains('\n')) {
            return;
          }
        }

        final newText =
            '${text.substring(0, selection.start)}\n${text.substring(selection.end)}';

        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start + 1),
        );
      };

      widget.controller!.setText = (String text) {
        final currentText = _controller.text;
        final newText = "$currentText ${text.trim()}";

        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      };
    }

    allTriggerAnnotations =
        widget.mentions.map((mention) => mention.triggerAnnotation).join("|");

    focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant MentionInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    updateAllMentionWords();

    _controller.allMentionWords = allMentionWords;
  }

  @override
  void dispose() {
    _controller.removeListener(_suggestionListener);

    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: isSuggestionsVisible,
      anchor: Aligned(
          target: widget.suggestionAlignment == SuggestionAlignment.top
              ? Alignment.topCenter
              : Alignment.bottomCenter,
          follower: widget.suggestionAlignment == SuggestionAlignment.top
              ? Alignment.bottomCenter
              : Alignment.topCenter,
          widthFactor: 1),
      portalFollower: SuggestionSection(
        scrollController: widget.suggestionScrollController,
        currentMentionIndex: currentMentionIndex,
        itemHeight: widget.itemHeight,
        addMention: addMention,
        suggestionList: suggestionList,
        itemBuilder: widget.itemBuilder,
        padding: widget.suggestionContainerPadding,
        margin: widget.suggestionContainerMargin,
        borderRadius: widget.suggestionContainerBorderRadius,
        color: widget.suggestionContainerColor,
        decoration: widget.suggestionContainerDecoration,
        dividerBetweenItems: widget.dividerBetweenItems,
      ),
      child: InputSection(
        controller: _controller,
        onArrowDownPressed: onArrowDownKeyPressed,
        onArrowUpPressed: onArrowUpKeyPressed,
        onAddMention: () {
          addMention(suggestionList[currentMentionIndex].display);
        },
        autoHandleArrowKeys: widget.autoHandleArrowKeys,
        suggestionListVisible: isSuggestionsVisible,
        focusNode: focusNode,
        hasSendButton: widget.hasSendButton,
        shouldShowSendButton: shouldShowSendButton,
        leftInputMargin: widget.leftInputMargin,
        rightInputMargin: widget.rightInputMargin,
        leftWidgets: widget.leftWidgets,
        rightWidgets: widget.rightWidgets,
        autoFocus: widget.autoFocus,
        clearTextAfterSent: widget.clearTextAfterSent,
        onSend: widget.onSend,
        placeHolder: widget.placeHolder,
        padding: widget.textFieldContainerPadding,
        borderRadius: widget.textFieldContainerBorderRadius,
        color: widget.textFieldContainerColor,
        decoration: widget.textFieldContainerDecoration,
        sendIcon: widget.sendIcon,
        shouldHideLeftWidgets: widget.shouldHideLeftWidgets,
        shouldHideRightWidgets: widget.shouldHideRightWidgets,
        cursorColor: widget.cursorColor,
        keyboardType: widget.keyboardType,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: widget.style,
        textAlign: widget.textAlign ?? TextAlign.start,
        textAlignVertical: widget.textAlignVertical,
        textCapitalization:
            widget.textCapitalization ?? TextCapitalization.none,
        textDirection: widget.textDirection,
        submitByEnter: widget.submitByEnter,
      ),
    );
  }
}

String _normalizeString(String text) {
  String str = text.toLowerCase();

  const vietnameseMap = {
    'a': 'áàạảãâấầậẩẫăằắặẳẵ',
    'e': 'éèẹẻẽêềếệểễ',
    'i': 'íìịỉĩ',
    'o': 'óòọỏõôồốộổỗơờớợởỡ',
    'u': 'úùụủũưừứựửữ',
    'y': 'ýỳỵỷỹ',
    'd': 'đ',
  };

  vietnameseMap.forEach((nonAccented, accentedGroup) {
    for (int i = 0; i < accentedGroup.length; i++) {
      str = str.replaceAll(accentedGroup[i], nonAccented);
    }
  });

  str = str.replaceAll(RegExp(r'[^a-z0-9]'), '');

  return str;
}
