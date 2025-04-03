class FaqItem {
  final String question;
  final String answer;

  const FaqItem({
    required this.question,
    required this.answer,
  });
}

class FaqCategory {
  final String title;
  final List<FaqItem> items;

  const FaqCategory({
    required this.title,
    required this.items,
  });
}