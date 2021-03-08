import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/mountController.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/recordButton.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

typedef void Callback(List<dynamic> list, int h, int w, TrackingData trackingData);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final BluetoothCharacteristic _bleCharacteristic;

  Camera(this.cameras, this.setRecognitions, this._bleCharacteristic);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  CameraController recController;
  bool isDetecting = false;
  CameraDescription camera;
  int cameraFlip = 0;
  TrackingData _trackingData;


  @override
  void initState() {
    super.initState();
    startCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void startCamera(){
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[1],
        ResolutionPreset.high,
      );
      recController = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      recController.initialize().then((value) => null);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});


        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;
            //int startTime = new DateTime.now().millisecondsSinceEpoch;

            Tflite.detectObjectOnFrame(
              bytesList: img.planes.map((plane) {return plane.bytes;}).toList(),
              model: "SSDMobileNet",
              imageHeight: img.height,
              imageWidth: img.width,
              numResultsPerClass: 5,
              threshold: 0.5,
            ).then((recognitions) {
              //print(recognitions);

              //making a new list that only contains detectedClass: person
              List<dynamic> newRecognitions = List<dynamic>();
              try {
                int newRecognitionIndex= recognitions.indexOf(recognitions.firstWhere((element) =>
                element.toString().contains("detectedClass: person")
                    //todo --> slet linjen her for kun at tracke personer
                    || element.toString().contains("detectedClass: bottle")));

                newRecognitions.add(recognitions[newRecognitionIndex]);
              }catch(e) {
                // no person found
              }

              if(newRecognitions.length>0){
                String wCoord= newRecognitions[0].toString().split(",")[0].replaceFirst("{rect: {w: ", "").trim();
                //print("Wcoord:" + wCoord);
                String xCoord= newRecognitions[0].toString().split(",")[1].replaceFirst("x: ", "").trim();
                //print("Xcoord:" + xCoord);
                String hCoord= newRecognitions[0].toString().split(",")[2].replaceFirst("h: ", "").trim();
                //print("Hcoord:" + hCoord);
                String yCoord= newRecognitions[0].toString().split(",")[3].replaceFirst("y: ", "").replaceFirst("}", "").trim();
                //print("Ycoord:" + yCoord);

                String testSpeed = "500";//todo --> fix this compared to earlier frame coords
                _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, testSpeed);
              }
              else{
                _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", "0.0");
              }
              widget.setRecognitions(newRecognitions, img.height, img.width, _trackingData);
              isDetecting = false;
            });
          }
        });
      });
    }
  }

  void changeCameraLens() {
    // get current lens direction (front / rear)
    final lensDirection = controller.description.lensDirection;
    if (lensDirection == CameraLensDirection.front) {
      setState(() {
        //Back camera
        cameraFlip = 0;
      });
      camera = cameras[0];
    }
    else {
      setState(() {
        //Front camera
        cameraFlip = 1;
      });
      camera = cameras[1];
    }
    if (camera != null) {
      startCamera();
    }
    else {
      print('Asked camera not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return Stack(
      children: [
        OverflowBox(
          maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
          maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
          child: CameraPreview(controller),
        ),
        Container(
          alignment: Alignment.topRight,
          child: FloatingActionButton(
            child: Icon(Icons.flip_camera_android),
            onPressed: () {
              changeCameraLens();
            },
          ) ,
        ),

        MountController(_trackingData, widget._bleCharacteristic),

        RecordButton(cameras[cameraFlip], startCamera)
      ],
    );
  }
}

