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
  Widget Function(int index, MentionData data)? itemBuilder;

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
      this.textDirection});

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
            .where((mention) => mention.display.contains(word))
            .toList();

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

    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length));

    focusNode.requestFocus();

    selectionWord = null;
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
      ),
    );
  }
}
