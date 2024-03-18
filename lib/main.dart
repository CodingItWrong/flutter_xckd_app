import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

Future<int> getLatestComicNumber({
  http.Client? httpClient,
  File? latestComicNFile,
}) async {
  httpClient ??= http.Client();

  if (latestComicNFile == null) {
    final dir = await getTemporaryDirectory();
    latestComicNFile = File('${dir.path}/latestComicNumber.txt');
  }

  int n = 1;

  try {
    n = json.decode(
      await httpClient.read(
        Uri.parse("https://xkcd.com/info.0.json"),
      ),
    )["num"];
    latestComicNFile.exists().then((exists) {
      if (!exists) {
        latestComicNFile?.createSync();
      }
      latestComicNFile?.writeAsString("$n");
    });
  } catch (e) {
    if (latestComicNFile.existsSync() &&
        latestComicNFile.readAsStringSync() != "") {
      n = int.parse(latestComicNFile.readAsStringSync());
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

  Future<Map<String, dynamic>> fetchComic(
    int n, {
    http.Client? httpClient,
    File? comicFile,
  }) async {
    int comicNumber = latestComic - n;
    Directory? dir;

    httpClient ??= http.Client();

    if (comicFile == null) {
      dir = await getTemporaryDirectory();
      comicFile = File("${dir.path}/$comicNumber.json");
    }

    if (await comicFile.exists() && comicFile.readAsStringSync() != "") {
      return json.decode(comicFile.readAsStringSync());
    } else {
      final comic = await http.read(
        Uri.parse("https://xkcd.com/${latestComic - n}/info.0.json"),
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
                builder: (context) => SelectionPage(),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: latestComic,
        itemBuilder: (context, i) => FutureBuilder(
          future: fetchComic(i),
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
      appBar: AppBar(
        title: Text(
          "#${comic["num"]}",
          key: const Key("AppBar text"),
        ),
      ),
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
  SelectionPage({super.key});

  final TextEditingController _controller = TextEditingController();

  Future<Map<String, dynamic>> fetchComic(
    String n, {
    http.Client? httpClient,
    File? comicFile,
  }) async {
    Directory? dir;
    httpClient ??= http.Client();

    if (comicFile == null) {
      dir = await getTemporaryDirectory();
      comicFile = File("${dir.path}/$n.json");
    }

    if (await comicFile.exists() && comicFile.readAsStringSync() != "") {
      return json.decode(comicFile.readAsStringSync());
    } else {
      final comic = await httpClient.read(
        Uri.parse("https://xkcd.com/$n/info.0.json"),
      );

      comicFile.writeAsString(comic);
      return json.decode(comic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Comic selection",
          key: Key("AppBar text"),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            key: const Key("insert comic"),
            controller: _controller,
            decoration: const InputDecoration(
              labelText: "Insert comic #",
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (a) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FutureBuilder(
                  future: fetchComic(a),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ErrorPage();
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return ComicPage(comic: snapshot.data!);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
          ),
          OutlinedButton(
            key: const Key("submit comic"),
            child: Text("Open".toUpperCase()),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FutureBuilder(
                  future: fetchComic(_controller.text),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ErrorPage();
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return ComicPage(comic: snapshot.data!);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Error"),
      ),
      body: const Column(children: [
        Icon(Icons.not_interested),
        Text("The comic you have selected doesn't exist or isn't available"),
      ]),
    );
  }
}
