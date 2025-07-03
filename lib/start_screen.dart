import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartScreen extends StatelessWidget {
  const StartScreen(this.startQuiz, {super.key});
  final void Function() startQuiz;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets\\images\\quiz-logo.png',
            height: 270,
            color: const Color.fromARGB(130, 255, 255, 255),
          ),
          SizedBox(
            height: 50,
          ),
          Text(
            'Learn Flutter the fun way!!',
            style: GoogleFonts.varelaRound(
              color: const Color.fromARGB(202, 70, 2, 118),
              fontSize: 20,
            ),
          ),
          SizedBox(
            height: 50,
          ),
          OutlinedButton.icon(
            onPressed: startQuiz,
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
            ),
            label: const Text(
              'Start Quiz',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
