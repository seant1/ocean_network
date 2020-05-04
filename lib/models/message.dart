import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String body;
  final String uid;
  final Timestamp timestamp;
  final int score;

  Message({this.id, this.body, this.uid, this.timestamp, this.score});
}
