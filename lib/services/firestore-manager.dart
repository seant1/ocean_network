import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class FirestoreManager {
  /// FIRESTORE IMPORTER
  /// running FirestoreImporter().importMessages() will import JSON data from assets

  String jsonFile = 'assets/test.json'; // works with array of JSON objects
  String jsonImportField = 'text'; // String field of each JSON object

  final CollectionReference messageCollection =
      Firestore.instance.collection('messages');

  void importMessages() async {
    print('🔥🔥🔥BATCH CREATE🔥🔥🔥: Start');
    String jsonString = await rootBundle.loadString(jsonFile);
    final List<dynamic> jsonData = jsonDecode(jsonString);
    jsonData.forEach((message) async {
      var messageMap = _parseMessageBody(message[jsonImportField]);
      // await messageCollection.document().setData(messageMap);
      print('🔥📤db-POST: $messageMap');
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

  /// FIRESTORE DELETER
  /// modify as needed
  void batchDelete() async {
    Query _deleteQuery = messageCollection
        .where('score', isLessThan: 0);
        // .where('downvotes', isNull: true);

    print('🔥🔥🔥BATCH DELETE🔥🔥🔥: Start');
    int deleteCount = 0;
    QuerySnapshot _docsToDelete = await _deleteQuery.getDocuments();
    _docsToDelete.documents.forEach((doc) {
      print('🔥❌db-DELETE: ${doc.documentID} ${doc.data}');
      // messageCollection.document(doc.documentID).delete();
      deleteCount++;
    });
    print('🔥🔥🔥BATCH DELETE🔥🔥🔥: $deleteCount documents deleted ✅');
  }
}
