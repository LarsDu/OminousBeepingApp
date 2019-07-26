
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors/sensors.dart';
//import 'package:vector_math/vector_math.dart';

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
  //ref: https://medium.com/@tonyowen/gradient-text-in-flutter-24a8c8adfcd9
  // Note: need to scale this gradient to the screen
  final Shader linearGradient = LinearGradient(
      begin: FractionalOffset.topCenter,
      end: FractionalOffset.bottomCenter,
      colors: <Color>[Colors.white, Color(0xFF9BFFAA)],
                                               ).createShader(Rect.fromLTWH(0.0, 0.0, 750.0, 300.0));
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Container(
                  height: 440,
                  width: 304,
                  child: FlashingCircle(),
                ),
              ),
              Container(
                 child: Text( "OMINOUS\nBEEPING\nAPP",
                 textAlign: TextAlign.left,
                 style: TextStyle(fontFamily: 'Helvetica',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 60,
                                  //color: Colors.white,
                                  foreground: Paint()..shader = linearGradient,
                                  ),
              ),
            )
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
  
  int beepMs = 1500;
  int _curBeepMs;
  int lowerBeepMs = 150;
  int deltaBeepMs = -250;

  AudioCache _audioCache;
  AudioPlayer _audioPlayer;
  //AudioPlayerState _audioPlayerState;

  StreamSubscription<dynamic> shakeSubscription;
  List<double> accelXyz;
  double shakeSpeedThreshold=48.0;
  int currentTime;

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

    //animation = CurveTween(curve: Curves.easeIn).animate(controller)
    animation = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener((){
        setCircleIndexFromAnim();
      });

      // Make the animation triggerable by shaking
    shakeSubscription = accelerometerEvents.listen( _startAnimationOnShake );

  }


  _startAnimationOnShake(AccelerometerEvent event){
      List<double> newXyz =  <double>[event.x, event.y, event.z];
      if (currentTime == null){
        currentTime = DateTime.now().millisecondsSinceEpoch;
      } 
      if (accelXyz == null){
        accelXyz = newXyz;
      } 
      int newTime = DateTime.now().millisecondsSinceEpoch;
      double timeDiff = (newTime - currentTime)/(1000.0);
      double magnitude = calcMagnitude(newXyz, accelXyz);
      double speed = magnitude/timeDiff;

      if (speed>shakeSpeedThreshold){
        setState((){running=false;});
        _startAnimationIfRunning();
      }

      // Update variables
      accelXyz = newXyz;
      currentTime = newTime;
  }

  double calcMagnitude( List a, List b){
    return sqrt( pow(a[0]-b[0], 2)+pow(a[1]-b[1], 2)+pow(a[2]-b[2], 2));
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
  _startAnimationIfRunning(){
    if (running){
    // Stop running the animation and beeper
      running = false;     
      // Reset controller duration
      controller.duration = Duration( milliseconds: beepMs);   
      _curBeepMs = beepMs;    
      controller.reset();
      controller.stop();
      } else {
        controller.forward(from: 0.0);
        running = true;
     }
   // Set the state once again
   setState( (){
      setCircleIndexFromAnim();
   });
  }
          

  @override
  Widget build(BuildContext context){
      return FlatButton(
        child: CustomPaint(painter: DrawCircle(circleIndex)),        
        onPressed: _startAnimationIfRunning,
      );

  }
  
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
    shakeSubscription.cancel();
  }

}


