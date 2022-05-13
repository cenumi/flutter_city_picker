import 'package:city_picker_china/city_picker_china.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      locale: const Locale('zh'),
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final codeController = TextEditingController();
  final provinceController = TextEditingController();
  final cityController = TextEditingController();
  final countyController = TextEditingController();

  _TriggerMode _triggerMode = _TriggerMode.none;

  void _changeMode(_TriggerMode? mode) {
    if (mode == null || mode == _triggerMode) {
      return;
    }
    setState(() {
      _triggerMode = mode;
    });
  }

  Future<void> _invoke() async {
    late final WidgetBuilder builder;

    switch (_triggerMode) {
      case _TriggerMode.byCode:
        builder = (_) => CityPicker.fromCode(code: codeController.text.trim());
        break;
      case _TriggerMode.byCity:
        builder = (_) => CityPicker.fromName(
              province: provinceController.text.trim(),
              city: cityController.text.trim(),
              county: countyController.text.trim(),
            );
        break;
      case _TriggerMode.none:
        builder = (_) => const CityPicker();
        break;
    }

    final res = await showModalBottomSheet<CityResult>(
        context: context, builder: builder);

    if (res == null) {
      return;
    }

    codeController.text = res.code;
    provinceController.text = res.province;
    cityController.text = res.city ?? '';
    countyController.text = res.county ?? '';
  }

  @override
  void dispose() {
    codeController.dispose();
    provinceController.dispose();
    cityController.dispose();
    countyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: _invoke,
        tooltip: 'Invoke',
        child: const Icon(Icons.open_in_new),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            leading: const Text('Code'),
            title: TextField(
              textAlign: TextAlign.right,
              controller: codeController,
            ),
          ),
          ListTile(
            leading: const Text('Province'),
            title: TextField(
              textAlign: TextAlign.right,
              controller: provinceController,
            ),
          ),
          ListTile(
            leading: const Text('City'),
            title: TextField(
              textAlign: TextAlign.right,
              controller: cityController,
            ),
          ),
          ListTile(
            leading: const Text('County'),
            title: TextField(
              textAlign: TextAlign.right,
              controller: countyController,
            ),
          ),
          const Divider(),
          RadioListTile(
            title: const Text('Invoke with nothing'),
            value: _TriggerMode.none,
            groupValue: _triggerMode,
            onChanged: _changeMode,
          ),
          RadioListTile(
            title: const Text('Invoke with code'),
            value: _TriggerMode.byCode,
            groupValue: _triggerMode,
            onChanged: _changeMode,
          ),
          RadioListTile(
            title: const Text('Invoke with names'),
            value: _TriggerMode.byCity,
            groupValue: _triggerMode,
            onChanged: _changeMode,
          ),
        ],
      ),
    );
  }
}

enum _TriggerMode { byCode, byCity, none }
