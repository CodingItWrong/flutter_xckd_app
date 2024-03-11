import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

Future<int> getLatestComicNumber() async => json.decode(
      await http.read(
        Uri.parse("https://xkcd.com/info.0.json"),
      ),
    )["num"];

void main() async {
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
      print("Loading $n from cache");
      return json.decode(comicFile.readAsStringSync());
    } else {
      final comic = await http.read(
        Uri.parse(
          "https://xkcd.com/${latestComic - n}/info.0.json",
        ),
      );
      print("Saving $n to cache");
      comicFile.writeAsStringSync(comic);
      return json.decode(comic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
        Image.network(comic["img"]),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(comic["alt"]),
        ),
      ]),
    );
  }
}
