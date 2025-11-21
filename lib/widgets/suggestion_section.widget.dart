import 'package:flutter/material.dart';

import '../models/mention_data.model.dart';

class SuggestionSectionController {
  late VoidCallback onNext;
  late VoidCallback onPrevious;
  late VoidCallback onRevert;
}

class SuggestionSection extends StatefulWidget {
  final double itemHeight;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final BorderRadius? borderRadius;
  final Color? color;
  final Function(String replaceText) addMention;
  final bool? dividerBetweenItems;
  final List<MentionData> suggestionList;
  final Widget Function(int index, MentionData data, int highlightIndex)?
      itemBuilder;
  final ScrollController? scrollController;
  final SuggestionSectionController? controller;

  const SuggestionSection(
      {super.key,
      required this.itemHeight,
      required this.addMention,
      required this.suggestionList,
      this.scrollController,
      this.margin,
      this.decoration,
      this.padding,
      this.borderRadius,
      this.color,
      this.itemBuilder,
      this.dividerBetweenItems = true,
      this.controller});

  @override
  State<SuggestionSection> createState() => _SuggestionSectionState();
}

class _SuggestionSectionState extends State<SuggestionSection> {
  int highlightIndex = 0;

  @override
  void initState() {
    super.initState();

    if (widget.scrollController != null) {
      widget.controller?.onNext = () {
        print("khaidq onNext called");

        if (highlightIndex < widget.suggestionList.length - 1) {
          widget.scrollController!.animateTo(
              widget.scrollController!.offset + widget.itemHeight,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);

          setState(() {
            highlightIndex = highlightIndex + 1;
          });
        } else {
          widget.scrollController!.animateTo(0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);

          setState(() {
            highlightIndex = 0;
          });
        }
      };

      widget.controller?.onPrevious = () {
        if (highlightIndex == 0) {
          return;
        }

        widget.scrollController!.animateTo(
            widget.scrollController!.offset - widget.itemHeight,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut);

        setState(() {
          highlightIndex = highlightIndex - 1;
        });
      };

      widget.controller?.onRevert = () {
        widget.scrollController!.animateTo(0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut);
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          minHeight: widget.itemHeight, maxHeight: widget.itemHeight * 4),
      height: widget.itemHeight * (widget.suggestionList.length + 1),
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 16),
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: widget.decoration ??
          BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              color: widget.color ?? Colors.white),
      child: Scrollbar(
        child: ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.zero,
          children: [
            ...widget.suggestionList.asMap().entries.map((entry) {
              var index = entry.key;
              var mention = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => widget.addMention(mention.display),
                    child: widget.itemBuilder
                            ?.call(index, mention, highlightIndex) ??
                        SizedBox(
                          width: double.infinity,
                          height: widget.itemHeight,
                          child: Row(
                            children: [
                              if (mention.imageUrl != null)
                                CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(mention.imageUrl!),
                                ),
                              const SizedBox(width: 12),
                              Text(
                                mention.display,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                  ),
                  index != widget.suggestionList.length - 1 &&
                          widget.dividerBetweenItems!
                      ? const Divider()
                      : const SizedBox(),
                ],
              );
            })
          ],
        ),
      ),
    );
  }
}
