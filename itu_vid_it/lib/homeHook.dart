import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/bleUI.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';
import 'package:ituvidit/mountRemoteControls.dart';
import 'package:ituvidit/static.dart';
import 'package:tflite/tflite.dart';
import 'camera.dart';




class HomeHooks extends HookWidget{
  final List<CameraDescription> cameras;


  HomeHooks(this.cameras);

  loadModel() async {
    String res;
    res = await Tflite.loadModel(
        model: "assets/lite-model_ssd_mobilenet_v1_1_metadata_2.tflite",
        labels: "assets/ssd_mobilenet.txt");
    print(res);
  }

  Widget startTrackingButton(ValueNotifier<bool> isTracking){
    return RaisedButton(
      color: Colors.teal,
      child: const Text(
        "Start Tracking",
        style: TextStyle(color: Colors.black),
      ),
      onPressed: () {
        loadModel();
        isTracking.value = true;
      },
    );
  }

  Widget detectImageButton(BuildContext context){
    return RaisedButton(
      child: Text("Detect in Image"),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => StaticImage(),
        ),
        );
      },
    );
  }

  Widget remoteControls(BuildContext context){
    return RaisedButton(
      child: Text("Mount Remote Controls"),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => MountRemoteControls(),
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //Values and setter used for debugmode in the drawer
    final debugModeValue = useState(true);
    void setDebugModeValue(bool val){
      debugModeValue.value = val;
    }

    final bleCharacteristic = useState();
    void setCharacteristic(BluetoothCharacteristic characteristic){
      bleCharacteristic.value = characteristic;
    }


    final isTracking = useState(false);
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return(
        Scaffold(
         appBar: AppBar(
            //Only show backarrow if _model.value is not ""
            leading: isTracking.value ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                isTracking.value = false;
              },
            ) : null,
            title: Text("VidIt"),
            flexibleSpace: CustomAppBarDesign(),
          ),
          endDrawer: CustomDrawer(setDebugModeValue, debugModeValue.value),
          backgroundColor: appBarPrimary,
          body: !isTracking.value ?
          Center(
            child: isPortrait ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                startTrackingButton(isTracking),
                detectImageButton(context),
                remoteControls(context),
                FlutterBlueWidget(setCharacteristic),
              ],
            ) : Row(children: [
              FlutterBlueWidget(setCharacteristic),
              Column(
                children: [
                  startTrackingButton(isTracking),
                  detectImageButton(context),
                  remoteControls(context),
                ],
              ),
            ],)
          )
              : Stack(
            children: [
              Camera(
                cameras,
                bleCharacteristic.value,
                debugModeValue,
              ),
            ],
          ),
        )
    );
  }
}