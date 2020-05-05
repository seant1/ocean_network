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
  /// Currently: Resets scores, upvotes, downvotes
  /// Usage: FirestoreManager().batchUpdate();
  void batchUpdate() async {
    Query _updateQuery =
        messageCollection.where('score', isLessThan: 25); // MODIFY QUERY

    print('🔥🔥🔥BATCH UPDATE🔥🔥🔥: Start');
    int _queryMatchCount = 0;
    int _updateCount = 0;

    int _resetUpvotesCount = 0; // CONDITION #1 COUNT
    int _resetDownvotesCount = 0; // CONDITION #2 COUNT
    int _resetScoreCount = 0; // CONDITION #2 COUNT

    QuerySnapshot _docsToUpdate = await _updateQuery.getDocuments();
    _docsToUpdate.documents.forEach((doc) {
      bool _updated = false;
      if (doc.data['upvotes'] != 0) {
        // MODIFY UPDATE CONDITION #1
        print("🔥🔄db-UPDATE (reset 'upvotes'): ${doc.documentID} ${doc.data}");
        // messageCollection.document(doc.documentID).updateData({'upvotes': 0});
        _updated = true;
        _resetUpvotesCount++;
      }
      if (doc.data['downvotes'] != 0) {
        // MODIFY UPDATE CONDITION #2
        print("🔥🔄db-UPDATE (reset 'downvotes'): ${doc.documentID} ${doc.data}");
        // messageCollection.document(doc.documentID).updateData({'downvotes': 0});
        _updated = true;
        _resetDownvotesCount++;
      }
      if (doc.data['score'] != 3) {
        print("🔥🔄db-UPDATE (reset 'score'): ${doc.documentID} ${doc.data}");
        // messageCollection.document(doc.documentID).updateData({'score': 3});
        _updated = true;
        _resetScoreCount++;
      }
      _updated
          ? _updateCount++
          : print(
              "🔥❎db-UPDATE (queried, not updated): ${doc.documentID} ${doc.data}");
      _queryMatchCount++;
    });
    print('resetUpvotes: $_resetUpvotesCount/$_queryMatchCount');
    print('resetDownvotes: $_resetDownvotesCount/$_queryMatchCount');
    print('resetScore: $_resetScoreCount/$_queryMatchCount');
    print(
        '🔥🔥🔥BATCH UPDATE🔥🔥🔥: $_updateCount/$_queryMatchCount documents updated ✅');
  }
}
