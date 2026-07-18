# Mention Input

---

> [!WARNING]
> **BREAKING CHANGE (v2.0.0)**: `MentionInput` has been completely rewritten as a **headless widget**. All UI-specific properties (like `suggestionContainerColor`, `textFieldContainerPadding`, `sendIcon`, etc.) have been removed. 
> Instead, `MentionInput` now uses a `builder` pattern, giving you **100% total control** over the UI (e.g., rendering suggestion lists in an `OverlayPortal`, inline menus, bottom sheets, or anywhere else). You are responsible for rendering your own `TextField` and suggestion list using the provided state and controller.

***Summary:** A powerful, highly customizable Flutter mention input widget. Inspired by flutter_mentions of [fayeed](https://pub.dev/packages/flutter_mentions).*

## Features
- **Headless UI**: Build your own Text Fields, chat inputs, and suggestion dropdowns exactly how you want them.
- **Custom Search Fields**: Match mentions not just by their display name, but by custom fields (e.g., username, email, phone).
- **Custom Matchers**: Support for exact prefix matching (e.g., `/cmd` commands) or any custom logic.
- **Delete Full Mention**: Optional setting to delete an entire mention chip at once when backspace is pressed.
- **Custom Span Builder**: Render mentions exactly how you want inside the text field (e.g. as custom containers/chips with interactive 'X' buttons).
- **Vietnamese Support**: Seamlessly searches ignoring Vietnamese diacritics and accents.

## How to install

---

### 1. `pubspec.yaml`

```yaml
dependencies: 
  mention_input: ^2.0.0
```

### 2. Flutter CLI

```bash
flutter pub add mention_input
```

## Basic Usage

---

With the new headless architecture, you provide a `builder` that returns your UI.

```dart
MentionInput(
  mentions: [
    Mention(
      triggerAnnotation: "@",
      highlightStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      data: [
        MentionData(id: "1", display: "John Doe"),
        MentionData(id: "2", display: "Alice Smith"),
      ],
    ),
  ],
  builder: (context, controller, manager, state) {
    return Column(
      children: [
        // 1. Render Suggestions if visible
        if (state.isSuggestionVisible)
          ListView.builder(
            shrinkWrap: true,
            itemCount: state.suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = state.suggestions[index];
              return ListTile(
                title: Text(suggestion.display),
                onTap: () => manager.addMention(controller, suggestion),
              );
            },
          ),
          
        // 2. Render your TextField
        TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Type @ to mention..."),
        ),
      ],
    );
  },
)
```

## Properties

---

### `MentionInput` Properties

| Property | Description | Data Type | Default Value | Required? |
| ----------- | ----------- | ----------- | ----------- | ----------- |
| mentions | List of mention configurations (triggers, styles, matchers, and data). | `List<Mention>` | | * |
| builder | A builder function that provides the `BuildContext`, `MentionInputTextEditingController`, `MentionManager`, and `MentionState` to construct your UI. | `MentionWidgetBuilder` | | * |
| controller | Custom controller. If not provided, one is created automatically. | `MentionInputTextEditingController?`| null | |
| focusNode | Focus node for the text field. | `FocusNode?` | null | |
| searchKeys | The keys in `MentionData` (either 'display' or keys inside 'customData') to search against. | `List<String>` | `['display']` | |
| replaceWithMatchedText | If true, inserts the matched text field instead of always inserting the 'display' text. | `bool` | `true` | |

### `MentionInputTextEditingController` Properties

This custom `TextEditingController` powers the mention highlighting and backspace behavior.

| Property | Description | Data Type | Default Value |
| ----------- | ----------- | ----------- | ----------- |
| deleteFullMention | If true, pressing backspace inside a mention will delete the entire mention block at once (like a chip). | `bool` | `false` |
| customSpanBuilder | A custom builder for rendering mentions as inline spans (e.g. for chips with an X button). Overrides default highlighting. | `InlineSpan Function(String matchedText, MentionWord mention)?` | null |

## Models

---

### `Mention`

```dart
String triggerAnnotation;
List<MentionData> data;
TextStyle? highlightStyle;
MentionMatcher matcher; // e.g. BasicMentionMatcher() or ExactPrefixMatcher()
```

### `MentionData`

```dart
String id;
String display;
String? imageUrl;
Map<String, dynamic>? customData;
```

## Examples

Check the `/example` folder for 5 extensive examples demonstrating:
1. **Chat Dropdown & Send**: Using `OverlayPortal` to render suggestions floating above the keyboard.
2. **Command Matcher**: Using `/cmd` exact prefix matching.
3. **Basic Matcher**: Standard `@` mentions.
4. **Custom Fields Matcher**: Searching by `@username` or `@email` using custom data fields.
5. **Chip with X Button**: Using `customSpanBuilder` and `deleteFullMention: true` to render interactive chips inside the text field.

## References

---

`flutter_mentions`: [fayeed](https://pub.dev/packages/flutter_mentions)