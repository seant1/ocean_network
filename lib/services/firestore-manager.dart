import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:ocean_network/services/db-service.dart';


class FirestoreManager {
  /// FIRESTORE IMPORTER
  /// running FirestoreImporter().importMessages() will import JSON data from assets
  String jsonFile = 'assets/test.json'; // works with array of JSON objects
  String jsonImportField = 'text'; // String field of each JSON object
  
  final CollectionReference messageCollection =
      Firestore.instance.collection('messages');

  void importMessages() async {
    String jsonString = await rootBundle.loadString(jsonFile);
    final List<dynamic> jsonData = jsonDecode(jsonString);
    jsonData.forEach((message) async {
      var messageMap = _parseMessageBody(message[jsonImportField]);
      // await messageCollection.document().setData(messageMap);
      print('db-POST: $messageMap');
    });
  }

  Map<String, dynamic> _parseMessageBody(String messageBody) {
    return {
      'body': messageBody,
      'uid': 'import',
      'timestamp': Timestamp.now(),
      'score': 3,
      'upvotes': 0,
      'downvotes': 0,
    };
  }
}
