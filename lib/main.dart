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



            debugShowCheckedModeBanner: false,

            home: mainPage(),
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return MaterialApp(
            home: LoadingPages(), debugShowCheckedModeBanner: false);
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

  final _collection = FirebaseFirestore.instance.collection('myTodo');
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();


  void _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {

          return _myDialog();
        });
  }

  void _delete(DocumentSnapshot document) {
    _collection.doc(document.id).delete();
  }

  void _insertion() {
    String result = _textController.text.trim();
    if (result != "") {
      DocumentReference docReference =
          _collection.doc('${DateTime.now().toUtc().millisecondsSinceEpoch}');
      docReference.set({'Title': result, 'isCheck': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        key: _scaffoldKey,
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: _showDialog,
        ),
        appBar: AppBar(
          title: Text('Todo-List App'),
        ),

        body: _myTodos());

  }

  Widget _showSnackBar(DocumentSnapshot document) {
    String title = document.data()['Title'];
    return SnackBar(

        duration: Duration(milliseconds: 2000),

        content: Text('$title is Complete'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.

            _collection
                .doc(document.id)
                .set({'Title': title, 'isCheck': false});

          },
        ));
  }

  Widget _myTodos() {
    return StreamBuilder<QuerySnapshot>(
        stream: _collection.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return _myList(snapshot);
          } else {
            return Align(
              alignment: FractionalOffset.center,
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Widget _myDialog() {
    return AlertDialog(
      content: Padding(
          padding: EdgeInsets.all(5.0),
          child: Form(
              key: _formKey,
              child: TextFormField(
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: ('please input here'),
                  )))),
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

            if (_formKey.currentState.validate()) {
              _insertion();
              Navigator.of(context).pop();
              _textController.clear();
            }
          },
          child: Text(
            "Insert",
            style: TextStyle(fontSize: 15.0),
          ),
        )
      ],
    );
  }

  Widget _myList(AsyncSnapshot<QuerySnapshot> snapshot) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(10),
      children: snapshot.data.docs.map((DocumentSnapshot document) {
        if (document.data()['isCheck'] == true) {
          Timer(Duration(milliseconds: 1000), () {
            _scaffoldKey.currentState.hideCurrentSnackBar();
            _scaffoldKey.currentState.showSnackBar(_showSnackBar(document));
            _delete(document);
          });
        }
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
              onChanged: (value) => _collection.doc(document.id).update(
                  {'Title': document.data()['Title'], 'isCheck': value})),
          color: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }).toList(),
    );
  }
}
