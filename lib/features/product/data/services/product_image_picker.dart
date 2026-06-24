import 'package:cafe/features/product/data/services/product_image_uploader.dart';
import 'package:image_picker/image_picker.dart' as platform;

enum ProductImageSource { camera, gallery }

abstract class ProductImagePicker {
  Future<ProductImageFile?> pick(ProductImageSource source);
}

class DeviceProductImagePicker implements ProductImagePicker {
  DeviceProductImagePicker({platform.ImagePicker? picker})
    : _picker = picker ?? platform.ImagePicker();

  final platform.ImagePicker _picker;

  @override
  Future<ProductImageFile?> pick(ProductImageSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        ProductImageSource.camera => platform.ImageSource.camera,
        ProductImageSource.gallery => platform.ImageSource.gallery,
      },
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;

    return ProductImageFile(
      bytes: await file.readAsBytes(),
      fileName: file.name,
      contentType: _contentType(file.name),
    );
  }

  String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
