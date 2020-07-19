import 'dart:ffi';
import 'dart:io';
import 'package:admin_website/group.dart';
import 'package:admin_website/paperback.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import 'model/state.dart';

class GroupA extends StatefulWidget {
  @override
  _GroupAState createState() => _GroupAState();
}

class _GroupAState extends State<GroupA> {
  String grpName;
  List<DocumentSnapshot> d = [];
  File sampleImage;
  int _myValue;
  String _description;
  String postUrl;
  String cardUrl;
  String _d;
  String _group;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<String> image = List<String>();
  var url;
  Future getDisplayImage() async {
    var tempImage = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      sampleImage = tempImage;
    });
  }

  bool validateAndSave() {
    final form = formKey.currentState;

    if (form.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   getName();
  // }

  void uploadStatusImage() async {
    if (validateAndSave()) {
      final StorageReference postImageRef =
          FirebaseStorage.instance.ref().child("PaperBacks/$grpName/");

      var timeKey = new DateTime.now();
      final StorageUploadTask uploadTask =
          postImageRef.child("paperBack${_myValue}").putFile(sampleImage);

      var PostUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
      postUrl = PostUrl.toString();
      print("Post Url =" + postUrl);
      saveToDatabase(postUrl);
      getName();
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => GroupA()));
    }
  }

  void saveToDatabase(String url) {
    var dbTimeKey = new DateTime.now();
    var formatDate = new DateFormat('MMM d, yyyy');
    var formatTime = new DateFormat('EEEE, hh:mm aaa');

    String date = formatDate.format(dbTimeKey);
    String time = formatTime.format(dbTimeKey);

    final ref = Firestore.instance.collection("$grpName");

    Map<String, List<String>> topic = Map<String, List<String>>();

    var data = {
      "img": postUrl,
      "name": _myValue,
      "title": _description,
      "date": date,
      "time": time,
      "Topic": topic
    };
    ref.document("paperBack${_myValue}").setData(data);
    print("paperback uplpaded");
  }

  Future<List<DocumentSnapshot>> getName() async {
    final db = Firestore.instance;
    QuerySnapshot qs;
    qs = await Firestore.instance.collection("$grpName").getDocuments();
    print("doc");
    List<DocumentSnapshot> d = qs.documents;
  
    return d;
  }

  @override
  Widget build(BuildContext context) {
    grpName = Provider.of<Params>(context).grpName;
    return new Scaffold(
      backgroundColor: Colors.white,
      body: WillPopScope(
        onWillPop: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Group()));
        },
        child: Column(
          children: <Widget>[
            new Center(
              child: sampleImage == null
                  ? Padding(
                      padding: EdgeInsets.all(50),
                      child: Text(
                        "PaperBacks Screen",
                        style: TextStyle(fontSize: 30.0),
                      ),
                    )
                  : enableUpload(),
            ),
            FutureBuilder<List<DocumentSnapshot>>(
                future: getName(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.done) {
                    print(snap.data.length);
                    return Expanded(
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: snap.data.length,
                        itemBuilder: (context, i) {
                          print("inside grid");

                          return Center(
                            child: GestureDetector(
                              onTap: () {
                                print("navigating");

                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) {
                                          return PaperBack();
                                        },
                                        settings: RouteSettings(
                                            arguments: snap.data[i])));
                              },
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.3,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 4.0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: GridTile(
                                          // child:
                                          //  Hero(
                                          //   tag: i,
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                // "http://via.placeholder.com/350x200",
                                                snap.data[i].data["img"],
                                            fit: BoxFit.fill,
                                            placeholder: (context, url) => Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            errorWidget: (_, str, dynamic) =>
                                                Center(
                                              child: Icon(Icons.error),
                                            ),

                                            //               // value: loadingProgress.expectedTotalBytes != null
                                            //               //     ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
                                            //               //     : null,
                                            //
                                          ),
                                          // ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                      child: Text(
                                          snap.data[i].documentID +
                                              "\n " +
                                              snap.data[i].data["title"],
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)))
                                ],
                              ),
                            ),
                          );
                        },
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 1.25,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                        ),
                      ),
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                })
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        tooltip: 'Add Image',
        child: new Icon(Icons.add_a_photo),
        onPressed: getDisplayImage,
      ),
    );
    // return Container(
    //     color: Colors.amber,
    //     child: Center(
    //       child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           children: <Widget>[
    //             sampleImage == null
    //                 ? RaisedButton(
    //                     onPressed: getDisplayImage,
    //                     child: Text(
    //                       "Make A Post",
    //                       style: TextStyle(fontSize: 40),
    //                       textAlign: TextAlign.center,
    //                     ))
    //                 : enableUpload(),
    //           ]),
    //     ));
  }

  Widget enableUpload() {
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height - 100,
            child: new Form(
              key: formKey,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Center(
                          child: Image.file(sampleImage,
                              height: 200, width: 150, fit: BoxFit.contain)),
                    ],
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: new InputDecoration(labelText: 'PaperBack No'),
                    validator: (value) {
                      return value.isEmpty ? 'PaperBack No is required' : null;
                    },
                    onSaved: (value) {
                      return _myValue = int.parse(value);
                    },
                  ),
                  TextFormField(
                    decoration:
                        new InputDecoration(labelText: 'Title of PaperBack'),
                    validator: (value) {
                      return value.isEmpty
                          ? 'Title of PaperBack is required'
                          : null;
                    },
                    onSaved: (value) {
                      return _description = value;
                    },
                  ),
                  // TextFormField(
                  //   decoration: new InputDecoration(labelText: 'd'),
                  //   validator: (value) {
                  //     return value.isEmpty ? 'd is required' : null;
                  //   },
                  //   onSaved: (value) {
                  //     return _d = value;
                  //   },
                  // ),
                  SizedBox(height: 15.0),
                  RaisedButton(
                    color: Colors.black,
                    onPressed: uploadStatusImage,
                    elevation: 4.0,
                    splashColor: Colors.blueGrey,
                    child: Text(
                      'Upload',
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
