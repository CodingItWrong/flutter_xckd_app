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
    var latestComicNumberExists = false;
    String latestComicNumberString = "NOT SET YET";
    var mockHttp = MockClient();

    when(mockHttp.read(Uri.parse('https://xkcd.com/info.0.json')))
        .thenAnswer((_) {
      return Future.value(comics[1]);
    });
    when(latestComicNumberFile.createSync()).thenAnswer((_) {
      latestComicNumberExists = true;
    });
    when(latestComicNumberFile.create()).thenAnswer((_) {
      latestComicNumberExists = true;
      return Future.value(latestComicNumberFile);
    });
    when(latestComicNumberFile.writeAsStringSync("2")).thenAnswer((_) {
      latestComicNumberExists = true;
      latestComicNumberString = "2";
    });
    when(latestComicNumberFile.writeAsString("2")).thenAnswer((_) {
      latestComicNumberExists = true;
      latestComicNumberString = "2";
      return Future.value(latestComicNumberFile);
    });
    when(latestComicNumberFile.existsSync())
        .thenReturn(latestComicNumberExists);
    when(latestComicNumberFile.exists())
        .thenAnswer((_) => Future.value(latestComicNumberExists));
    when(latestComicNumberFile.readAsStringSync()).thenAnswer((_) {
      assert(latestComicNumberExists, true);
      return "2";
    });
    when(latestComicNumberFile.readAsString()).thenAnswer((_) {
      assert(latestComicNumberExists, true);
      return Future.value(latestComicNumberString);
    });

    expect(
      await getLatestComicNumber(
        httpClient: mockHttp,
        latestComicNFile: latestComicNumberFile,
      ),
      2,
    );
  });
}
