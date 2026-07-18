import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mention_input/mention_input.dart';

void main() {
  runApp(const MyApp());
}

/// A custom plugin to show how to override the default StringSimilarityMatcher.
/// This matcher only allows exact prefix matching (ignoring case) on the 'display' field.
class ExactPrefixMatcher implements MentionMatcher {
  @override
  String? match(String query, MentionData data, List<String> searchKeys) {
    if (query.isEmpty) return data.display;
    final lowerQuery = query.toLowerCase();
    
    // For demonstration, we only check the display field regardless of searchKeys
    if (data.display.toLowerCase().startsWith(lowerQuery)) {
      return data.display;
    }
    return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mention Input Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _examples = [
    const ChatDropdownExample(),
    const CommandMatchExample(),
    const BasicMentionExample(),
    const CustomSearchFieldsExample(),
    const ChipWithXButtonExample(),
  ];

  final List<String> _exampleNames = [
    "Chat Dropdown & Send",
    "Command Matcher (/cmd)",
    "Basic Matcher (@)",
    "Custom Fields Matcher (@)",
    "Chip with X Button (@)",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedIndex,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            items: List.generate(
              _exampleNames.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(_exampleNames[index]),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedIndex = value;
                });
              }
            },
          ),
        ),
      ),
      body: _examples[_selectedIndex],
    );
  }
}

/// ---------------------------------------------------------
/// EXAMPLE 1: Command Matcher
/// Uses ExactPrefixMatcher to match commands.
/// ---------------------------------------------------------
class CommandMatchExample extends StatefulWidget {
  const CommandMatchExample({super.key});

  @override
  State<CommandMatchExample> createState() => _CommandMatchExampleState();
}

class _CommandMatchExampleState extends State<CommandMatchExample> {
  final mentions = [
    Mention(
      triggerAnnotation: "/cmd",
      highlightStyle: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
      data: [
        MentionData(id: "1", display: "start"),
        MentionData(id: "2", display: "stop"),
        MentionData(id: "3", display: "restart"),
        MentionData(id: "4", display: "status"),
      ],
      // Inject custom exact matcher
      matcher: ExactPrefixMatcher(),
    ),
  ];

