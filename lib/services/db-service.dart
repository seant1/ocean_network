import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_network/models/message.dart';

String _currentId; // TODO: store in state
var rng = Random();

class DatabaseService {
  final CollectionReference messageCollection =
      Firestore.instance.collection('messages');

  // Get random message
  Future<Message> getMessage() async {
    var randomNo = rng.nextInt(await getMaxScore());
    print('db-randomNo: $randomNo');
    try {
      var docSnapshot =
          // await messageCollection.orderBy('score', descending: true).limit(1).getDocuments();
          await messageCollection
              .where('score', isGreaterThanOrEqualTo: randomNo)
              .limit(1)
              .getDocuments();
      print(
          'db-GET: ${docSnapshot.documents.single.documentID} ${docSnapshot.documents.single.data}');
      return _parseDocumentSnapshot(docSnapshot.documents.single);
    } catch (e) {
      return Message(body: e.toString());
    }
  }

  // Convert DocumentSnapshot to Message model
  Message _parseDocumentSnapshot(DocumentSnapshot snapshot) {
    _currentId = snapshot.documentID;
    // print('db-currentId: $_currentId');
    return Message(
      body: snapshot.data['body'],
      uid: snapshot.data['uid'],
      timestamp: snapshot.data['timestamp'],
      score: snapshot.data['score'],
    );
  }

  // Convert Message to DocumentSnapshot Map<String, dynamic> for posting
  Map<String, dynamic> _parseMessageBody(String messageBody) {
    return {
      'body': messageBody,
      'uid': 'programmatic',
      'timestamp': Timestamp.now(),
      'score': 0,
    };
  }

  // Post message
  Future<void> postMessage(String messageOut) async {
    var messageMap = _parseMessageBody(messageOut);
    await messageCollection.document().setData(messageMap);
    print('db-POST: $messageMap');
  }

  // Update score
  void incrementScore(int add) async {
    try {
      await messageCollection.document(_currentId).updateData({
        'score': FieldValue.increment(add),
        'upvotes': FieldValue.increment(1),
      });
      print('db-Firebase incrementScore');
    } catch (e) {
      print(e.toString());
    }
  }

  void decrementScore(int subtract) async {
    try {
      await messageCollection.document(_currentId).updateData({
        'score': FieldValue.increment(-subtract),
        'downvotes': FieldValue.increment(1),
      });
      print('db-Firebase decrementScore');
    } catch (e) {
      print(e.toString());
    }
  }

  Future<int> getMaxScore() async {
    try {
      var docSnapshot = await messageCollection
          .orderBy('score', descending: true)
          .limit(1)
          .getDocuments();
      print('db-MaxScore: ${docSnapshot.documents.single.data['score']}');
      if (docSnapshot.documents.single.data['score'] != 0) {
        return docSnapshot.documents.single.data['score'];
      } else {
        print('db-MaxScore: defaulted to 1');
        return 1;
      }
    } catch (e) {
      print('db-MaxScore: ${e.toString()}');
      return 1;
    }
  }
}
