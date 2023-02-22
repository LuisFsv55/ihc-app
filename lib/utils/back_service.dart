import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:mencuentras/request/request.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_background_service/flutter_background_service.dart'
    show
        AndroidConfiguration,
        FlutterBackgroundService,
        IosConfiguration,
        ServiceInstance;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';



import 'package:shake/shake.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stts;
// ignore_for_file: depend_on_referenced_packages

final service = FlutterBackgroundService();
final flutterTts = FlutterTts();
ShakeDetector? detector;
int _counter = 0;
var _speechToText = stts.SpeechToText();
bool isListening = false;
String text = "";
String lat = "Latitud";
String lng = "Longitud";
String alt = "Altitud";
String speed = "Spread";
String addres = "Calle";
late Placemark calles;
late Stream<StepCount> _stepCountStream;
late Stream<PedestrianStatus> _pedestrianStatusStream;
String _status = '?', steps = '?';
int pasos = 0;


Future initializeService() async {
  _initShakeListen();
  await service.configure(
    androidConfiguration: AndroidConfiguration(onStart: onStart, autoStart: true, isForegroundMode: true ),
    iosConfiguration: IosConfiguration( autoStart: true, onForeground: onStart, onBackground: onIosBackground ),
  );
  await service.startService();
}

bool onIosBackground( ServiceInstance service ) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  initPlatformState();
  _initShakeListen();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) async {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "My App Service",
        content: "Updated at ${DateTime.now()}",
      );
    }
    _startListening();
    // puedes ver este registro en logcat
    // print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    // prueba usando un complemento externo
    service.invoke(
      'update', {
        "current_date": DateTime.now().toIso8601String(),
        "counter": _counter,
      },
    );
  });
}

void _initShakeListen() async {
  detector = ShakeDetector.waitForStart(onPhoneShake: () async{
    listen();
  },);
}

void _startListening() async {
  detector?.startListening();
}

void _stopListening() async {
  detector?.stopListening();
}

void speak( String text ) async {
    await flutterTts.setLanguage('es-ES');
    await flutterTts.setPitch(1);
    await flutterTts.speak( text );
}
void speak1() {
  flutterTts.speak("Shake detected");
  _counter++;
}
void listen() async {
  if (!isListening) {
    bool available = await _speechToText.initialize( onStatus: (status) {}, onError: (errorNotification) => {});
    if (available) {
      isListening = true;
      await _speechToText.listen( 
        onResult: result,
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration( seconds: 5 ),
        partialResults: false,
        cancelOnError: true
      );
    }
  } else {
    isListening = false;
    _speechToText.stop();
  }
}
result( SpeechRecognitionResult result ) async {
  text = result.recognizedWords;
  await updatePosition();
}
void initPlatformState() {
  _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
  _pedestrianStatusStream
      .listen(onPedestrianStatusChanged)
      .onError(onPedestrianStatusError);

  _stepCountStream = Pedometer.stepCountStream;
  _stepCountStream.listen(onStepCount).onError(onStepCountError);
}
void onStepCount(StepCount event) {
    steps = event.steps.toString();
}

void onPedestrianStatusChanged(PedestrianStatus event) {
    _status = event.status;
}
  void onPedestrianStatusError(error) {
  _status = 'Pedometro no habilitado';
}

void onStepCountError(error) {
  steps = 'Contador no disponible';
}

Future<void> updatePosition() async {
  Position pos = await Geolocator.getCurrentPosition( desiredAccuracy: LocationAccuracy.high );
  List mp = await placemarkFromCoordinates( pos.latitude, pos.longitude );
  lat = pos.latitude.toString();
  lng = pos.longitude.toString();
  alt = pos.altitude.toString();
  speed = pos.speed.toString();
  addres = mp[0].toString();
  calles = mp[0];
  final Map<String, dynamic> mapa1 = {
    "area": calles.administrativeArea,
    "provincia": calles.subAdministrativeArea,
    "localidad": calles.locality,
    "sublocalidad": calles.subLocality,
    "calle": calles.thoroughfare,
    "numero": calles.subThoroughfare
  };
  String res = await httpConnetPost( lat, lng, mapa1, text, steps );
  speak( res );
}
Future<void> getLocation() async {
  await Geolocator.checkPermission();
  await Geolocator.requestPermission();
}