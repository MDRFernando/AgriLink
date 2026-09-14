abstract final class CropAssets {
  static const directory = 'assets/images/crops';
  static const fallback = '$directory/produce.png';

  static const Map<String, String> _paths = {
    'rice': '$directory/rice.png',
    'wheat': '$directory/wheat.png',
    'maize': '$directory/maize.png',
    'corn': '$directory/maize.png',
    'potato': '$directory/potato.png',
    'tomato': '$directory/tomato.png',
    'onion': '$directory/onion.png',
    'tea': '$directory/tea.png',
    'coconut': '$directory/coconut.png',
    'chilli': '$directory/chilli.png',
    'chili': '$directory/chilli.png',
    'banana': '$directory/banana.png',
    'vegetables': '$directory/vegetables.png',
    'vegetable': '$directory/vegetables.png',
  };

  static String pathFor(String cropType) {
    final key = cropType.trim().toLowerCase();
    return _paths[key] ?? fallback;
  }
}
