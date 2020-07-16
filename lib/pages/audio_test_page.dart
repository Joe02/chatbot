import 'package:chatbot/pages/audio_recognition_chat.dart';
import 'package:chatbot/utils/audio_recognition_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioTestPage extends StatefulWidget {
  @override
  AudioTestPageState createState() => AudioTestPageState();
}

class AudioTestPageState extends State<AudioTestPage> {
  TextEditingController _textController = TextEditingController();
  var helper = AudioRecognitionHelper();

  @override
  void initState() {
    super.initState();
    helper.initSpeechState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tela de teste de áudio"),
        actions: <Widget>[
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AudioRecognitionChatPage()));
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.arrow_forward),
            ),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: "Clique no microfone e fale algo.",
                suffixIcon: InkWell(
                  onTap: () {
                    getsAudioResponse();
                  },
                  child: Icon(Icons.mic),
                )),
          ),
        ),
      ),
    );
  }

  //Listens to user audio
  getsAudioResponse() async {
    helper.startListening();

    //While the user's words == null
    while (helper.lastWords == "") {
      await Future.delayed(Duration(seconds: 1));
    }

    //Once the user say something :
    setState(() {
      _textController.text = helper.lastWords;
    });

    //Dialog flow request for Dialog flow response via tts.
    _dialogFlowRequest(query: _textController.text);
  }

  //Sends user message to dialogFlow and gets it's reply.
  _dialogFlowRequest({String query}) async {
    AuthGoogle authGoogle = await AuthGoogle(fileJson: "assets/credentials.json").build();
    Dialogflow dialogflow = Dialogflow(authGoogle: authGoogle, language: "pt-BR");
    AIResponse response = await dialogflow.detectIntent(query);

    //Configures flutterTts
    FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage('pt_BR');
    flutterTts.setPitch(3);

    //tts the response message.
    await flutterTts.speak(response.getMessage());
  }
}
