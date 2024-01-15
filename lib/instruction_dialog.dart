import 'package:flutter/material.dart';

class CameraPermissionInstruction {

  bool isAlertDialogShown(BuildContext context) {


    // Check if there is a Navigator in the current context
    if (Navigator.of(context).overlay != null) {
      // Check if there are any active overlays (dialogs)
      return Navigator.of(context).overlay?.mounted == true;
    }
    return false;
  }

  final GlobalKey _alertKey = GlobalKey();

  // if a context is attached to the key, the alert dialog is shown
  bool alertDialogShown() => _alertKey.currentContext != null;


  static void showRationalDialog(BuildContext context, void Function() onClose) {
    showDialog(

      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(

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
                    "Camdikey need camera permission to take liveness picture"),
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

  static void showDeniedPermanentlyDialog(BuildContext context, void Function() onClose) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
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
