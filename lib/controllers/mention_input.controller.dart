typedef GetTextMethod = String Function();
typedef FocusInput = void Function();

class MentionInputController {
  late Function clearText;
  late GetTextMethod getText;
  late FocusInput focusInput;
}
