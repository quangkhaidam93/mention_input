import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mention_input/controllers/mention_input.controller.dart';
import 'package:mention_input/mention_input.dart';
import 'package:mention_input/widgets/suggestion_section.widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var submitByEnter = true;

  final data1 = [
    MentionData(id: "1", display: "react"),
    MentionData(id: "2", display: "javascript"),
    MentionData(id: "3", display: "nodejs"),
    MentionData(id: "4", display: "angular"),
    MentionData(id: "5", display: "vue"),
  ];

  final data2 = [
    MentionData(id: "1", display: "flutter"),
    MentionData(id: "2", display: "react_native"),
    MentionData(id: "3", display: "native_script"),
  ];

  var controller = MentionInputController();

  bool isData1 = true;

  late List<MentionData> mentionData;
  late ScrollController suggestionScrollController;
  late SuggestionSectionController suggestionSectionController;

  @override
  void initState() {
    super.initState();

    suggestionScrollController = ScrollController();
    suggestionSectionController = SuggestionSectionController();
    mentionData = data1;
  }

  void changeDataSet() {
    setState(() {
      mentionData = isData1 ? data2 : data1;
      isData1 = !isData1;
    });

    controller.clearText();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Portal(
        child: Scaffold(
          body: Center(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        // We only care about key down events for this logic.
                        if (event is! KeyDownEvent) return;

                        // Check for Shift + Enter combination
                        if (HardwareKeyboard.instance.isShiftPressed &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          setState(() {
                            submitByEnter = false;
                          });

                          controller.insertNewLine();

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.focusInput();
                          });
                        }

                        if (!HardwareKeyboard.instance.isShiftPressed &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          setState(() {
                            submitByEnter = true;
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.clearText();
                            controller.focusInput();
                          });
                        }
                      },
                      child: Focus(
                        onKeyEvent: (node, event) {
                          // Only act on key down events to avoid duplicate (down + up) prints
                          if (event is! KeyDownEvent) {
                            return KeyEventResult.ignored;
                          }
                          // Prevent the default behavior of the Enter key
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            print("khaidq: arrow up pressed");

                            suggestionSectionController.onPrevious();

                            return KeyEventResult.handled;
                          }

                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowDown) {
                            print("khaidq: arrow down pressed");

                            suggestionSectionController.onNext();

                            return KeyEventResult.handled;
                          }

                          return KeyEventResult.ignored;
                        },
                        child: MentionInput(
                          itemHeight: 60,
                          suggestionSectionController:
                              suggestionSectionController,
                          suggestionScrollController:
                              suggestionScrollController,
                          submitByEnter: submitByEnter,
                          // shouldHideRightWidgets: false,
                          rightWidgets: const [
                            VerticalDivider(
                              thickness: 2,
                              indent: 8,
                              endIndent: 8,
                            ),
                            Icon(Icons.access_alarm),
                            SizedBox(
                              width: 12,
                            )
                          ],
                          itemBuilder: (index, data, highlightIndex) =>
                              Container(
                            height: 60,
                            color: index == highlightIndex
                                ? Colors.cyan
                                : Colors.transparent,
                            width: double.infinity,
                            key: ValueKey(data.id),
                            child: Text(
                              data.display,
                              style: TextStyle(
                                  color: index == highlightIndex
                                      ? Colors.green
                                      : Colors.brown),
                            ),
                          ),
                          sendIcon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.share_location)),
                          controller: controller,
                          mentions: [
                            Mention(
                                triggerAnnotation: "@",
                                highlightStyle: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600),
                                data: [...mentionData])
                          ],
                          textFieldContainerPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          textFieldContainerColor: Colors.amberAccent,
                          textFieldContainerBorderRadius:
                              const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12)),
                          suggestionContainerColor: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: changeDataSet,
                        child: const Text("Change data")),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () {
                          controller.setText("New text added");
                          controller.focusInput();
                        },
                        child: const Text("Add text to input")),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
