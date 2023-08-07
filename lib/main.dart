import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(ImageRecog());
}

class ImageRecog extends StatelessWidget {
  const ImageRecog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Colors.teal;
    return MaterialApp(
      home: Detect(),
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: primary,
      ),
    );
  }
}

class Detect extends StatefulWidget {
  const Detect({Key? key}) : super(key: key);

  @override
  _DetectState createState() => _DetectState();
}

class _DetectState extends State<Detect> {
  late File _image;
  late double _imageWidth;
  late double _imageHeight;
  var _recognitions;

  loadModel() async {
    Tflite.close();

    try {
      late final String? res;

      res = await Tflite.loadModel(
          model: "assets/mobilenet.tflite", labels: "assets/labels.txt");
      print(res);
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  Future predict(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.2,
      asynch: true,
    );

    print(recognitions);

    setState(() {
      _recognitions = recognitions;
    });
  }

  sendImage(File image) async {
    predict(image);

    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
            _image = image;
          });
        })));
    sendImage(image);
  }

  selectFromGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    sendImage(image);
  }

  selectFromCamera() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    sendImage(image);
  }

  @override
  void initState() {
    super.initState();

    loadModel().then((val) {
      setState(() {});
    });
  }

  Widget printValue(rcg) {
    if (rcg == null) {
      return Text('',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700));
    } else if (rcg.isEmpty) {
      return Center(
        child: Text('Could not recognize',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Center(
        child: Text(
          "Prediction: " + _recognitions[0]['label'].toString().toUpperCase(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    late double finalW;
    late double finalH;

    if (_imageHeight == null && _imageWidth == null) {
      finalW = size.width;
      finalH = size.height;
    } else {
      double ratioW = size.width / _imageWidth;
      double ratioH = size.height / _imageHeight;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Machine Learning'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 30),
            child: printValue(_recognitions),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: _image == null
                ? Center(
                    child: Text("Select image from camera or gallery"),
                  )
                : Center(
                    child: Image.file(_image,
                        fit: BoxFit.fill, width: finalW, height: finalH)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  selectFromCamera();
                },
                child: Column(
                  children: [
                    Icon(Icons.camera),
                    Text('Camera'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  selectFromCamera();
                },
                child: Column(
                  children: [
                    Icon(Icons.image),
                    Text('Gallery'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
