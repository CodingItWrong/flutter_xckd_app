import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

Future<int> getLatestComicNumber() async {
  final dir = await getTemporaryDirectory();
  var file = File("${dir.path}/latestComicNumber.txt");
  int n = 1;

  try {
    n = json.decode(
      await http.read(
        Uri.parse("https://xkcd.com/info.0.json"),
      ),
    )["num"];
    file.exists().then((exists) {
      if (!exists) {
        file.createSync();
      }
      file.writeAsString("$n");
    });
  } catch (e) {
    if (file.existsSync() && file.readAsStringSync() != "") {
      n = int.parse(file.readAsStringSync());
    }
  }

  return n;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      home: HomeScreen(
        title: "XKCD app",
        latestComic: await getLatestComicNumber(),
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.latestComic,
    required this.title,
  });
  final int latestComic;
  final String title;

  Future<Map<String, dynamic>> _fetchComic(int n) async {
    final dir = await getTemporaryDirectory();
    int comicNumber = latestComic - n;
    var comicFile = File("${dir.path}/$comicNumber.json");

    if (await comicFile.exists() && comicFile.readAsStringSync() != "") {
      return json.decode(comicFile.readAsStringSync());
    } else {
      final comic = await http.read(
        Uri.parse(
          "https://xkcd.com/${latestComic - n}/info.0.json",
        ),
      );
      comicFile.writeAsStringSync(comic);
      return json.decode(comic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.looks_one),
            tooltip: "Select Comics by Number",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SelectionPage(),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: latestComic,
        itemBuilder: (context, i) => FutureBuilder(
          future: _fetchComic(i),
          builder: (context, comicResult) => comicResult.hasData
              ? ComicTile(comic: comicResult.data)
              : const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Padding(
                      padding: EdgeInsets.all(3.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class ComicTile extends StatelessWidget {
  const ComicTile({super.key, required this.comic});
  final Map<String, dynamic>? comic;

  @override
  Widget build(BuildContext context) {
    if (comic == null) {
      return const Placeholder();
    }
    var presentComic = comic!;

    return ListTile(
      leading: Image.network(
        presentComic["img"],
        height: 30,
        width: 30,
      ),
      title: Text(presentComic["title"]),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComicPage(comic: presentComic),
          ),
        );
      },
    );
  }
}

class ComicPage extends StatelessWidget {
  const ComicPage({super.key, required this.comic});
  final Map<String, dynamic> comic;

  void _launchComic(int comicNumber) {
    launchUrl(Uri.parse("https://xkcd.com/$comicNumber/"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("#${comic["num"]}")),
      body: ListView(children: [
        Center(
          child: Text(
            comic["title"],
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        InkWell(
          onTap: () {
            _launchComic(comic["num"]);
          },
          child: Image.network(comic["img"]),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(comic["alt"]),
        ),
      ]),
    );
  }
}

class SelectionPage extends StatelessWidget {
  const SelectionPage({super.key});

  Future<Map<String, dynamic>> _fetchComic(String n) async {
    final dir = await getTemporaryDirectory();
    var comicFile = File("${dir.path}.$n.json}");

    if (await comicFile.exists() && comicFile.readAsStringSync() != "") {
      return json.decode(comicFile.readAsStringSync());
    } else {
      final comic =
          await http.read(Uri.parse("https://xkcd.com/$n/info.0.json"));
      print(comic);
      comicFile.writeAsString(comic);
      return json.decode(comic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comic selection"),
      ),
      body: Center(
        child: TextField(
          decoration: const InputDecoration(
            labelText: "Insert comic #",
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
          onSubmitted: (a) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: _fetchComic(a),
                builder: (context, snapshot) {
                  print(snapshot.data);
                  if (snapshot.hasData && snapshot.data != null) {
                    return ComicPage(comic: snapshot.data!);
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
