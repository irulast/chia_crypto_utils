import 'package:chia_crypto_utils/src/nft/utils/nft_data_csv_parser/uploadable_value.dart';

class NftThemeCsvData {
  NftThemeCsvData({
    required this.name,
    required this.accentColor,
    required this.brightness,
    required this.buttonColor,
    required this.buttonOpacity,
    required this.imageData,
    required this.nftTextOutlineColor,
    required this.nftTextColor,
  });

  final String name;
  final String accentColor;
  final String brightness;
  final String buttonColor;
  final double buttonOpacity;
  final String? nftTextOutlineColor;
  final String? nftTextColor;

  final List<ThemeImageData> imageData;
}

class ThemeImageData {
  ThemeImageData({
    required this.size,
    required this.image,
    required this.background,
  });
  final num size;
  final UploadableValue? image;
  final UploadableValue? background;
}
