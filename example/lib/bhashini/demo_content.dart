import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'answer_button.dart';

class DemoContentScreen extends StatelessWidget {
  const DemoContentScreen({
    Key? key,
    required this.demoTitle,
    required this.demoContent,
    required this.assignment,
    required this.question,
    required this.answer,
  }) : super(key: key);
  final String demoTitle;
  final String demoContent;
  final String assignment;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              utf8.decode(demoTitle.runes.toList()),
              style: GoogleFonts.anekDevanagari(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              utf8.decode(demoContent.runes.toList()),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              utf8.decode(assignment.runes.toList()),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300]),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    margin: EdgeInsets.only(top: 20),
                    child: Text(
                      utf8.decode(question.runes.toList()),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: AnswerButton(
                    answer: answer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
