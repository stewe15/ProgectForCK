import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebSocket Demo',
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebSocketChannel channel;
  List<String> messages = [];
  String inputMessage = "";

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
        Uri.parse("wss://serverck.onrender.com/ws/parse"));
    channel.stream.listen((message) {
      setState(() {
        messages.add(message);
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close(status.normalClosure);
    super.dispose();
  }

  void sendMessage(String message) {
    if (message.isNotEmpty) {
      channel.sink.add(message);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.sizeOf(context).width;
    double h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Введите URL для парсинга...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      inputMessage = value;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    messages.clear();
                    sendMessage(inputMessage);
                  },
                ),
              ],
            ),
          ),
          Container(
            height: h * 0.1,
            width: w * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: const Color.fromARGB(255, 44, 111, 236),
            ),
            child: TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HtmlParse()));
                },
                child: const Text(
                  "Парсинг по html-гегам",
                  style: TextStyle(color: Colors.white),
                )),
          ),
        ],
      ),
    );
  }
}

class HtmlParse extends StatefulWidget {
  const HtmlParse({super.key});

  @override
  State<HtmlParse> createState() => _HtmlParseState();
}

class _HtmlParseState extends State<HtmlParse> {
  late WebSocketChannel channel;
  List<String> messages = [];
  String inputMessage = "";
  String inputTeg = "";
  Future<void> openFileExplorer() async {
    //Не работает
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;
    final storageStatus = android.version.sdkInt < 33
        ? await Permission.storage.request()
        : PermissionStatus.granted;

    if (storageStatus.isGranted) {
      String? filePath = await FilePicker.platform
          .pickFiles(
            type: FileType.any,
          )
          .then((result) => result?.files.single.path);

      if (filePath != null) {
        File file = File(filePath);
        try {
          if (messages.isNotEmpty) {
            await file.writeAsString(messages.join('\n'), mode: FileMode.write);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Файл обновлен: $filePath')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Нет данных для сохранения')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при сохранении файла: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл не выбран')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Разрешение на доступ к хранилищу не предоставлено')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
        Uri.parse("wss://serverck.onrender.com/ws/parseViaTeg"));
    channel.stream.listen((message) {
      setState(() {
        messages.add(message + '\n');
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close(status.normalClosure);
    super.dispose();
  }

  void sendMessage(String message) {
    if (message.isNotEmpty) {
      channel.sink.add(message);
      setState(() {});
    }
  }

  void Save() {}

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.sizeOf(context).width;
    double h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Назад',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(messages[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Введите URL для парсинга...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    inputMessage = value;
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Введите тег для парсинга...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    inputTeg = value;
                  },
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
                child: Container(
              height: h * 0.1,
              width: w * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: const Color.fromARGB(255, 44, 111, 236),
              ),
              child: TextButton(
                  onPressed: () {
                    messages.clear();
                    sendMessage('${inputMessage}\t${inputTeg}');
                  },
                  child: Text(
                    "Парсить",
                    style: TextStyle(color: Colors.white),
                  )),
            )),
            Container(
              width: 4,
            ),
            Expanded(
                child: Container(
              height: h * 0.1,
              width: w * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.green,
              ),
              child: TextButton(
                  onPressed: openFileExplorer,
                  child: Text(
                    "Сохранить",
                    style: TextStyle(color: Colors.white),
                  )),
            ))
          ],
        )
      ]),
    );
  }
}
