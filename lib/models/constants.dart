import 'package:cloud_firestore/cloud_firestore.dart';

import 'message.dart';

final defaultMessage = Message(
  // might only actually need to be the messageBody
  id: 'defaultId',
  body: '',
  uid: 'defaultman',
  timestamp: Timestamp.now(),
  score: 0,
);
