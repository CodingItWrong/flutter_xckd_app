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
  });
}
