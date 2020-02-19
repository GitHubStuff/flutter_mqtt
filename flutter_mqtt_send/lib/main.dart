import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_theme_package/flutter_theme_package.dart';
import 'package:flutter_tracers/trace.dart' as Log;

void main() => runApp(MQTTest());

class MQTTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModeTheme(
      data: (brightness) => (brightness == Brightness.light) ? ModeThemeData.bright() : ModeThemeData.dark(),
      defaultBrightness: Brightness.light,
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          home: MQTTester(),
          initialRoute: '/',
          routes: {
            MQTTester.route: (context) => MQTTest(),
          },
          theme: theme,
          title: 'MQTTest Demo',
        );
      },
    );
  }
}

class MQTTester extends StatefulWidget {
  const MQTTester({Key key}) : super(key: key);
  static const route = '/mqtTester';

  @override
  _MQTTester createState() => _MQTTester();
}

class _MQTTester extends State<MQTTester> with WidgetsBindingObserver, AfterLayoutMixin<MQTTester> {
  bool hideSpinner = true;

  // ignore: non_constant_identifier_names
  Size get ScreenSize => MediaQuery.of(context).size;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('mqtTester initState()');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('mqtTester afterFirstLayout()');
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('mqtTester didChangeDependencies()');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('mqtTester didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    ModeTheme.of(context).setBrightness(brightness);
    Log.t('mqtTester didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    Log.t('mqtTester build()');
    return HudScaffold.progressText(
      context,
      hide: hideSpinner,
      indicatorColors: Swatch(bright: Colors.purpleAccent, dark: Colors.greenAccent),
      progressText: 'MQTTester Showable spinner',
      scaffold: Scaffold(
        appBar: AppBar(
          title: Text('Title: mqtTester'),
        ),
        body: body(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              hideSpinner = false;
              Future.delayed(Duration(seconds: 3), () {
                setState(() {
                  hideSpinner = true;
                });
              });
            });
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('mqtTester didUpdateWidget()');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('mqtTester deactivate()');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('mqtTester dispose()');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    Log.t('mqtTester body()');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('MQTTester Template', style: Theme.of(context).textTheme.display1),
          RaisedButton(
            child: Text('Toggle Mode'),
            onPressed: () {
              ModeTheme.of(context).toggleBrightness();
            },
          ),
          RaisedButton(
            child: Text('Next Screen'),
            onPressed: () {
              /// Navigator.push(context, MaterialPageRoute(builder: (context) => Berky()));
            },
          ),
        ],
      ),
    );
  }
}
