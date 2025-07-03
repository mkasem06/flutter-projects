import 'package:flutter/material.dart';
import 'package:quiz_app/question_identifier.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryItem extends StatelessWidget {
  const SummaryItem(this.itemData, {super.key});
  final Map<String, Object> itemData;

  @override
  Widget build(context) {
    final isCorrectAnswer =
        itemData['user_answer'] == itemData['correct_answer'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionIdentifier(
            itemData['question_index'] as int,
            isCorrectAnswer,
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemData['question'] as String,
                  style: GoogleFonts.varelaRound(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  itemData['user_answer'] as String,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 92, 15, 128),
                  ),
                ),
                Text(
                  itemData['correct_answer'] as String,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 34, 170, 255),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
