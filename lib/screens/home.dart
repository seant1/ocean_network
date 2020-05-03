import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:ocean_network/models/message.dart';
import 'package:ocean_network/services/db-service.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // UI
  String activeAnimation = 'idle';
  String animateFlag = 'idle';
  String animateDoor = 'idle';
  String animateSend = 'idle';
  bool messageOpenable = false;
  bool messageOpen = false;
  bool messageEditing = false;

  // data
  Message _messageIn = Message(
    // might only actually need to be the messageBody
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
            if (messageOpen) {
              postMessage();
              setState(() {
                messageOpenable = false;
                closeMessage();
              });
            }
          } else if (details.primaryVelocity > 0) {
            print('SWIPE DOWN');
            if (messageOpen) {
              discardMessage();
            } else {
              await getMessage();
            }
          } else {
            print('DRAG ZERO');
            if (messageOpen) {
              setState(() {
                messageOpenable = true;
                closeMessage();
              });
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
              animation: animateDoor,
            ),
            FlareActor(
              'assets/mailbox_v03-flag.flr',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
              animation: animateFlag,
            ),
            FlareActor(
              'assets/mailbox_v03-ground.flr',
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
            ),
            // Text(activeAnimation),
            Text(messageOpenable.toString()),
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
                            _messageIn
                                .body, //'"You’ll stop worrying what others think about you when you realize how seldom they do" - David Foster Wallace',
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
        // bottle tap gesture detector
        visible: messageOpenable ? true : false,
        child: Center(
          // bottle tap detector
          heightFactor: 6.5,
          child: Container(
            color: Colors.transparent,
            width: 100,
            height: 100,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                openMessage();
              },
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: Container(
          padding: EdgeInsets.all(50.0),
          child: FloatingActionButton(
            backgroundColor: Colors.grey[400],
            onPressed: () {
              print('TAP: edit');
              setState(() {
                messageOpen = true;
                messageEditing = true;
              });
            },
            child: Icon(Icons.edit),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.all(50.0),
          child: FloatingActionButton(
            backgroundColor: Colors.grey[400],
            onPressed: () {
              print('TAP: send');
              if (messageOpen) {
                if (messageEditing) {
                  postMessage();
                } else {
                  DatabaseService().incrementScore(1);
                }
                setState(() {
                  closeMessage();
                  messageOpenable = false;
                  animateSend = 'start';
                });
              }
            },
            child: Icon(Icons.send),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.all(50.0),
          child: FloatingActionButton(
            backgroundColor: Colors.grey[400],
            onPressed: () {
              print('TAP: discard');
              if (messageOpen) discardMessage();
              messageOpenable = false;
            },
            child: Icon(Icons.delete),
          ),
        ),
      ),
    ]);
  }

  void discardMessage() {
    messageEditing ? _messageBayOut = '' : DatabaseService().decrementScore(1);
    setState(() {
      closeMessage();
      messageOpenable = false;
    });
  }

  void postMessage() {
    if (messageEditing) {
      _messageBayOut != ''
          ? DatabaseService().postMessage(_messageBayOut)
          : print('ERROR: Cannot post empty string');
      _messageBayOut = '';
    } else {
      DatabaseService().incrementScore(1);
    }
  }

  void closeMessage() {
    messageOpen = false;
    messageEditing = false;
    activeAnimation = 'close';
    animateDoor = 'close';
  }

  void openMessage() {
    print('TAP: bottle');
    setState(() {
      messageOpen = true;
      messageOpenable = false;
      activeAnimation = 'open'; // callback for open animation opens message
      animateDoor = 'open';
      animateFlag = 'down';
    });
  }

  Future getMessage() async {
    var newMessageIn = await DatabaseService().getMessage();
    // print('NEW messageIn.body: ${newMessageIn.body}');
    setState(() {
      _messageIn = newMessageIn;
      messageOpenable = true;
      activeAnimation = 'up';
      animateFlag = 'up';
    });
  }
}
