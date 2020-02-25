import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String activeAnimation = 'idle';
  bool messageOpen = false;
  bool messageEditing = false;
  bool messageOpenable = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      GestureDetector(
        // onTap: () => print('TAP'),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity < 0) {
            if (messageOpen) setState(() => messageOpen = false);
            print('SWIPE UP');
          } else if (details.primaryVelocity > 0) {
            setState(() =>
                messageOpen ? messageOpen = false : activeAnimation = 'start');
            print('SWIPE DOWN');
          } else {
            if (messageOpen) {
              setState(() {
                messageOpen = false;
                messageOpenable = true;
              });
            }
            print('DRAG ZERO');
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
                print('Animation completed: waves.flr');
              },
            ),
            FlareActor(
              'assets/bottle-in.flr',
              alignment: Alignment.center,
              fit: BoxFit.fitWidth,
              animation: activeAnimation,
              callback: (callback) {
                setState(() {
                  activeAnimation = 'idle';
                  messageOpenable = true;
                });
                print('Animation completed: bottle-in.flr');
              },
            ),
            AnimatedOpacity(
              // visible: messageOpen ? true : false,
              opacity: messageOpen ? 1 : 0,
              duration: Duration(milliseconds: 200),
              child: Center(
                child: Container(
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
                    '"You’ll stop worrying what others think about you when you realize how seldom they do" - David Foster Wallace',
                    style: TextStyle(
                      color: Colors.black,
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
