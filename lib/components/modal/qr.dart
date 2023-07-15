import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

String buildBarcode(
  Barcode bc,
  String data, {
  double? width,
  double? height,
  double? fontHeight,
}) {
  final String svg = bc.toSvg(
    data,
    width: width ?? 500,
    height: height ?? 200,
    fontHeight: fontHeight,
  );
  return svg;
}

showQrPopUp(context, currentUser) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(
                20.0,
              ),
            ),
          ),
          contentPadding: EdgeInsets.only(
            top: 10.0,
          ),
          title: Center(child: Text(
            "Public Identifier",
            style: TextStyle(fontSize: 24.0),
          ),
          ),
          content: Container(
            height: 400,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Center(
                    child: SvgPicture.string(
                      buildBarcode(
                        Barcode.qrCode(),
                        currentUser.npub,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        currentUser.npub, // TODO: This needs to be copyable
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
}
