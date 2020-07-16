import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioRecognitionHelper {

  // ------------------------- VOICE VARIABLES ------------------------- //

  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = "";
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "";
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  // ------------------------------------------------------------------- //

  //Initialize stt recognition.
  Future<void> initSpeechState() async {
    _hasSpeech = false;
    lastWords = "";
    lastError = "";
    lastStatus = "";

    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale.localeId;
    }

    _hasSpeech = hasSpeech;
  }

  //Sends user message to dialogFlow and gets it's reply.
  Future _dialogFlowRequest({String query}) async {
//    _addMessage(
//        name: 'Bot de mensagem',
//        text: 'Escrevendo...',
//        type: ChatMessageType.received);

    AuthGoogle authGoogle = await AuthGoogle(fileJson: "assets/credentials.json").build();
    Dialogflow dialogflow = Dialogflow(authGoogle: authGoogle, language: "pt-BR");
    AIResponse response = await dialogflow.detectIntent(query);

//    setState(() {
//      _messageList.removeAt(0);
//    });

//    _addMessage(
//        name: 'Bot de mensagem',
//        text: response.getMessage() ?? '',
//        type: ChatMessageType.received);

    FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage('pt_BR');
    flutterTts.setPitch(3);

    //tts the response message.
    await flutterTts.speak(response.getMessage());
  }

  //Starts to listen to device's microphone
  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(
        onResult: (result) {
          lastWords = result.recognizedWords;
        },
        listenFor: Duration(seconds: 10),
        localeId: _currentLocaleId,
//        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true,
        onDevice: true,
        listenMode: ListenMode.confirmation);
  }

  //Sets the result text from listening to lastWords.
  void resultListener(SpeechRecognitionResult result) {
      lastWords = "${result.recognizedWords}";
  }

  //Sound level configuration.
//  void soundLevelListener(double level) {
//    minSoundLevel = min(minSoundLevel, level);
//    maxSoundLevel = max(maxSoundLevel, level);
//    // print("sound level $level: $minSoundLevel - $maxSoundLevel ");
//    setState(() {
//      this.level = level;
//    });
//  }

  //Delay to wait for user's voice recognition
  waitForSpeech(int duration) async {
    await Future.delayed(Duration(seconds: duration), () {});
  }

  //On recognition error.
  void errorListener(SpeechRecognitionError error) {
    // print("Received error status: $error, listening: ${speech.isListening}");
    lastError = "${error.errorMsg} - ${error.permanent}";
  }

  //Sets recognition status.
  void statusListener(String status) {
    lastStatus = "$status";
  }

}