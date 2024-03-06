import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_voice_processor_example/bhashini/bhashini_service.dart';
import 'package:flutter_voice_processor_example/bhashini/demo_content.dart';

class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({Key? key}) : super(key: key);

  @override
  _SelectLanguageScreenState createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  String buttonText = 'Continue';
  String selectedLanguageCode = 'en';

  final Map<String, dynamic> languages = {
    'hi': 'हिन्दी', // Hindi
    'en': 'English',
    'bn': 'বাংলা', // Bengali
    'ta': 'தமிழ்', // Tamil
    'pa': 'ਪੰਜਾਬੀ', // Punjabi

    // Add other languages here
  };

  final Map selectedLng = {
    'continue': {
      'hi': 'जारी रखें', // Hindi for "Continue"
      'en': 'Continue',
      'bn': 'চালিয়ে যাওয়া', // Bengali for "Continue"
      'ta': 'தொடர்செய்', // Tamil for "Continue"
      'pa': 'ਜਾਰੀ ਰੱਖੋ', // Punjabi for "Continue"
    }
  };

  void _onLanguageSelected(String languageCode) {
    setState(() {
      selectedLanguageCode = languageCode;
      // Correctly access the "Continue" translation for the selected language
      buttonText = selectedLng['continue'][languageCode] ?? 'Continue';
    });
  }

  final String demoTitle = 'Agricultural Content';
  final String demoContent =
      'Agriculture is a broad field that encompasses the cultivation of plants and the rearing of animals for food, fiber, medicinal plants, and other products used to sustain and enhance human life. It plays a crucial role in the global economy and is a significant source of livelihood for millions of people worldwide.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 14,
            child: ListView.builder(
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final languageCode = languages.keys.elementAt(index);
                final isSelected = languageCode ==
                    selectedLanguageCode; // Assuming you have a variable to track the selected language
                return ListTile(
                  title: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : Colors.white, // Change color based on selection
                      border: Border.all(
                        width: 1,
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      child: Text(languages[languageCode]!),
                    ),
                  ),
                  onTap: () => _onLanguageSelected(languageCode),
                );
              },
            ),
          ),
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  print(selectedLanguageCode);
                  await sendTranslationRequest(demoTitle, selectedLanguageCode)
                      .then((value) {
                    print(value);
                    final json = jsonDecode(value);
                    final t =
                        json["pipelineResponse"][0]["output"][0]["target"];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DemoContentScreen(
                          demoTitle: t,
                          demoContent: demoContent,
                        ),
                      ),
                    );
                  });
                },
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      ),
    );
  }
}