  final focusNode = FocusNode();
  int selectedIndex = 0;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Command Example: Type '/cmd' to trigger an exact-match command menu! Use Arrow Keys to navigate."),
          const SizedBox(height: 12),
          MentionInput(
            mentions: mentions,
            builder: (context, controller, manager, state) {
              if (state.isSuggestionVisible && selectedIndex >= state.suggestions.length) {
                selectedIndex = 0;
              }

              return Column(
                children: [
                  if (state.isSuggestionVisible)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.purple[50],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: state.suggestions.asMap().entries.map((entry) {
                            int index = entry.key;
                            var suggestion = entry.value;

                            return ListTile(
                              tileColor: index == selectedIndex ? Colors.purple.withValues(alpha: 0.2) : Colors.transparent,
                              leading: const Icon(Icons.terminal, color: Colors.purple),
                              title: Text(suggestion.display),
                              onTap: () {
                                manager.addMention(controller, suggestion);
                                setState(() => selectedIndex = 0);
                                focusNode.requestFocus();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (!state.isSuggestionVisible) return KeyEventResult.ignored;

                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() => selectedIndex = (selectedIndex + 1) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() => selectedIndex = (selectedIndex - 1 + state.suggestions.length) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                        if (state.suggestions.isNotEmpty) {
                          manager.addMention(controller, state.suggestions[selectedIndex]);
                          setState(() => selectedIndex = 0);
                          focusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "Enter a message...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.purple, width: 2)
                        ),
                        prefixIcon: const Icon(Icons.chat),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// EXAMPLE 2: Without Search Fields
/// Matches only the display string and uses standard matching.
/// ---------------------------------------------------------
class BasicMentionExample extends StatefulWidget {
  const BasicMentionExample({super.key});

  @override
  State<BasicMentionExample> createState() => _BasicMentionExampleState();
}

class _BasicMentionExampleState extends State<BasicMentionExample> {
  final mentions = [
    Mention(
      triggerAnnotation: "@",
      highlightStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      data: [
        MentionData(id: "1", display: "John Doe"),
        MentionData(id: "2", display: "Alice Smith"),
        MentionData(id: "3", display: "Bob Johnson"),
      ],
    ),
  ];

  final focusNode = FocusNode();
  int selectedIndex = 0;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Basic Example: Type '@' to mention a user. Only searches by their display name."),
          const SizedBox(height: 16),
          MentionInput(
            mentions: mentions,
            builder: (context, controller, manager, state) {
              if (state.isSuggestionVisible && selectedIndex >= state.suggestions.length) {
                selectedIndex = 0;
              }

              return Column(
                children: [
                  if (state.isSuggestionVisible)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: state.suggestions.asMap().entries.map((entry) {
                            int index = entry.key;
                            var suggestion = entry.value;

                            return ListTile(
                              tileColor: index == selectedIndex ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
                              title: Text(suggestion.display),
                              onTap: () {
                                manager.addMention(controller, suggestion);
                                setState(() => selectedIndex = 0);
                                focusNode.requestFocus();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (!state.isSuggestionVisible) return KeyEventResult.ignored;

                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() => selectedIndex = (selectedIndex + 1) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() => selectedIndex = (selectedIndex - 1 + state.suggestions.length) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                        if (state.suggestions.isNotEmpty) {
                          manager.addMention(controller, state.suggestions[selectedIndex]);
                          setState(() => selectedIndex = 0);
                          focusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Enter a message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// EXAMPLE 2: With Search Fields and replaceWithMatchedText
/// Searches across multiple custom fields (e.g. email, username).
/// ---------------------------------------------------------
class CustomSearchFieldsExample extends StatefulWidget {
  const CustomSearchFieldsExample({super.key});

  @override
  State<CustomSearchFieldsExample> createState() => _CustomSearchFieldsExampleState();
}

class _CustomSearchFieldsExampleState extends State<CustomSearchFieldsExample> {
  final mentions = [
    Mention(
      triggerAnnotation: "@",
      highlightStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      data: [
        MentionData(id: "1", display: "John Doe", customData: {'username': 'johnd', 'email': 'john@example.com'}),
        MentionData(id: "2", display: "Alice Smith", customData: {'username': 'alices', 'email': 'alice@example.com'}),
        MentionData(id: "3", display: "Bob Johnson", customData: {'username': 'bobj', 'email': 'bob@example.com'}),
      ],
    ),
  ];

  final focusNode = FocusNode();
  int selectedIndex = 0;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Advanced Example: Type '@' to mention. Try searching for an email like '@alice' or username '@bobj'. Notice how the text field inserts the matched text (like the email) instead of just the display name!"),
          const SizedBox(height: 16),
          MentionInput(
            mentions: mentions,
            searchKeys: const ['display', 'username', 'email'],
            replaceWithMatchedText: true,
            builder: (context, controller, manager, state) {
              if (state.isSuggestionVisible && selectedIndex >= state.suggestions.length) {
                selectedIndex = 0;
              }

              return Column(
                children: [
                  if (state.isSuggestionVisible)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: state.suggestions.asMap().entries.map((entry) {
                            int index = entry.key;
                            var suggestion = entry.value;

                            return ListTile(
                              tileColor: index == selectedIndex ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
                              title: Text(suggestion.display),
                              subtitle: Text("@${suggestion.customData?['username']} - ${suggestion.customData?['email']}"),
                              onTap: () {
                                manager.addMention(controller, suggestion);
                                setState(() => selectedIndex = 0);
                                focusNode.requestFocus();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (!state.isSuggestionVisible) return KeyEventResult.ignored;

                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() => selectedIndex = (selectedIndex + 1) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() => selectedIndex = (selectedIndex - 1 + state.suggestions.length) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                        if (state.suggestions.isNotEmpty) {
                          manager.addMention(controller, state.suggestions[selectedIndex]);
                          setState(() => selectedIndex = 0);
                          focusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Enter a message...",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// EXAMPLE 4: Chat Dropdown & Send
/// Shows how to use OverlayPortal for dropdown selection,
/// Enter to send/clear, and Shift+Enter for new line.
/// ---------------------------------------------------------
class ChatDropdownExample extends StatefulWidget {
  const ChatDropdownExample({super.key});

  @override
  State<ChatDropdownExample> createState() => _ChatDropdownExampleState();
}

class _ChatDropdownExampleState extends State<ChatDropdownExample> {
  final mentions = [
    Mention(
      triggerAnnotation: "@",
      highlightStyle: TextStyle(
        color: Colors.deepOrange, 
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.deepOrange.withValues(alpha: 0.1),
      ),
      data: [
        MentionData(id: "1", display: "John Doe"),
        MentionData(id: "2", display: "Alice Smith"),
        MentionData(id: "3", display: "Bob Johnson"),
      ],
    ),
  ];

  final focusNode = FocusNode();
  int selectedIndex = 0;
  
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Sent message: $text")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Chat Example: Type '@' to show a dropdown overlay.\nPress ENTER to send (or select suggestion).\nPress SHIFT + ENTER to add a new line."),
          const SizedBox(height: 16),
          const Spacer(), // Push input to the bottom like a chat UI
          MentionInput(
            mentions: mentions,
            builder: (context, controller, manager, state) {
              if (state.isSuggestionVisible && selectedIndex >= state.suggestions.length) {
                selectedIndex = 0;
              }
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (state.isSuggestionVisible && !_overlayController.isShowing) {
                  _overlayController.show();
                } else if (!state.isSuggestionVisible && _overlayController.isShowing) {
                  _overlayController.hide();
                }
              });

              return CompositedTransformTarget(
                link: _layerLink,
                child: OverlayPortal(
                  controller: _overlayController,
                  overlayChildBuilder: (context) {
                    return Positioned(
                      width: 300,
                      child: CompositedTransformFollower(
                        link: _layerLink,
                        targetAnchor: Alignment.topCenter,
                        followerAnchor: Alignment.bottomCenter,
                        offset: const Offset(0, -8),
                        child: Material(
                          elevation: 8,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: state.suggestions.length,
                              itemBuilder: (context, index) {
                                var suggestion = state.suggestions[index];
                                return ListTile(
                                  tileColor: index == selectedIndex ? Colors.deepOrange.withValues(alpha: 0.2) : Colors.transparent,
                                  title: Text(suggestion.display),
                                  onTap: () {
                                    manager.addMention(controller, suggestion);
                                    setState(() => selectedIndex = 0);
                                    focusNode.requestFocus();
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;

                      if (state.isSuggestionVisible) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          setState(() => selectedIndex = (selectedIndex + 1) % state.suggestions.length);
                          return KeyEventResult.handled;
                        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          setState(() => selectedIndex = (selectedIndex - 1 + state.suggestions.length) % state.suggestions.length);
                          return KeyEventResult.handled;
                        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                          if (state.suggestions.isNotEmpty) {
                            manager.addMention(controller, state.suggestions[selectedIndex]);
                            setState(() => selectedIndex = 0);
                            focusNode.requestFocus();
                            return KeyEventResult.handled;
                          }
                        }
                      } else {
                        if (event.logicalKey == LogicalKeyboardKey.enter) {
                          if (HardwareKeyboard.instance.isShiftPressed) {
                            // Allow new line
                            return KeyEventResult.ignored;
                          } else {
                            // Send message
                            _sendMessage(controller.text);
                            controller.clear();
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: Colors.deepOrange),
                          onPressed: () {
                            _sendMessage(controller.text);
                            controller.clear();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// EXAMPLE 5: Chip with X Button
/// Demonstrates custom span builder with an interactive X button
/// to delete the full mention, and deleteFullMention behavior.
/// ---------------------------------------------------------
class ChipWithXButtonExample extends StatefulWidget {
  const ChipWithXButtonExample({super.key});

  @override
  State<ChipWithXButtonExample> createState() => _ChipWithXButtonExampleState();
}

class _ChipWithXButtonExampleState extends State<ChipWithXButtonExample> {
  final mentions = [
    Mention(
      triggerAnnotation: "@",
      highlightStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      data: [
        MentionData(id: "1", display: "John Doe"),
        MentionData(id: "2", display: "Alice Smith"),
        MentionData(id: "3", display: "Bob Johnson"),
      ],
    ),
  ];

  final focusNode = FocusNode();
  int selectedIndex = 0;
  
  late final MentionInputTextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = MentionInputTextEditingController(
      deleteFullMention: true, // Delete whole chip on backspace
      customSpanBuilder: (matchedText, mention) {
        return TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Exclude the zero-width space from the text we display
                    Text(
                      matchedText.substring(0, matchedText.length - 1), 
                      style: mention.style,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        // Programmatically delete the mention when X is clicked
                        final currentText = controller.text;
                        final mentionStart = currentText.indexOf(matchedText);
                        if (mentionStart != -1) {
                          final newText = currentText.replaceRange(mentionStart, mentionStart + matchedText.length, '');
                          controller.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: mentionStart),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Chip Example: Type '@' to mention. The mention uses a customSpanBuilder to render as a Chip with an 'X' button! It can be deleted by clicking 'X' or pressing Backspace."),
          const SizedBox(height: 16),
          MentionInput(
            mentions: mentions,
            controller: controller,
            builder: (context, controller, manager, state) {
              if (state.isSuggestionVisible && selectedIndex >= state.suggestions.length) {
                selectedIndex = 0;
              }

              return Column(
                children: [
                  if (state.isSuggestionVisible)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: state.suggestions.asMap().entries.map((entry) {
                            int index = entry.key;
                            var suggestion = entry.value;

                            return ListTile(
                              tileColor: index == selectedIndex ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
                              title: Text(suggestion.display),
                              onTap: () {
                                // IMPORTANT: We append a zero-width space (\u200B) to the suggestion
                                // This gives the text buffer exactly 1 extra character to perfectly match the WidgetSpan!
                                final modifiedSuggestion = MentionData(
                                  id: suggestion.id,
                                  display: "${suggestion.display}\u200B", 
                                  customData: suggestion.customData
                                );
                                manager.addMention(controller, modifiedSuggestion);
                                setState(() => selectedIndex = 0);
                                focusNode.requestFocus();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (!state.isSuggestionVisible) return KeyEventResult.ignored;

                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() => selectedIndex = (selectedIndex + 1) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() => selectedIndex = (selectedIndex - 1 + state.suggestions.length) % state.suggestions.length);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                        if (state.suggestions.isNotEmpty) {
                          var suggestion = state.suggestions[selectedIndex];
                          final modifiedSuggestion = MentionData(
                            id: suggestion.id,
                            display: "${suggestion.display}\u200B", 
                            customData: suggestion.customData
                          );
                          manager.addMention(controller, modifiedSuggestion);
                          setState(() => selectedIndex = 0);
                          focusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Enter a message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
