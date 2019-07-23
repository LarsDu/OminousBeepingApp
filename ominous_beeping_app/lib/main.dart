
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


//ref: https://medium.com/@tonyowen/gradient-text-in-flutter-24a8c8adfcd9
final Shader linearGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[Colors.white, Colors.green[10]],
).createShader(Rect.fromLTWH(0.0, 0.0, 300.0, 100.0));

void main() {
  //ref: https://medium.com/@kr1uz/how-to-restrict-device-orientation-in-flutter-65431cd35113
  //runApp(new OminousApp());
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
   .then((_) {
      runApp(new OminousApp());
  });
}

class OminousApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'OminousBeepingApp',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new OminousPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class OminousPage extends StatefulWidget {
  @override
  OminousState createState() => OminousState();
}

class OminousState extends State<OminousPage> {  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [  
            Container(
              height: 440,
              width: 304,                   
              child: FlashingCircle(),            
            ),
            Text( "OMINOUS\nBEEPING\nAPP",
                 textAlign: TextAlign.left,
                 style: TextStyle(fontFamily: 'Helvetica',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 60,
                                  color: Colors.white,
                                  //foreground: Paint()..shader = linearGradient,  
                                  ),

            ),
          ],
         )
        ),
    );
  }
}

class DrawCircle extends CustomPainter {

  int circleIndex = 0;
  Paint _paint;
  Paint _innerPaint;

  DrawCircle(this.circleIndex) {
    _paint = Paint()
      ..color = Color(0xFFCC3B78)
      ..strokeWidth = 16.0
      ..style = PaintingStyle.stroke;

    _innerPaint = Paint()
      ..color = Color(0xFFCC3B78)
      ..strokeWidth = 16.0
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw circle according to current circleIndex
    if (circleIndex < 3){
     canvas.drawCircle(Offset(0.0, 0.0), 32.0, _innerPaint); 
    }
    if(circleIndex >= 1){
      canvas.drawCircle(Offset(0.0, 0.0), 64.0, _paint); 
    }
    if(circleIndex >= 2){
      canvas.drawCircle(Offset(0.0, 0.0), 96.0, _paint);
    }
    if(circleIndex >=3){
      canvas.drawCircle(Offset(0.0, 0.0), 128.0, _paint);
    }

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class FlashingCircle extends StatefulWidget {
  @override
  FlashingCircleState createState() => FlashingCircleState();
}

class FlashingCircleState extends State<FlashingCircle> with SingleTickerProviderStateMixin {

  bool running=false;
  int circleIndex = 0;
  Animation<double> animation;
  AnimationController controller;
  
  int beepMs = 1800;
  int _curBeepMs;
  int lowerBeepMs = 100;
  int deltaBeepMs = -250;

  AudioCache _audioCache;
  AudioPlayer _audioPlayer;
  AudioPlayerState _audioPlayerState;

  @override
  void initState(){
    super.initState();
    initAudio();
    controller = AnimationController(
      duration: Duration( milliseconds: beepMs),
      vsync: this);
    _curBeepMs = beepMs;
    controller.addStatusListener((status){
      if (status == AnimationStatus.completed){
        _curBeepMs = max(_curBeepMs + deltaBeepMs, lowerBeepMs);
        controller.duration = Duration( milliseconds: _curBeepMs);
        controller.reset();
      } else if (status == AnimationStatus.dismissed){
        controller.forward();     
      }
    });

    animation = CurveTween(curve: Curves.easeIn).animate(controller)
      ..addListener((){
        setCircleIndexFromAnim();
      });

  }

  void initAudio(){
    // ref: https://medium.com/@pongpiraupra/a-comprehensive-guide-to-playing-local-mp3-files-with-seek-functionality-in-flutter-7730a453bb1a
      _audioPlayer = new AudioPlayer(mode: PlayerMode.LOW_LATENCY);
      _audioCache = new AudioCache(fixedPlayer: _audioPlayer);
  }

  void setCircleIndexFromAnim(){
    var animv = animation.value;
    int newCircleIndex;
    if(animv < 0.25 ){
      newCircleIndex = 0;
    } else if (animv >= 0.25 && animv < 0.50){
      newCircleIndex = 1;
    } else if (animv >= 0.50 && animv < 0.75){
      newCircleIndex = 2;
    } else if (animv >= 0.75 && animv < 1.0){
      newCircleIndex = 3;
    } else {
      newCircleIndex = 4;
      //makeBeep();
      _audioCache.play('beep.wav');
    }

    if (newCircleIndex != circleIndex){
      // If the circleIndex has changed at all from the animv value
      setState((){circleIndex=newCircleIndex;});
    }

  }
  
  /*
  Future makeBeep() async {
    await _audioPlayer.play("beep.wave");
    setState(() {
      _audioPlayerState = AudioPlayerState.PLAYING;
    });
  }
  */

  @override
  Widget build(BuildContext context){
      return FlatButton(
        child: CustomPaint(painter: DrawCircle(circleIndex)),
        
        onPressed: (){
          if (running){
            // Stop running the animation and beeper
            running = false;     
            // Reset controller duration
            controller.duration = Duration( milliseconds: beepMs);       
            controller.reset();
            controller.stop();
          } else {
            controller.forward(from: 0.0);
            running = true;
          }
          // Set the state once again
          setState( (){
            setCircleIndexFromAnim();
          } );
          
        },
      );

  }
  
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

}

