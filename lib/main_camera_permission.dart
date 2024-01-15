import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_2/camera_permission.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

List<CameraDescription> cameras = [];


Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: const TakePictureScreen(),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
  });

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool isRecordingVideo = false;

  final _cameraPermission = CameraPermission();


  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {

    // developer.log("===>>>>>>> LIFE CYCLE: $state, dialog shown: ${_cameraPermission.alertDialogShown()}");

    if(ModalRoute.of(context)?.isCurrent == true){
      if (state == AppLifecycleState.paused) {
        _controller?.dispose();
        _controller = null;
      } else if (state == AppLifecycleState.resumed) {
        if(!_cameraPermission.dialogShown()){
          print("======>>>>>>>>> request camera permission if resume and not showing dialog");
          _cameraPermission.requestCameraPermission(context, () {
            _initializeCameraController();
          });
        }
      }
    }
  }


  /*
  void requestCameraPermission() async {
    if (await Permission.camera.status.isGranted) {
      // can init camera
      developer.log("======>>>>>>>>> PERMISSION GRANTED, DIALOG SHOWN (with key 1): ${_cameraPermission.dialogShown()}");
      _initializeCameraController();
    } else if(await Permission.camera.shouldShowRequestRationale) {

      // shouldShowRequestRationale (Android only)
      if(!mounted) return;
      developer.log("======>>>>>>>>> PERMISSION REQUEST RATIONAL, DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");

      _cameraPermission.showRationalDialog(context, () async {
        developer.log("======>>>>>>>>> SHOW RATIONAL DIALOG, DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");

        _cameraPermission.systemPermissionShown = true;

        final result = await Permission.camera.request();
        if(result.isGranted){
          // init camera - (permissionDialogShown is already false)
          developer.log("======>>>>>>>>> PERMISSION GRANTED, DIALOG SHOWN (with key 2): ${_cameraPermission.dialogShown()}");

          _initializeCameraController();
        } else {
          // show permanently blocked message
          // open setting
          if(!mounted) return;
          developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");
          _cameraPermission.showDeniedPermanentlyDialog(context, () async {
            developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");
            await openAppSettings();
          });

          _cameraPermission.systemPermissionShown = false;
        }
      });
    } else if (await Permission.camera.isDenied) {

        _cameraPermission.systemPermissionShown = true;
        // request for the first time
        final result = await Permission.camera.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          if(Platform.isAndroid){
            // In Android, a request is rational after the first denial
            // so we can request the permission again
            requestCameraPermission();
          } else {
            // In iOS, the permission status will be changed to deniedPermanently after the first denial
            // A user needs to allow the permission in Setting
            if(!mounted) return;

            developer.log("======>>>>>>>>> PERMISSION DENIED (FIRST REQUEST), DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");

            _cameraPermission.showDeniedPermanentlyDialog(context, () async {
              developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");
              await openAppSettings();
            });
          }
        } else {
          developer.log("======>>>>>>>>> PERMISSION GRANTED, DIALOG SHOWN (with key 3): ${_cameraPermission.dialogShown()}");
          _initializeCameraController();
        }

        _cameraPermission.systemPermissionShown = false;
    } else {
      if(!mounted) return;
      developer.log("======>>>>>>>>> PERMISSION REQUEST PERMANENT DENIED, DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");
      _cameraPermission.showDeniedPermanentlyDialog(context, () async {
        developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${_cameraPermission.dialogShown()}");
        await openAppSettings();
      });
    }
  }
   */

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraPermission.requestCameraPermission(context, () {
      _initializeCameraController();
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller?.dispose();
    _controller = null;

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _logError(String code, String? message) {
    // ignore: avoid_print
    print('Error: $code${message == null ? '' : '\nError Message: $message'}');
  }

  Future<void> _initializeCameraController() async {
    if (_controller != null) {
      print("====>>> controller is not null");
      // _controller!.setDescription(cameraDes);
      return;
    }

    int cameraIndex = 0;

    if (cameras.any(
      (element) =>
          element.lensDirection == CameraLensDirection.front &&
          element.sensorOrientation == 90,
    )) {
      cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) =>
              element.lensDirection == CameraLensDirection.front &&
              element.sensorOrientation == 90,
        ),
      );
    } else {
      cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) => element.lensDirection == CameraLensDirection.front,
        ),
      );
    }

    final cameraDes = cameras[cameraIndex];

    final CameraController cameraController = CameraController(
      cameraDes,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        print("error");
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('Audio access is restricted.');
          break;
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> startVideoRecording() async {
    if (_controller == null || _controller?.value.isInitialized == false) {
      showInSnackBar('Error: select a camera first.');
      return;
    }

    if (_controller?.value.isRecordingVideo == true) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await _controller?.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (_controller == null || _controller?.value.isInitialized == false) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (_controller?.value.isRecordingVideo == false) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      return _controller?.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Widget cameraInstant(bool isRecording) {
    if (_controller == null || _controller?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: [
          CameraPreview(_controller!),
          ElevatedButton(
            onPressed: () async {
              if (isRecording) {
                stopVideoRecording().then((file) async {
                  final tempDir = await getTemporaryDirectory();
                  final tempAppDir = await getApplicationCacheDirectory();
                  final downloadDir = await getDownloadsDirectory();

                  print("temp dir ==> $tempDir");
                  print("temp app dir ==> $tempAppDir");
                  print("download dir ==> $downloadDir");

                  print("-----------------------------------------------");
                  print("====>>> FILE: $file");
                  print("======>>> FILE PATH: ${file?.path}");

                  if (file != null) {
                    await Gal.putVideo(file.path, album: null);
                    // File(file.path).delete();
                  }

                  if (mounted) {
                    setState(() {
                      isRecordingVideo = false;
                    });
                  }
                });
              } else {
                startVideoRecording().then((_) {
                  if (mounted) {
                    setState(() {
                      isRecordingVideo = true;
                    });
                  }
                });
              }
            },
            child: Text(
              isRecording ? "Recording Video" : "Record Video",
              style: TextStyle(color: isRecording ? Colors.red : Colors.white),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: cameraInstant(isRecordingVideo),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          _cameraPermission.requestCameraPermission(context, () {
            _initializeCameraController();
          });

          // LivenessInstructionDialog.showInstructionAlert(context, (){
          //   print("===============>>> ");
          // });

          // try {
          //   await _controller?.dispose();
          //   _controller = null;
          //
          //   if (!mounted) return;
          //
          //   // If the picture was taken, display it on a new screen.
          //   Navigator.of(context).push(
          //     MaterialPageRoute(
          //       builder: (context) {
          //         // _controller.dispose();
          //         return const TakePictureScreen2();
          //       },
          //     ),
          //   ).then((value) {
          //     _initializeCameraController();
          //   });
          // } catch (e) {
          //   // If an error occurs, log the error to the console.
          //   print(e);
          // }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
