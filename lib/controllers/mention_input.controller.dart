typedef GetTextMethod = String Function();
typedef FocusInput = void Function();
typedef InsertNewLine = void Function();
typedef SetTextMethod = void Function(String text);

class MentionInputController {
  late Function clearText;
  late GetTextMethod getText;
  late FocusInput focusInput;
  late InsertNewLine insertNewLine;
  late SetTextMethod setText;
}
