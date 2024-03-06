import 'dart:convert';
import 'package:http/http.dart' as http;

Future<dynamic> sendRequest(
    {required String base64Audio, required String sourceLanguage}) async {
  var headers = {
    'Accept': '*/*',
    'User-Agent': 'Thunder Client (https://www.thunderclient.com)',
    'Authorization':
        'g4qW4OmNlHZoc8EJTXGBFBMTdSM-N-D60ZotjAwWqPAs9eWhQuL3Yb7EJCOpAtGd',
    'Content-Type': 'application/json'
  };

  var body = json.encode({
    "pipelineTasks": [
      {
        "taskType": "asr",
        "config": {
          "language": {"sourceLanguage": sourceLanguage},
          "serviceId": "ai4bharat/conformer-hi-gpu--t4",
          "audioFormat": "flac",
          "samplingRate": 16000
        }
      }
    ],
    "inputData": {
      "audio": [
        {"audioContent": base64Audio}
      ]
    }
  });

  var response = await http.post(
    Uri.parse('https://dhruva-api.bhashini.gov.in/services/inference/pipeline'),
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    print(utf8.decode(response.body.runes.toList()));
    return utf8.decode(response.body.runes.toList());
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

Future<dynamic> sendTranslationRequest(
    String sourceText, String targetLanguage) async {
  var headers = {
    'Accept': '*/*',
    'User-Agent': 'Thunder Client (https://www.thunderclient.com)',
    'Authorization':
        'g4qW4OmNlHZoc8EJTXGBFBMTdSM-N-D60ZotjAwWqPAs9eWhQuL3Yb7EJCOpAtGd',
    'Content-Type': 'application/json'
  };

  var body = json.encode({
    "pipelineTasks": [
      {
        "taskType": "translation",
        "config": {
          "language": {
            "sourceLanguage": "en",
            "targetLanguage": targetLanguage
          },
          "serviceId": "ai4bharat/indictrans-v2-all-gpu--t4"
        }
      }
    ],
    "inputData": {
      "input": [
        {"source": sourceText}
      ]
    }
  });

  var response = await http.post(
    Uri.parse('https://dhruva-api.bhashini.gov.in/services/inference/pipeline'),
    headers: headers,
    body: body,
  );

  if (response.statusCode == 200) {
    print(response.body);
    return response.body;
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}
