import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_network/models/message.dart';

var rng = Random();

class DatabaseService {
  final CollectionReference messageCollection =
      Firestore.instance.collection('messages');

  int _getScore(int maxScore) {
    int randCase = rng.nextInt(3);
    double randomDouble = rng.nextDouble(); // rng.nextInt(await getMaxScore());
    switch (randCase) {
      case 0:
        print('🔥 db-getScore: New (3/$maxScore)');
        return 3;
        break;
      default:
        int scaledRandom = (randomDouble * (maxScore + 1)).toInt();
        print('🔥 db-getScore: Random ($scaledRandom/$maxScore)');
        return scaledRandom;
        break;
    }
  }

  // Get random message
  Future<Message> getMessage() async {
    try {
      var docSnapshot =
          // await messageCollection.orderBy('score', descending: true).limit(1).getDocuments();
          await messageCollection
              .where('score',
                  isGreaterThanOrEqualTo: _getScore(await getMaxScore()))
              .limit(1)
              .getDocuments();
      print(
          '🔥📥 db-GET: ${docSnapshot.documents.single.documentID} ${docSnapshot.documents.single.data}');
      return _parseDocumentSnapshot(docSnapshot.documents.single);
    } catch (e) {
      return Message(body: e.toString());
    }
  }

  // Convert DocumentSnapshot to Message model
  Message _parseDocumentSnapshot(DocumentSnapshot snapshot) {
    return Message(
      id: snapshot.documentID,
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
      'score': 3,
    };
  }

  // Post message
  Future<void> postMessage(String messageOut) async {
    var messageMap = _parseMessageBody(messageOut);
    await messageCollection.document().setData(messageMap);
    print('🔥📤 db-POST: $messageMap');
  }

  // Update score
  void incrementScore(String messageId) async {
    try {
      await messageCollection.document(messageId).updateData({
        'score': FieldValue.increment(1),
        'upvotes': FieldValue.increment(1),
      });
      print('🔥👍 db-Firebase incrementScore: $messageId');
    } catch (e) {
      print(e.toString());
    }
  }

  void decrementScore(String messageId) async {
    try {
      await messageCollection.document(messageId).updateData({
        'score': FieldValue.increment(-1),
        'downvotes': FieldValue.increment(1),
      });
      print('🔥👎 db-Firebase decrementScore: $messageId');
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
      // print('db-MaxScore: ${docSnapshot.documents.single.data['score']}');
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
