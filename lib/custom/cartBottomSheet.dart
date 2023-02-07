import 'package:flutter/material.dart';

class AddToCartBottomSheet extends StatefulWidget {
  const AddToCartBottomSheet({Key key}) : super(key: key);

  @override
  _AddToCartBottomSheetState createState() => _AddToCartBottomSheetState();
}

class _AddToCartBottomSheetState extends State<AddToCartBottomSheet> {
  int _quantity = 0;
  // ...

    void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _quantity++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
        minHeight: MediaQuery.of(context).size.height / 2,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(4),
            // ...
            child: Text("Add item to Cart"),
          ),
          Padding(
            padding: EdgeInsets.all(4),
            // ...
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: null,
                ), // decrease qty button
                Text("${_quantity}"), // current quanity
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _incrementCounter,
                ) // increase qty button
              ],
            ),
          ),
          RaisedButton(
            color: Colors.orangeAccent,
            textColor: Colors.white,
            child: Text(
              "Add To Cart".toUpperCase(),
            ),
            onPressed: () => Navigator.of(context).pop(_quantity),
          )
        ],
      ),
    );
  }
}
