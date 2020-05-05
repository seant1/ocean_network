import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_network/models/message.dart';

var rng = Random();

class DatabaseService {
  final CollectionReference messageCollection =
      Firestore.instance.collection('messages');

  int _lastScore;
  List<int> _lastMaxScore = [4];

  int _getScore(int maxScore) {
    int score;
    int randCase = rng.nextInt(3);
    double randomDouble = rng.nextDouble(); // rng.nextInt(await getMaxScore());
    switch (randCase) {
      case 0:
        // print('🔥 db-getScore: New (3/$maxScore)');
        score = 3;
        break;
      default:
        int scaledRandom = (randomDouble * (maxScore)).toInt();
        // print('🔥 db-getScore: Random ($scaledRandom/$maxScore)');
        score = scaledRandom;
        break;
    }
    if (score == _lastScore) {
      // if duplicate consecutive scores
      print('duplicate consecutive score ($score --> ${score + 1})');
      score++;
    }
    print('🔥 db-getScore: ($score/$maxScore)');
    _lastScore = score;
    return score;
  }

  // Get random message
  Future<Message> getMessage() async {
    try {
      var docSnapshot =
          // await messageCollection.orderBy('score', descending: true).limit(1).getDocuments();
          await messageCollection
              .where('score',
                  isGreaterThanOrEqualTo: _getScore(await getMaxScore()))
              .orderBy('score')
              .orderBy(
                  'downvotes') // IF REMOVED, remove Firstore composite index for "score_downvotes"
              .limit(1)
              .getDocuments();
      print(
          '🔥📥 db-GET: ${docSnapshot.documents.single.documentID} ${docSnapshot.documents.single.data}');
      return _parseDocumentSnapshot(docSnapshot.documents.single);
    } catch (e) {
      print(e);
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
    print('lastMaxScore: $_lastMaxScore');
    int _maxScore;
    try {
      var docSnapshot = _lastMaxScore[0] >
              4 // reduces max score every time until 4, then restarts from max
          ? await messageCollection
              .orderBy('score', descending: true)
              .startAfter(_lastMaxScore) // second highest scoring message
              .limit(1)
              .getDocuments()
          : await messageCollection // actual highest scoring message (should only be run initially)
              .orderBy('score', descending: true)
              .limit(1)
              .getDocuments();
      // print('db-MaxScore: ${docSnapshot.documents.single.data['score']}');
      if (docSnapshot.documents.single.data['score'] != 0) {
        _maxScore = docSnapshot.documents.single.data['score'];
      } else {
        print('db-MaxScore: defaulted to 4');
        return 4;
      }
    } catch (e) {
      print('db-MaxScore: ${e.toString()}');
      return 4;
    }
    if (_lastMaxScore.isNotEmpty) _lastMaxScore.clear();
    _lastMaxScore.add(_maxScore);
    return _maxScore;
  }
}
