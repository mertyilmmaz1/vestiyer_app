/// Firebase Storage path constants.
abstract class StoragePaths {
  static String clothingImage(String userId, String itemId) =>
      'users/$userId/clothing/$itemId.jpg';
}
