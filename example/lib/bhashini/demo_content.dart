import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'answer_button.dart';

class DemoContentScreen extends StatelessWidget {
  const DemoContentScreen(
      {Key? key, required this.demoTitle, required this.demoContent})
      : super(key: key);
  final String demoTitle;
  final String demoContent;

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
              demoTitle,
              style: GoogleFonts.anekDevanagari(),
              // style: TextStyle(
              //   fontSize: 24,
              //   fontWeight: FontWeight.bold,
              //   fontFamily: GoogleFonts.anekDevanagari,
              // ),
            ),
            SizedBox(height: 16),
            Text(
              'Agriculture is a broad field that encompasses the cultivation of plants and the rearing of animals for food, fiber, medicinal plants, and other products used to sustain and enhance human life. It plays a crucial role in the global economy and is a significant source of livelihood for millions of people worldwide.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              'Assignment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300]),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: EdgeInsets.only(top: 20),
                  child: Text(
                    'What is agriculture?',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Spacer(),
                AnswerButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
