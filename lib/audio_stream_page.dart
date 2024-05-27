import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioStreamPage extends StatefulWidget {
  @override
  _AudioStreamPageState createState() => _AudioStreamPageState();
}

class _AudioStreamPageState extends State<AudioStreamPage> {
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BehaviorSubject<Uint8List> _audioStream = BehaviorSubject<Uint8List>();
  StreamSubscription? _audioStreamSubscription;

  String myText = """Hello how are you""";

  // final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  final player = AudioPlayer();
  bool _isStreaming = false;
  bool fetchingResponse = true;
  List<int> bytes = [];
  final voiceSource = VoiceSource();
  @override
  void initState() {
    super.initState();
    // _soundPlayer.openAudioSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    _audioStream.close();
    _audioStreamSubscription?.cancel();
    // _soundPlayer.closeAudioSession();
    super.dispose();
  }

  Future _sendTextAndStreamAudio(String text) async {
    List<String> words = text.split(' ');
    print("length of words is ${words.length}");
    print("start the process");
    final String apiUrl =
        'https://api.elevenlabs.io/v1/text-to-speech/GYuixkHJoHNePdSa4pNt/stream';
    try {
      final request = http.Request('POST', Uri.parse(apiUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'xi-api-key': dotenv.env['ELEVENLABSKEY']!,
      });
      request.body = jsonEncode({
        "text": text.replaceAll('*', ''),
        "model_id": "eleven_multilingual_v2",
        // widget.guruName == AppLocalizations.of(context)!.spanishPastor
        //     ? "eleven_multilingual_v2" :"eleven_multilingual_v1",

        // : "eleven_multilingual_v2",
      });

      final response = await request.send();
      print("my response is $response");
      print("my code is ${response.statusCode}");

      if (response.statusCode == 200) {
        print("response success");
        // _audioStreamSubscription = response.stream.listen((chunk) {
        //   _audioStream.add(Uint8List.fromList(chunk));
        // }, onDone: () {
        //   _audioStream.close();
        // }, onError: (error) {
        //   print('Error: $error');
        // });
        //
        // // Play the streamed audio
        // _playStreamedAudio();
        // setState(() {
        //   _isStreaming = true;
        // });

        response.stream.listen(
              (chunk) {
            bytes.addAll(chunk);
            voiceSource.addBytes(chunk);
            if (bytes.isNotEmpty) {
              print("${bytes.length}");
            } else {
              print("why come here ${bytes.length}");
            }
          },
          onDone: () {
            print("on done length ${bytes.length}");
            voiceSource.removeListener();
          },
          onError: (error) {},
          cancelOnError: true,
        );
        print("is bytes empty ${bytes.length}");
        await player.setAudioSource(voiceSource, preload: false);
        player.play();
      } else {
        print("something bad happened");
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print("getting no error");
      print("caught error : $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Stream Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _sendTextAndStreamAudio(myText);
              },
              child: const Text('Send Text and Stream Audio'),
            ),
          ],
        ),
      ),
    );
  }
}


class VoiceSource extends StreamAudioSource {
  final StreamController<List<int>> _controller =
  StreamController<List<int>>.broadcast();
  List<int> bytes = [];

  void addBytes(List<int> chunk) {
    bytes.addAll(chunk);
    _controller.add(chunk);
  }

  void removeListener() {
    _controller.close();
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: null,
      contentLength: 9999999,
      offset: start,
      stream: _controller.stream,
      contentType: 'audio/mpeg',
    );
  }
}
