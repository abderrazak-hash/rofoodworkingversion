import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:webcontent_converter/webcontent_converter.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const TestApp(),
  );
}

class TestApp extends StatefulWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  WebViewController? ctrl;
  String url = '';
  Uint8List? webConv;

  @override
  void initState() {
    super.initState();
    SunmiPrinter.bindingPrinter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: WebView(
            initialUrl: 'https://pos.rofood.co',
            zoomEnabled: false,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (c) {
              ctrl = c;
            },
            onPageFinished: (url) async {
              setState(() {
                this.url = url;
              });
              if (url.contains('/print/')) {
                String html = await ctrl!.runJavascriptReturningResult(
                    "encodeURIComponent(document.documentElement.outerHTML)");
                html = Uri.decodeComponent(html);
                html = html.substring(1, html.length - 1);
                html = html.replaceFirst(RegExp(r'</style>'), '<!--');
                html = html.replaceFirst(
                    RegExp(r'<h1 class="name_rep">مطعم المطاعم </h1>'),
                    '--></style><body><h1 class="name_rep">مطعم المطاعم </h1>');
                webConv =
                    await WebcontentConverter.contentToImage(content: html);
                await SunmiPrinter.initPrinter();
                await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
                await SunmiPrinter.startTransactionPrint(true);
                await SunmiPrinter.printImage(webConv!);
                await SunmiPrinter.lineWrap(1);
                await SunmiPrinter.exitTransactionPrint(true);
                await SunmiPrinter.cut();
              }
            },
          ),
        ),
      ),
    );
  }
}
