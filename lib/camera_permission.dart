import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

class CameraPermission {

  bool _systemPermissionShown = false;
  final GlobalKey _alertKey = GlobalKey();

  // if a context is attached to the key, the alert dialog is shown
  bool dialogShown() => (_alertKey.currentContext != null) || _systemPermissionShown;

  void requestCameraPermission(BuildContext context, void Function() onGranted) async {
    if (await Permission.camera.status.isGranted) {
      // can init camera
      developer.log("======>>>>>>>>> PERMISSION GRANTED, DIALOG SHOWN (with key 1): ${dialogShown()}");
      // _initializeCameraController();
      onGranted();
    } else if(await Permission.camera.shouldShowRequestRationale) {

      // shouldShowRequestRationale (Android only)
      if(!context.mounted) return;
      developer.log("======>>>>>>>>> PERMISSION REQUEST RATIONAL, DIALOG SHOWN (with key): ${dialogShown()}");

      showRationalDialog(context, () async {
        developer.log("======>>>>>>>>> SHOW RATIONAL DIALOG, DIALOG SHOWN (with key): ${dialogShown()}");

        final result = await Permission.camera.request();

        if(result.isGranted){
          // init camera - (permissionDialogShown is already false)
          developer.log("======>>>>>>>>> PERMISSION GRANTED, DIALOG SHOWN (with key 2): ${dialogShown()}");

          // _initializeCameraController();

          onGranted();
          _systemPermissionShown = false;
        } else {
          // show permanently blocked message
          // open setting

          _systemPermissionShown = false;

          if(!context.mounted) return;
          developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${dialogShown()}");
          showDeniedPermanentlyDialog(context, () async {

            developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${dialogShown()}");
            await openAppSettings();
          });
        }
      });
    } else if (await Permission.camera.isDenied) {
      _systemPermissionShown = true;
      // request for the first time
      final result = await Permission.camera.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        if(Platform.isAndroid){
          // In Android, a request is rational after first denial
          // so we can request the permission again
          // A rational dialog (boolean value managed by the system/lib) will be shown immediately after this
          if(!context.mounted) return;
          requestCameraPermission(context, onGranted);
        } else {
          // In iOS, the permission status will be changed to deniedPermanently after the first denial
          // A user needs to allow the permission in Setting

          _systemPermissionShown = false;

          if(!context.mounted) return;

          developer.log("======>>>>>>>>> PERMISSION DENIED (FIRST REQUEST), DIALOG SHOWN (with key): ${dialogShown()}");

         showDeniedPermanentlyDialog(context, () async {
            developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${dialogShown()}");
            await openAppSettings();
          });
        }
      } else {
        developer.log("======>>>>>>>>> PERMISSION GRANTED, DIALOG SHOWN (with key 3): ${dialogShown()}");
        // _initializeCameraController();
        onGranted();
      }
    } else {
      if(!context.mounted) return;
      developer.log("======>>>>>>>>> PERMISSION REQUEST PERMANENT DENIED, DIALOG SHOWN (with key): ${dialogShown()}");
      showDeniedPermanentlyDialog(context, () async {
        developer.log("======>>>>>>>>> SHOW PERMANENT DENIED DIALOG, DIALOG SHOWN (with key): ${dialogShown()}");
        await openAppSettings();
      });
    }
  }


  void showRationalDialog(BuildContext context, void Function() onClose) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            key: _alertKey,
            insetPadding: const EdgeInsets.all(20),
            contentPadding: const EdgeInsets.all(15),
            title: const Text(
              "Camera Permission",
              textAlign: TextAlign.start,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "This app need camera permission to take liveness picture"),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose();
                  },
                  style: ButtonStyle(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                  child: const Text(
                    "Ok",
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showDeniedPermanentlyDialog(BuildContext context, void Function() onClose) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            key: _alertKey,
            insetPadding: const EdgeInsets.all(20),
            contentPadding: const EdgeInsets.all(15),
            title: const Text(
              "Camera Permission",
              textAlign: TextAlign.start,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Camera permission denied permanently, go to setting to enable permission"),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose();
                  },
                  style: ButtonStyle(
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                  child: const Text(
                    "Ok",
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
