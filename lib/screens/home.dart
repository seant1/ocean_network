import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String activeAnimation = 'idle';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => print('TAP'),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity < 0) {
          print('SWIPE UP');
        } else if (details.primaryVelocity > 0) {
          setState(() => activeAnimation = 'start');
          print('SWIPE DOWN');
        } else {
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
              setState(() => activeAnimation = 'idle');
              print('Animation completed: bottle-in.flr');
            },
          ),
        ],
      ),
    );
  }
}
