import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:ocean_network/models/message.dart';
import 'package:ocean_network/services/db-service.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  // lifecycle events
  AppLifecycleState _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🔄----------VIEWDIDLOAD');
    getMessage();
    Timer(Duration(microseconds: 1), () => startRandomTimer()); // timer needed to ensure this is run after _timer init
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // went to Background
      print('🔄----------PAUSE');
    }
    if (state == AppLifecycleState.resumed) {
      // came back to Foreground
      print('🔄----------RESUMED');
      startRandomTimer();
    }
  }

  // UI
  String animateSend = 'idle';
  bool inboxEmpty = true;
  bool messageOpen = false;
  bool messageEditing = false;

  Timer _timer = new Timer(Duration(seconds: 0), () => print('⏳ init'));

  // data
  DatabaseService db = DatabaseService();
  Message _messageBayIn = Message(
    // might only actually need to be the messageBody
    id: 'defaultId',
    body: 'DEFAULT INCOMING',
    uid: 'defaultman',
    timestamp: Timestamp.now(),
    score: 0,
  );
  Message _messageIn = Message(
    // might only actually need to be the messageBody
    id: 'defaultId',
    body: 'DEFAULT INCOMING',
    uid: 'defaultman',
    timestamp: Timestamp.now(),
    score: 0,
  );
  String _messageBayOut = '';

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      GestureDetector(
        onVerticalDragEnd: (details) async {
          if (details.primaryVelocity < 0) {
            print('SWIPE UP');
            // takeMessage(); // TODO: remove test
          } else if (details.primaryVelocity > 0) {
            print('SWIPE DOWN');
            // await getMessage(); // TODO: remove test
          } else {
            print('DRAG ZERO');
            if (messageOpen) {
              closeMessage();
            } else if (!inboxEmpty) {
              openMessage();
            }
          }
        },
        child: Stack(
          children: <Widget>[
            Container(
              //background
              color: Colors.grey[900],
            ),
            FlareActor(
              'assets/mailbox_v03-send.flr',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
              animation: animateSend,
              callback: (callback) {
                setState(() => animateSend = 'idle');
              },
            ),
            FlareActor(
              'assets/mailbox_v03-mailbox.flr',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
            ),
            FlareActor(
              'assets/mailbox_v03-door.flr',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
              animation: messageOpen ? 'open' : 'close',
            ),
            FlareActor(
              'assets/mailbox_v03-flag.flr',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
              animation: inboxEmpty ? 'down' : 'up',
            ),
            FlareActor(
              'assets/mailbox_v03-ground.flr',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
            ),
            // Text('messageOpen: ${_messageBayIn.body}'),
            Text('🐛: ${_messageIn.id}'),
            AnimatedOpacity(
              // message card
              opacity: messageOpen ? 1 : 0,
              duration: Duration(milliseconds: 150),
              child: Center(
                child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOutCirc,
                    // height: messageOpen ? 1000 : 0,
                    margin:
                        EdgeInsets.symmetric(horizontal: 30.0, vertical: 90.0),
                    padding: EdgeInsets.all(35.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 60.0,
                            offset: Offset(5, 10),
                            spreadRadius: -25),
                      ],
                    ),
                    child: messageEditing
                        ? Material(
                            color: Colors.white,
                            child: Form(
                              child: TextFormField(
                                initialValue: _messageBayOut,
                                onChanged: (val) =>
                                    setState(() => _messageBayOut = val),
                                maxLines: null,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.normal,
                                  fontSize: 25,
                                  decoration: TextDecoration.none,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Write to a random person',
                                  hintMaxLines:
                                      100, // can't have unlimited for some reason
                                  border: InputBorder.none,
                                ),
                              ),
                            ))
                        : Text(
                            _messageIn.body,
                            style: TextStyle(
                              color: Colors.black87,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.normal,
                              fontSize: 25,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          )),
              ),
            )
          ],
        ),
      ),
      Visibility(
        visible: !messageOpen,
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            padding: EdgeInsets.all(50.0),
            child: FloatingActionButton(
              backgroundColor: Colors.grey[400],
              onPressed: () {
                print('TAP: edit');
                openMessage();
                setState(() {
                  messageEditing = true;
                });
              },
              child: Icon(Icons.edit),
            ),
          ),
        ),
      ),
      Visibility(
        visible: messageOpen,
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            padding: EdgeInsets.all(50.0),
            child: FloatingActionButton(
              backgroundColor: Colors.grey[400],
              onPressed: () {
                print('TAP: send');
                postMessage();
                if (messageOpen) closeMessage();
              },
              child: Icon(Icons.send),
            ),
          ),
        ),
      ),
      Visibility(
        visible: messageOpen,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            padding: EdgeInsets.all(50.0),
            child: FloatingActionButton(
              backgroundColor: Colors.grey[400],
              onPressed: () {
                print('TAP: discard');
                discardMessage();
                if (messageOpen) closeMessage();
              },
              child: Icon(Icons.delete),
            ),
          ),
        ),
      ),
    ]);
  }

  Future getMessage() async {
    // gets a message from Firestore into messageBayIn
    Message _gotMessage = await db.getMessage();
    // print('NEW messageIn.body: ${newMessageIn.body}');
    setState(() {
      _messageBayIn = _gotMessage;
    });
  }

  void takeMessage() {
    // takes message from messageBayIn into mailbox (messageIn)
    print('📥📫 take message');
    setState(() {
      _messageIn = _messageBayIn;
      inboxEmpty = false;
    });
    getMessage();
  }

  void openMessage() {
    print('open message');
    setState(() {
      messageOpen = true;
    });
  }

  void closeMessage() {
    print('close message');
    setState(() {
      messageOpen = false;
      messageEditing = false;
    });
  }

  void postMessage() {
    if (messageOpen) {
      if (messageEditing) {
        _messageBayOut != ''
            ? db.postMessage(_messageBayOut)
            : print('ERROR: Cannot post empty string');
        setState(() {
          _messageBayOut = '';
        });
      } else {
        db.incrementScore(_messageIn.id);
      }
      setState(() {
        inboxEmpty = true;
        animateSend = 'start';
      });
      startRandomTimer();
    }
  }

  void discardMessage() {
    if (messageOpen) {
      if (messageEditing) {
        setState(() {
          _messageBayOut = '';
        });
      } else {
        db.decrementScore(_messageIn.id);
      }
      setState(() {
        inboxEmpty = true;
      });
      startRandomTimer();
    }
  }

  void startRandomTimer() {
    if (inboxEmpty && !_timer.isActive) {
      const int maxTime = 4;//30;
      const int minTime = 3;//5;
      Duration duration =
          Duration(seconds: rng.nextInt(maxTime - minTime) + minTime);
      print('⏳ startRandomTimer (${duration.inSeconds} seconds)');
      _timer = new Timer(duration, () {
        print('⌛ done');
        takeMessage();
      });
    }
  }
}
