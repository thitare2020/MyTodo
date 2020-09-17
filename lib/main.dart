import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:information_app/loading.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          throw 'SomethingWentwrong';
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(

            home: mainPage(),
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return MaterialApp(
          home: LoadingPages(),
        );
      },
    );
  }
}

class mainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _mainPageState();
  }
}

class _mainPageState extends State<mainPage> {
  final collection = FirebaseFirestore.instance.collection('myTodo');
  final textController = TextEditingController();
  void _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Padding(
                padding: EdgeInsets.all(5.0),
                child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: ('please input here'),
                    ))),
            elevation: 24.0,
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              FlatButton(
                color: Colors.blue,
                textColor: Colors.white,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.all(8.0),
                splashColor: Colors.blueAccent,
                onPressed: () {
                  _insertion();
                  if (textController.text.trim() != '') {
                    Navigator.of(context).pop();
                    textController.clear();
                  }
                },
                child: Text(
                  "Insert",
                  style: TextStyle(fontSize: 15.0),
                ),
              )
            ],
          );
        });
  }

  void _delete(DocumentSnapshot document) {
    collection.doc(document.id).delete();
  }

  void _insertion() {
    String result = textController.text.trim();
    if (result != "") {
      DocumentReference docReference =
          collection.doc('${DateTime.now().toUtc().millisecondsSinceEpoch}');
      docReference.set({'Title': result, 'isCheck': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: _showDialog,
        ),
        appBar: AppBar(
          title: Text('Todo-List App'),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: collection.snapshots(),
            builder: (BuildContext context,AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10),
                  children: snapshot.data.docs.map((DocumentSnapshot document) {
                    return Card(
                      elevation: 3,
                      semanticContainer: true,
                      child: CheckboxListTile(
                          title: Text(
                            '${document.data()['Title']}',
                            style: TextStyle(
                                decoration: document.data()['isCheck']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none),
                          ),
                          value: document.data()['isCheck'],
                          contentPadding: EdgeInsets.all(0),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (value) {
                            String title = document.data()['Title'];
                              collection
                                  .doc(document.id)
                                  .update({'Title': title, 'isCheck': value});

                            Timer(Duration(milliseconds: 1000), (){
                                _delete(document);
                                Scaffold.of(context).hideCurrentSnackBar();
                                Scaffold.of(context)
                                    .showSnackBar(_showSnackBar(document));
                            });

                          }),
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    );
                  }).toList(),
                );
              } else {
                return Align(
                  alignment: FractionalOffset.center,
                  child: CircularProgressIndicator(),
                );
              }
            }));
  }

  Widget _showSnackBar(DocumentSnapshot document) {
    String title = document.data()['Title'];
    return SnackBar(
        duration: const Duration(milliseconds: 1000),
        content: Text('$title is Complete'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
            collection.doc(document.id).set({'Title': title, 'isCheck': false});
          },
        ));
  }
}
