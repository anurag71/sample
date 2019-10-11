import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'pdfview.dart';
import 'savelist.dart';
import 'package:toast/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilePickerDemo extends StatefulWidget {
  String fName;

  FilePickerDemo(String markerId) {
    fName = markerId;
  }

  @override
  _FilePickerDemoState createState() => new _FilePickerDemoState(fName);
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  bool _uploaded = false;
  static String folderName;
  String order;

  _FilePickerDemoState(String fname) {
    folderName = fname;
  }

  String _fileName = '...';
  String assetPDFPath = ' ';
  String _path = '...';
  final db = Firestore.instance;

//String _extension="PDF";
  //bool _hasValidMime = false;
  FileType _pickingType = FileType.CUSTOM;

  //TextEditingController _controller = new TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _openFileExplorer() async {
    //if (_pickingType == FileType.CUSTOM || _hasValidMime) {
    try {
      _path = await FilePicker.getFilePath(
          type: _pickingType, fileExtension: "pdf");
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }

    if (!mounted) return;

    setState(() {
      _fileName = _path != null ? _path.split('/').last : '...';
    });
    //}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: const Text("Xerox"),
        backgroundColor: Colors.deepOrange[300],
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.view_list),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => Savedlist()));
            },
            tooltip: "List of online documents",
          )
        ],
      ),
      body: SingleChildScrollView(
        child: new Center(
            child: new Padding(
          padding: const EdgeInsets.only(top: 50.0, left: 10.0, right: 10.0),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // new Padding(
              //   padding: const EdgeInsets.only(top: 20.0),
              //   child: new DropdownButton(
              //       hint: new Text('LOAD PATH FROM'),
              //       value: _pickingType,
              //       items: <DropdownMenuItem>[
              //         new DropdownMenuItem(
              //           child: new Text('FROM AUDIO'),
              //           value: FileType.AUDIO,
              //         ),
              //         new DropdownMenuItem(
              //           child: new Text('FROM GALLERY'),
              //           value: FileType.IMAGE,
              //         ),
              //         new DropdownMenuItem(
              //           child: new Text('FROM VIDEO'),
              //           value: FileType.VIDEO,
              //         ),
              //         new DropdownMenuItem(
              //           child: new Text('FROM ANY'),
              //           value: FileType.ANY,
              //         ),
              //         new DropdownMenuItem(
              //           child: new Text('CUSTOM FORMAT'),
              //           value: FileType.CUSTOM,
              //         ),
              //       ],
              //       onChanged: (value) => setState(() => _pickingType = value)),
              // ),
              // new ConstrainedBox(
              //   constraints: new BoxConstraints(maxWidth: 150.0),
              //   child: _pickingType == FileType.CUSTOM
              //       ? new TextFormField(
              //     maxLength: 20,
              //     autovalidate: true,
              //     controller: _controller,
              //     decoration: InputDecoration(labelText: 'File type'),
              //     keyboardType: TextInputType.text,
              //     textCapitalization: TextCapitalization.none,
              //     validator: (value) {
              //       RegExp reg = new RegExp(r'[^a-zA-Z0-9]');
              //       if (reg.hasMatch(value)) {
              //         _hasValidMime = false;
              //         return 'Invalid format';
              //       }
              //       _hasValidMime = true;
              //     },
              //   )
              //       : new Container(),
              // ),
              new Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: new RaisedButton(
                  onPressed: () => _openFileExplorer(),
                  child: new Text("Open file picker"),
                ),
              ),
              _uploadpdf(),
              _widgetList(),
            ],
          ),
        )),
      ),
    );
  }

  Widget _widgetList() {
    if (!_uploaded) {
      return Column(
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
            child: new RaisedButton(
              onPressed: () => _viewpdf(),
              child: new Text("View the document"),
            ),
          ),
          new Text(
            'URI PATH ',
            textAlign: TextAlign.center,
            style: new TextStyle(fontWeight: FontWeight.bold),
          ),
          new Text(
            _path ?? '...',
            textAlign: TextAlign.center,
            softWrap: true,
            textScaleFactor: 0.85,
          ),
          new Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: new Text(
              'FILE NAME ',
              textAlign: TextAlign.center,
              style: new TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          new Text(
            _fileName,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    else
      {
        return SizedBox();
      }
  }

  Widget _viewpdf() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => PdfViewPage(path: _path)));
  }

  Widget _uploadpdf() {
    if (_uploaded) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        elevation: 0.0,
        backgroundColor: Colors.white,
        child: dialogContent(context),
      );
    }
    return Center(
      child: Column(
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
            child: new RaisedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                var cid = prefs.getString("cid");
                final StorageReference storageRef = FirebaseStorage.instance
                    .ref()
                    .child(folderName + "/" + _fileName);
                StorageTaskSnapshot storageTaskSnapshot =
                    await storageRef.putFile(File(_path)).onComplete;
                if (storageTaskSnapshot != null) {
                  String name;
                  await Firestore.instance
                      .document("customer/$cid")
                      .get()
                      .then(((document) {
                    name = document.data["name"];
                  }));
                  String url = await storageTaskSnapshot.ref.getDownloadURL();
                  DocumentReference docref = db
                      .collection("Xerox Shops/$folderName/files received")
                      .document();
                  order = docref.documentID;
                  await docref.setData({
                    "ordered by": name,
                    "orderId": order,
                    "file name": _fileName,
                    "order status": "Accepted",
                    "pdf_url": url
                  });
                  Toast.show("Upload Successful", context);
                  setState(() {
                    _uploaded = true;
                  });
                }
              },
              child: new Text("Upload File"),
            ),
          ),
        ],
      ),
    );
  }

  dialogContent(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder(
            stream: db
                .collection("Xerox Shops/$folderName/files received")
                .document(order)
                .snapshots(),
            builder: (context, snapshot) {
              return Wrap(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text("Order Status:"),
                      Text(snapshot.data["order status"]),
                    ],
                  ),
                ],
              );
            }));
  }
}
