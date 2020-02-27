import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mqtt/flutter_mqtt.dart';
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
  final MQTTStream mqttStream = MQTTStream();
  MQTTManager mqttManager;
  MQTTAppConnectionState currentAppState = MQTTAppConnectionState.connected;

  String textBody = 'Output here!';

  final TextEditingController _hostTextController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();

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
    _hostTextController.dispose();
    _messageTextController.dispose();
    _topicTextController.dispose();
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    Log.t('mqtTester body()');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text('MQTTester Template', style: Theme.of(context).textTheme.display1),
        RaisedButton(
          child: Text('Toggle Mode'),
          onPressed: () {
            ModeTheme.of(context).toggleBrightness();
          },
        ),
        Row(
          children: [
            RaisedButton(
              child: Text('Connect'),
              onPressed: () {
                _setup();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Broker: test.mosquitto.org, subject: silversphere/funstuff'),
            ),
          ],
        ),
        RaisedButton(
          child: Text('Disconnect'),
          onPressed: () {
            mqttManager.disconnect();
          },
        ),
        _buildPublishMessageRow(),
        //_buildEditableColumn(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Expanded(child: Text(textBody)),
        ),
      ],
    );
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText, MQTTAppConnectionState state) {
    bool shouldEnable = true;
//    if (controller == _messageTextController &&
//        state == MQTTAppConnectionState.connected) {
//      shouldEnable = true;
//    } else if ((controller == _hostTextController &&
//        state == MQTTAppConnectionState.disconnected) || (controller == _topicTextController &&
//        state == MQTTAppConnectionState.disconnected)) {
//      shouldEnable = true;
//    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  Widget _buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          _buildTextFieldWith(_hostTextController, 'Enter broker address', currentAppState),
          const SizedBox(height: 10),
          _buildTextFieldWith(_topicTextController, 'Enter a topic to subscribe or listen', currentAppState),
          const SizedBox(height: 10),
          _buildPublishMessageRow(),
          const SizedBox(height: 10),
          _buildConnecteButtonFrom(currentAppState),
        ],
      ),
    );
  }

  Widget _buildConnecteButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          child: RaisedButton(
              color: Colors.lightBlueAccent,
              child: const Text('Connect'),
              onPressed: () {
                mqttManager.connect();
              }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RaisedButton(
            color: Colors.redAccent,
            child: const Text('Disconnect'),
            onPressed: () {
              mqttManager.disconnect();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPublishMessageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: _buildTextFieldWith(_messageTextController, 'Enter a message', currentAppState),
        ),
        _buildSendButtonFrom(currentAppState)
      ],
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return RaisedButton(
      color: Colors.green,
      child: const Text('Send'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null, //
    );
  }

  void _publishMessage(String text) {
//    String osPrefix = 'Flutter_iOS';
//    if(Platform.isAndroid){
//      osPrefix = 'Flutter_Android';
//    }
//    final String message = osPrefix + ' says: ' + text;
    mqttManager.publish(text);
    _messageTextController.clear();
  }

  void _setup() {
    mqttStream.stream.listen((mqttResponse) {
      Log.i(mqttResponse.data);
      setState(() {
        textBody += '\n' + mqttResponse.data;
      });
    });

    mqttManager = MQTTManager(host: 'test.mosquitto.org', sink: mqttStream.sink, topic: 'silversphere/funstuff')
      ..initializeMQTTClient()
      ..connect();
  }
}
