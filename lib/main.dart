import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';

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

  Future<Map<String, dynamic>> _fetchComic(int n) async => json.decode(
        await http.read(
          Uri.parse(
            "https://xkcd.com/${latestComic - n}/info.0.json",
          ),
        ),
      );

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
              : const Divider(),
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
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ComicPage(comic),
        //   ),
        // );
      },
    );
  }
}
