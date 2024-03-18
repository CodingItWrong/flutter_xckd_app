import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:xckd_app/main.dart';
import 'dart:io';

@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<File>()])
import 'unit_test.mocks.dart';

const comics = [
  """
  {
    "month": "",
    "num": 1,
    "link": "",
    "year": "",
    "news": "",
    "safe_title": "The First Comic",
    "transcript": "",
    "alt": "first comic alt-text",
    "img": "https://example.com/1.png",
    "title": "The First Comic",
    "day": ""
  }
  """,
  """
  {
    "month": "",
    "num": 2,
    "link": "",
    "year": "",
    "news": "",
    "safe_title": "The Second Comic",
    "transcript": "",
    "alt": "second comic alt-text",
    "img": "https://example.com/2.png",
    "title": "The Second Comic",
    "day": ""
  }
  """
];

void main() {
  test("get latest comic number", () async {
    var latestComicNumberFile = MockFile();
    var mockHttp = MockClient();

    when(mockHttp.read(Uri.parse('https://xkcd.com/info.0.json')))
        .thenAnswer((_) {
      return Future.value(comics[1]);
    });

    expect(
      await getLatestComicNumber(
        httpClient: mockHttp,
        latestComicNFile: latestComicNumberFile,
      ),
      2,
    );
  });

  group("SelectionPage fetchComic", () {
    test("when not cached", () async {
      var mockHttp = MockClient();
      var latestComicFile = MockFile();

      when(latestComicFile.exists()).thenAnswer((_) => Future.value(false));
      when(mockHttp.read(Uri.parse("https://xkcd.com/2/info.0.json")))
          .thenAnswer((_) => Future.value(comics[1]));

      var selPage = SelectionPage();

      expect(
        await selPage.fetchComic(
          "2",
          httpClient: mockHttp,
          comicFile: latestComicFile,
        ),
        json.decode(comics[1]),
      );
    });

    test("when cached", () async {
      var mockHttp = MockClient();
      var latestComicFile = MockFile();

      when(latestComicFile.exists()).thenAnswer((_) => Future.value(true));
      when(latestComicFile.readAsStringSync()).thenAnswer((_) => comics[1]);

      var selPage = SelectionPage();

      expect(
        await selPage.fetchComic(
          "2",
          httpClient: mockHttp,
          comicFile: latestComicFile,
        ),
        json.decode(comics[1]),
      );
    });
  });
}
