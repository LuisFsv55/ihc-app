import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mencuentras/utils/back_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart'
    show
        AndroidConfiguration,
        FlutterBackgroundService,
        IosConfiguration,
        ServiceInstance;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getLocation();
  await initializeService();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'mEncuentras',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('mEncuentras'),
          backgroundColor: Colors.blueGrey,
          centerTitle: true,
          elevation: 0,
        ),
        body:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                // ignore: prefer_const_constructors
                style: ButtonStyle(
                  backgroundColor: const MaterialStatePropertyAll<Color>(Colors.orangeAccent),
                ),
                onPressed: () async {
                    final service = FlutterBackgroundService();
                    var isRunning = await service.isRunning();
                    if (isRunning) {
                      service.invoke("stopService");
                    } else {
                      service.startService();
                    }
                }, 
                child: Icon( Icons.mobile_off_sharp )
              ),
            ),
          ],
        ),
      ),
    );
  }
}