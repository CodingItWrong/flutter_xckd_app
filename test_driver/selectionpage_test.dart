import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group("Selection Page", () {
    FlutterDriver? driver;
    SerializableFinder appBarText = find.byValueKey("AppBar text");

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        driver?.close();
      }
    });

    test("Verify Page is Loaded", () async {
      await driver?.waitFor(appBarText);
      expect(await driver?.getText(appBarText), "Comic selection");
    });

    test("Open Comic", () async {
      await driver?.tap(find.byValueKey("insert comic"));
      await driver?.enterText("1");
      await driver?.tap(find.byValueKey("submit comic"));
      await driver?.waitFor(find.text("#1"));
      expect(await driver?.getText(appBarText), "#1");
    });
  });
}
