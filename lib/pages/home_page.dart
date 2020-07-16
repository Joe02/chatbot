import 'dart:math';

import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/widgets/chat_message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _messageList = <ChatMessage>[];
  final _controllerText = new TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controllerText.dispose();
  }

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

  @override
  void initState() {
    super.initState();
    initSpeechState();
  }

  @override
  Widget build(BuildContext context) {
    initSpeechState();
    return Scaffold(
      body: Column(
        children: <Widget>[
          _buildList(),
          Divider(height: 1.0),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Flexible(
      child: ListView.builder(
        padding: EdgeInsets.all(8.0),
        reverse: true,
        itemBuilder: (_, int index) => ChatMessageListItem(chatMessage: _messageList[index]),
        itemCount: _messageList.length,
      ),
    );
  }

  void _sendMessage({String text}) {
    _controllerText.clear();
    _addMessage(name: 'Usuário', text: text, type: ChatMessageType.sent);
  }

  void _addMessage({String name, String text, ChatMessageType type}) {
    var message = ChatMessage(
        text: text, name: name, type: type);
    setState(() {
      _messageList.insert(0, message);
    });

    if (type == ChatMessageType.sent) {
      _dialogFlowRequest(query: message.text);
    }
  }

  Widget _buildTextField() {
    return new Flexible(
      child: new TextField(
        controller: _controllerText,
        decoration: new InputDecoration.collapsed(
          hintText: "Enviar mensagem",
        ),
      ),
    );
  }

  // Botão para enviar a mensagem
  Widget _buildSendButton() {
    return Row(
      children: <Widget>[
        InkWell(
          onTap: () {
            // ignore: unnecessary_statements
            speech.isListening ? null : startListening();
            waitForSpeech(60);
          },
          child: Padding(
              padding: const EdgeInsets.all(8.0), child: Icon(Icons.mic)),
        ),
        Container(
          margin: new EdgeInsets.only(left: 8.0),
          child: new IconButton(
              icon: new Icon(Icons.send, color: Theme.of(context).accentColor),
              onPressed: () {
                if (_controllerText.text.isNotEmpty) {
                  _sendMessage(text: _controllerText.text);
                }
              }),
        )
      ],
    );
  }

  // Monta uma linha com o campo de text e o botão de enviao
  Widget _buildUserInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new Row(
        children: <Widget>[
          _buildTextField(),
          _buildSendButton(),
        ],
      ),
    );
  }

  // ------------------------- BEGINNING VOICE ------------------------- //

  //Initialize stt recognition.
  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale.localeId;
    }

    if (!mounted) return;

    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  //Sends user message to dialogFlow and gets it's reply.
  Future _dialogFlowRequest({String query}) async {
    _addMessage(
        name: 'Bot de mensagem',
        text: 'Escrevendo...',
        type: ChatMessageType.received);

    AuthGoogle authGoogle = await AuthGoogle(fileJson: "assets/credentials.json").build();
    Dialogflow dialogflow = Dialogflow(authGoogle: authGoogle, language: "pt-BR");
    AIResponse response = await dialogflow.detectIntent(query);

    setState(() {
      _messageList.removeAt(0);
    });

    _addMessage(
        name: 'Bot de mensagem',
        text: response.getMessage() ?? '',
        type: ChatMessageType.received);

    FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage('pt_BR');
    flutterTts.setPitch(3);

    //tts the response message.
    var result = await flutterTts.speak(response.getMessage());

  }

  //Starts to listen to device's microphone
  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 10),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true,
        onDevice: true,
        listenMode: ListenMode.confirmation);
    setState(() {});
  }

  //Sets the result text from listening to lastWords.
  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = "${result.recognizedWords}";
      _controllerText.text = lastWords;
    });
  }

  //Sound level configuration.
  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    setState(() {
      this.level = level;
    });
  }

  //Delay to wait for user's voice recognition
  waitForSpeech(int duration) async {
    await Future.delayed(Duration(seconds: duration), () {});
  }

  //On recognition error.
  void errorListener(SpeechRecognitionError error) {
    // print("Received error status: $error, listening: ${speech.isListening}");
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  //Sets recognition status.
  void statusListener(String status) {
    setState(() {
      lastStatus = "$status";
    });
  }

  // ------------------------- END VOICE ------------------------- //
}