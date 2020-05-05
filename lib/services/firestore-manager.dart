import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class FirestoreManager {
  /// FIRESTORE IMPORTER (modify as needed)
  /// Currently: adds a new document for each object in assets/test.json
  /// Usage: FirestoreManager().importMessages();

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

  /// FIRESTORE DELETER (modify as needed)
  /// Currently: deletes all documents where the 'score' is less than 0
  /// Usage: FirestoreManager().batchDelete();
  void batchDelete() async {
    Query _deleteQuery = messageCollection.where('score', isLessThan: 0);

    print('🔥🔥🔥BATCH DELETE🔥🔥🔥: Start');
    int _deleteCount = 0;
    QuerySnapshot _docsToDelete = await _deleteQuery.getDocuments();
    _docsToDelete.documents.forEach((doc) {
      print('🔥❌db-DELETE: ${doc.documentID} ${doc.data}');
      // messageCollection.document(doc.documentID).delete();
      _deleteCount++;
    });
    print('🔥🔥🔥BATCH DELETE🔥🔥🔥: $_deleteCount documents deleted ✅');
  }

  /// FIRESTORE UPDATER (modify as needed)
  /// Currently: Adds an 'upvotes' = 0 or 'downvotes' = 0 field if field does not exist in document where the 'score' is less than 25
  /// Usage: FirestoreManager().batchUpdate();
  void batchUpdate() async {
    Query _updateQuery =
        messageCollection.where('score', isLessThan: 25); // MODIFY QUERY

    print('🔥🔥🔥BATCH UPDATE🔥🔥🔥: Start');
    int _queryMatchCount = 0;
    int _updateCount = 0;

    int _nullUpvotesCount = 0; // CONDITION #1 COUNT
    int _nullDownvotesCount = 0; // CONDITION #2 COUNT

    QuerySnapshot _docsToUpdate = await _updateQuery.getDocuments();
    _docsToUpdate.documents.forEach((doc) {
      bool _updated = false;
      if (doc.data['upvotes'] == null) {
        // MODIFY UPDATE CONDITION #1
        print("🔥🔄db-UPDATE (add 'upvotes'): ${doc.documentID} ${doc.data}");
        // messageCollection.document(doc.documentID).updateData({'upvotes': 0});
        _nullUpvotesCount++;
        _updated = true;
      }
      if (doc.data['downvotes'] == null) {
        // MODIFY UPDATE CONDITION #2
        print("🔥🔄db-UPDATE (add 'downvotes'): ${doc.documentID} ${doc.data}");
        // messageCollection.document(doc.documentID).updateData({'downvotes': 0});
        _nullDownvotesCount++;
        _updated = true;
      }
      _updated
          ? _updateCount++
          : print(
              "🔥❎db-UPDATE (queried, not updated): ${doc.documentID} ${doc.data}");
      _queryMatchCount++;
    });
    print('nullUpvotes: $_nullUpvotesCount/$_queryMatchCount');
    print('nullDownvotes: $_nullDownvotesCount/$_queryMatchCount');
    print(
        '🔥🔥🔥BATCH UPDATE🔥🔥🔥: $_updateCount/$_queryMatchCount documents updated ✅');
  }
}
