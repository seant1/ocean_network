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
  String animateSend = 'idle';
  bool inboxEmpty = true;
  bool messageOpen = false;
  bool messageEditing = false;

  // data
  Message _messageBayIn = Message(
    // might only actually need to be the messageBody
    body: 'DEFAULT INCOMING',
    uid: 'defaultman',
    timestamp: Timestamp.now(),
    score: 0,
  );
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
            takeMessage(); // TODO: run takeMessage on a random timer
          } else if (details.primaryVelocity > 0) {
            print('SWIPE DOWN');
            await getMessage();
          } else {
            print('DRAG ZERO');
            if (messageOpen) {
              closeMessage();
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
            Text('messageOpen: $messageOpen'),
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
        // bottle tap gesture detector
        visible: inboxEmpty ? false : true,
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
                messageOpen ? closeMessage() : openMessage();
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
              openMessage();
              setState(() {
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
              postMessage();
              if (messageOpen) closeMessage();
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
              discardMessage();
              if (messageOpen) closeMessage();
            },
            child: Icon(Icons.delete),
          ),
        ),
      ),
    ]);
  }

  Future getMessage() async {
    Message _gotMessage = await DatabaseService().getMessage();
    // print('NEW messageIn.body: ${newMessageIn.body}');
    setState(() {
      _messageBayIn = _gotMessage;
    });
  }

  void takeMessage() {
    setState(() {
      _messageIn = _messageBayIn;
      inboxEmpty = false;
    });
    getMessage(); // get a new message into the messageBayIn
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
            ? DatabaseService().postMessage(_messageBayOut)
            : print('ERROR: Cannot post empty string');
        setState(() {
          _messageBayOut = '';
        });
      } else {
        DatabaseService().incrementScore(1);
      }
      setState(() {
        inboxEmpty = true;
        animateSend = 'start';
      });
    }
  }

  void discardMessage() {
    if (messageOpen) {
      if (messageEditing) {
        setState(() {
          _messageBayOut = '';
        });
      } else {
        DatabaseService().decrementScore(1);
      }
      setState(() {
        inboxEmpty = true;
      });
    }
  }
}
