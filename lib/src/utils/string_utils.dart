String normalizeString(String text) {
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
