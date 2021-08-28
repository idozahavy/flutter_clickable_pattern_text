import 'package:flutter/material.dart';
import 'package:clickable_pattern_text/clickable_pattern_text.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _incrementCounter() {
    // setState(() {
    //   // This call to setState tells the Flutter framework that something has
    //   // changed in this State, which causes it to rerun the build method below
    //   // so that the display can reflect the updated values. If we changed
    //   // _counter without calling setState(), then the build method would not be
    //   // called again, and so nothing would appear to happen.
    //   _counter++;
    // });
    // textCanvas2Key.currentState
    //     .ensureVisible(searchSpan, duration: Duration(seconds: 1), offset: 0);
    // richCanvas2Key.currentState.ensureVisible(
    //   searchSpan,
    //   alignment: 0,
    //   duration: Duration(seconds: 1),
    //   offset: 0,
    // );
    cpt1Key.currentState
        .ensureVisible(cpt1Span, duration: Duration(seconds: 1), alignment: 1);
  }

  final richCanvas2Key = GlobalKey<RichTextPositionerState>();
  final cpt1Key = GlobalKey<ClickablePatternTextState>();

  InlineSpan cpt1Span;
  InlineSpan searchSpan;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 200),

            RichTextPositioner(
              key: richCanvas2Key,
              text: TextSpan(
                text: '1 fd23 234fds fds' * 200,
                style: TextStyle(
                  color: Colors.black,
                ),
                children: [
                  // WidgetSpan(
                  //   child: SizedBox(width: 40, height: 40),
                  // ),
                  searchSpan = TextSpan(
                    text: 'gg',
                    style: TextStyle(
                      background: Paint()..color = Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: '5d5ew we5r64d6fs a5fd 21312 dsa' * 200,
                  ),
                  searchSpan,
                ],
              ),
            ),
            ClickablePatternText(
              'my phone is 123456789 or 987654321, my friends phone is:456321987 ' *
                  50,
              key: cpt1Key,
              style: TextStyle(color: Colors.black, fontSize: 16),
              // clickableDefaultStyle: TextStyle(
              //	color: Colors.blue, decoration: TextDecoration.underline),
              patterns: [
                ClickablePattern(
                  name: 'phone',
                  pattern: r'(?<=[ ,.:]|^)\d{9}(?=[ ,.]|$)',
                  onClicked: (phone, clickablePattern) => print(phone),
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                  onSpanCreation: (span, index) {
                    cpt1Span ??= span;
                    if ((index + 1) % 50 == 0) {}
                  },
                ),
              ],
            ),
            // ClickablePatternText(
            //   'my email is a@b.com you can click it or this a@c.com ',
            //   style: TextStyle(color: Colors.black, fontSize: 16),
            //   clickableDefaultStyle: TextStyle(
            //       color: Colors.blue, decoration: TextDecoration.underline),
            //   patterns: [
            //     ClickablePattern(
            //         name: 'url',
            //         pattern: r'\w+@\w+.\w+',
            //         onClicked: (url, clickablePattern) => print(url),
            //         style: TextStyle(
            //             color: Colors.blue,
            //             decoration: TextDecoration.underline)),
            //   ],
            // ),
            // ClickablePatternText('123456789',
            //     style: TextStyle(color: Colors.black, fontSize: 16),
            //     patterns: [
            //       ClickablePattern(
            //         name: '',
            //         pattern: r'[0-9]',
            //         onClicked: (text, clickablePattern) => print(text),
            //       )
            //     ]),
            // ClickablePatternText(
            //   'You have pushed the button this many times: '
            //   "'"
            //   '054-669-5220'
            //   "'"
            //   ' 0546695220,0546695220\r0546695220,ido@t.co.il.org.234.sd',
            //   style: Theme.of(context).textTheme.bodyText1,
            //   clickableDefaultStyle: TextStyle(
            //       color: Colors.blue, decoration: TextDecoration.underline),
            // ),
            // Text(
            //   '$_counter',
            //   style: Theme.of(context).textTheme.headline4,
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
