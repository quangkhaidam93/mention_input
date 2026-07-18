import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mention_input/mention_input.dart';

class ExactPrefixMatcher implements MentionMatcher {
  @override
  String? match(String query, MentionData data, List<String> searchKeys) {
    if (query.isEmpty) {
      if (searchKeys.isNotEmpty) {
        if (searchKeys.first == 'display') return data.display;
        if (data.customData?.containsKey(searchKeys.first) == true) {
          return data.customData![searchKeys.first]?.toString();
        }
      }
      return data.display;
    }
    
    final lowerQuery = query.toLowerCase();
    for (final key in searchKeys) {
      String? value;
      if (key == 'display') {
        value = data.display;
      } else if (data.customData != null && data.customData!.containsKey(key)) {
        value = data.customData![key]?.toString();
      }
      if (value != null && value.toLowerCase().startsWith(lowerQuery)) {
        return value;
      }
    }
    return null;
  }
}

void main() {
  Widget buildTestWidget({
    required List<Mention> mentions,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MentionInput(
          mentions: mentions,
          builder: (context, controller, manager, state) {
            return Column(
              children: [
                if (state.isSuggestionVisible)
                  ...state.suggestions.map((s) => Text(s.display)),
                TextField(controller: controller),
              ],
            );
          },
        ),
      ),
    );
  }

  testWidgets('MentionInput search ignores Vietnamese diacritics/accents', (WidgetTester tester) async {
    final mentions = [
      Mention(
        triggerAnnotation: '@',
        data: [
          MentionData(id: '1', display: 'Nguyễn Văn A'),
          MentionData(id: '2', display: 'Trần Thị B'),
        ],
      ),
    ];

    await tester.pumpWidget(buildTestWidget(mentions: mentions));

    // Focus input and enter text
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);

    // Type '@nguyen' (without accents, lowercase)
    await tester.enterText(inputFinder, '@nguyen');
    await tester.pumpAndSettle();

    // Nguyễn Văn A should be found, Trần Thị B should not
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Trần Thị B'), findsNothing);

    // Type '@tran'
    await tester.enterText(inputFinder, '@tran');
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn A'), findsNothing);
    expect(find.text('Trần Thị B'), findsOneWidget);
  });

  testWidgets('MentionInput search ignores punctuation', (WidgetTester tester) async {
    final mentions = [
      Mention(
        triggerAnnotation: '@',
        data: [
          MentionData(id: '1', display: 'react_native'),
          MentionData(id: '2', display: 'vue-js'),
        ],
      ),
    ];

    await tester.pumpWidget(buildTestWidget(mentions: mentions));

    final inputFinder = find.byType(TextField);

    // Type '@reactnative'
    await tester.enterText(inputFinder, '@reactnative');
    await tester.pumpAndSettle();

    expect(find.text('react_native'), findsOneWidget);
    expect(find.text('vue-js'), findsNothing);

    // Type '@vuejs'
    await tester.enterText(inputFinder, '@vuejs');
    await tester.pumpAndSettle();

    expect(find.text('react_native'), findsNothing);
    expect(find.text('vue-js'), findsOneWidget);
  });

  testWidgets('MentionInput search searches only the display field', (WidgetTester tester) async {
    final mentions = [
      Mention(
        triggerAnnotation: '@',
        matcher: ExactPrefixMatcher(),
        data: [
          MentionData(
            id: 'johndoe123',
            display: 'John Doe',
            customData: {'mention': 'john_custom'},
          ),
          MentionData(
            id: 'smith456',
            display: 'Alice Smith',
            customData: {'username': 'alice_username'},
          ),
        ],
      ),
    ];

    await tester.pumpWidget(buildTestWidget(mentions: mentions));

    final inputFinder = find.byType(TextField);

    // Search by display name (should match)
    await tester.enterText(inputFinder, '@John');
    await tester.pumpAndSettle();
    expect(find.text('John Doe'), findsOneWidget);

    // Search by ID (should not match display field, so finds nothing)
    await tester.enterText(inputFinder, '@smith456');
    await tester.pumpAndSettle();
    expect(find.text('Alice Smith'), findsNothing);

    // Search by customData 'mention' (should not match display field, so finds nothing)
    await tester.enterText(inputFinder, '@john_custom');
    await tester.pumpAndSettle();
    expect(find.text('John Doe'), findsNothing);

    // Search by customData 'username' (should not match display field, so finds nothing)
    await tester.enterText(inputFinder, '@alice_username');
    await tester.pumpAndSettle();
    expect(find.text('Alice Smith'), findsNothing);
  });
}

