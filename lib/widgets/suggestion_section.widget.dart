import 'package:flutter/material.dart';

import '../models/mention_data.model.dart';

class SuggestionSection extends StatelessWidget {
  final int currentMentionIndex;
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

  const SuggestionSection({
    super.key,
    required this.itemHeight,
    required this.addMention,
    required this.suggestionList,
    required this.currentMentionIndex,
    this.scrollController,
    this.margin,
    this.decoration,
    this.padding,
    this.borderRadius,
    this.color,
    this.itemBuilder,
    this.dividerBetweenItems = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(minHeight: itemHeight, maxHeight: itemHeight * 4),
      height: itemHeight * (suggestionList.length + 1),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration ??
          BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              color: color ?? Colors.white),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          ...suggestionList.asMap().entries.map((entry) {
            var index = entry.key;
            var mention = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => addMention(mention.display),
                  child: itemBuilder?.call(
                          index, mention, currentMentionIndex) ??
                      SizedBox(
                        width: double.infinity,
                        height: itemHeight,
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                ),
                index != suggestionList.length - 1 && dividerBetweenItems!
                    ? const Divider()
                    : const SizedBox(),
              ],
            );
          })
        ],
      ),
    );
  }
}
