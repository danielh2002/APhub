import 'package:aphub/models/lecturer_faq_model.dart';
import 'package:flutter/material.dart';

class LecturerFaqPage extends StatelessWidget {
  final String tpNumber;
  const LecturerFaqPage({super.key, required this.tpNumber});

  // FAQ Data (could be moved to a separate service file)
  static const List<FaqCategory> _faqCategories = [
    FaqCategory(
      title: "Booking",
      items: [
        FaqItem(
          question: "How do I book a venue?",
          answer: "Go to the 'Bookings' page, and press the 'Book' button.",
        ),
        FaqItem(
          question: "Can I see my current bookings?",
          answer:
              "Current bookings are displayed at the 'My Bookings' section.",
        ),
      ],
    ),
    FaqCategory(
      title: "Cancellations",
      items: [
        FaqItem(
          question: "Can I cancel a booking?",
          answer:
              "Yes, before the session starts. Ongoing bookings cannot be canceled.",
        ),
        FaqItem(
          question: "Will I be penalized for cancellations?",
          answer: "Currently, No.",
        ),
      ],
    ),
    FaqCategory(
      title: "Viewing & History",
      items: [
        FaqItem(
          question: "Where can I see my past bookings?",
          answer:
              "Go to the 'History' page to view past and canceled bookings.",
        ),
      ],
    ),
    FaqCategory(
      title: "Support",
      items: [
        FaqItem(
          question: "Who do I contact for urgent issues?",
          answer: "Reach out to support at admin@apu.com.",
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqCategories.length,
        itemBuilder: (context, categoryIndex) {
          final category = _faqCategories[categoryIndex];
          return _buildCategoryTile(category);
        },
      ),
    );
  }

  Widget _buildCategoryTile(FaqCategory category) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        iconColor: Colors.pink,
        collapsedIconColor: Colors.white,
        title: Text(
          category.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: category.items.map((faq) => _buildFaqTile(faq)).toList(),
      ),
    );
  }

  Widget _buildFaqTile(FaqItem faq) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        iconColor: Colors.pink,
        collapsedIconColor: Colors.white,
        title: Text(
          faq.question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Text(
              faq.answer,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
