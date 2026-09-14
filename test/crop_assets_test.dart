import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/constants/crop_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every crop type has a loadable image asset', () async {
    final crops = [...AppConstants.cropTypes, 'Vegetables'];
    for (final crop in crops) {
      final path = CropAssets.pathFor(crop);
      expect(path.endsWith('.png'), isTrue, reason: '$crop should map to a png');
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(1000),
        reason: '$crop image at $path should load',
      );
    }
  });

  test('unknown crops fall back to the produce image', () async {
    expect(CropAssets.pathFor('Dragonfruit'), CropAssets.fallback);
    final data = await rootBundle.load(CropAssets.fallback);
    expect(data.lengthInBytes, greaterThan(1000));
  });
}
