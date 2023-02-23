import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> httpConnetPost( String lat, String lng, Map<String,dynamic> address, String message, String pasos ) async {
  Uri url = Uri.parse( 'https://ihc-back.onrender.com' );
  // Uri url = Uri.parse( 'http://192.168.1.2:4000' );
  var response = await http.post(url, body: {
    'message': message,
    'lat': lat,
    'lng': lng,
    'address': json.encode( address ),
    'pasos': pasos
  });
  
  Map<String, dynamic> resNode = json.decode( response.body );

  return resNode["peticion_body"]["message"]["text"];
}




















// print('Response status: ${response.statusCode}');
// print( resNode );
// print( resNode["peticion_body"]["message"]["text"] );
// print('Response body: ${response.body}');