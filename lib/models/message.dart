import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String body;
  final String uid;
  final Timestamp timestamp;
  final int score;
  // does not include 'upvotes' and 'downvotes' fields because not currently used

  Message({this.id, this.body, this.uid, this.timestamp, this.score});
}
