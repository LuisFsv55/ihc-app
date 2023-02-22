import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shake/shake.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stts;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  int counter = 0;
  late ShakeDetector detector;
  String lat = "Latitud";
  String lng = "Longitud";
  String alt = "Altitud";
  String speed = "Spread";
  String addres = "Calle";
  late Placemark calles;
  // =====*****_____ Var: Activar el microfono _____*****===== //
  var _speechToText = stts.SpeechToText();
  bool isListening = false;
  String text = "Presionar Por favor";
  // =====*****_____ Var: Texto a Voz _____*****===== //
  final FlutterTts flutterTts = FlutterTts();
  

  
  

  speak( String text ) async {
    await flutterTts.setLanguage('es-ES');
    await flutterTts.setPitch(1);
    await flutterTts.speak( text );
  }

  // =====*****_____ Apagar Microfono y el detector _____*****===== //
  @override
  void dispose() {
    detector.stopListening();
    super.dispose();
  }
  // =====*****_____ Inicio de la App _____*****===== //
  @override
  void initState() {
    super.initState();
    speak('Bienvenido a la aplicación mEncuentras');
    detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        listen();
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7
    );
    _speechToText = stts.SpeechToText();
  }
  // =====*****_____ Función de escuchar cuando se agita el celular _____*****===== //
  void listen() async {
    if (!isListening) {
      bool available = await _speechToText.initialize(
          onStatus: (status) {
            // ignore: avoid_print
            print(status);
          },
          // ignore: avoid_print
          onError: (errorNotification) => print("$errorNotification"));
      if (available) {
        setState(() { isListening = true; });
        _speechToText.listen( onResult: (result) => setState(() { text = result.recognizedWords; }));
      }
    } else {
      setState(() { isListening = false; });
      speak('Usted apagó el micrófono');
      _speechToText.stop();
      // _updatePosition();
    }
  }
  void getLocation() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition( desiredAccuracy: LocationAccuracy.high);
    setState(() {
      lat = position.latitude.toString();
      lng = position.longitude.toString();
    });

    // httpConnetPost( lat, lng, text );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: const Text('Bienvenido al Asistente'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Center( child: Text(text) ),
          Center( child: Text(lat) ),
          Center( child: Text(lng) ),
          Center( child: Text(addres) )
        ],
      ),
      floatingActionButton: AvatarGlow(
        animate: isListening,
        repeat: isListening,
        endRadius: 80,
        glowColor: Colors.red,
        duration: const Duration(milliseconds: 1000),
        child: FloatingActionButton(
          onPressed: () => listen(),
          child: Icon(isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
    );
  }
}