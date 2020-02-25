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
  bool messageOpen = false;
  bool messageEditing = false;
  bool messageOpenable = false;

  // data
  Message _messageIn = Message(
    // might only actually need to be the messageBody
    body: 'DEFAULT INCOMING',
    uid: 'defaultman',
    timestamp: Timestamp.now(),
    score: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      GestureDetector(
        // onTap: () => print('TAP'),
        onVerticalDragEnd: (details) async {
          if (details.primaryVelocity < 0) {
            print('SWIPE UP');
            if (messageOpen)
              setState(() {
                messageOpen = false;
                activeAnimation = 'up';
              });
          } else if (details.primaryVelocity > 0) {
            print('SWIPE DOWN');
            if (messageOpen) {
              setState(() {
                messageOpen = false;
                activeAnimation = 'down';
              });
            } else {
              var newMessageIn = await DatabaseService().getMessage();
              print('NEW messageIn.body: ${newMessageIn.body}');
              setState(() {
                _messageIn = newMessageIn;
                activeAnimation = 'start';
              });
            }
          } else {
            print('DRAG ZERO');
            if (messageOpen) {
              setState(() {
                messageOpen = false;
                messageOpenable = true;
              });
            }
          }
        },
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.grey[100],
            ),
            FlareActor(
              'assets/waves.flr',
              alignment: Alignment.center,
              fit: BoxFit.fitWidth,
              animation: activeAnimation,
              callback: (callback) {
                setState(() => activeAnimation = 'idle');
                print('Animation completed: $callback (waves.flr)');
              },
            ),
            FlareActor(
              'assets/bottle-in-up-down.flr',
              alignment: Alignment.center,
              fit: BoxFit.fitWidth,
              animation: activeAnimation,
              callback: (callback) {
                setState(() {
                  activeAnimation = 'idle';
                  messageOpenable = true;
                });
                print('Animation completed: $callback (bottle-in.flr)');
              },
            ),
            AnimatedOpacity(
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
                  child: Text(
                    _messageIn.body, //'"You’ll stop worrying what others think about you when you realize how seldom they do" - David Foster Wallace',
                    style: TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.normal,
                      fontSize: 25,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      Visibility(
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
                print('TAP: bottle');
                setState(() {
                  messageOpen = true;
                  messageOpenable = false;
                });
              },
            ),
          ),
        ),
      ),
    ]);
  }
}
