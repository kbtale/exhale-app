// Web implementation of file utilities
class FileUtils {
  static Future<String> getTemporaryPath(String filename) async {
    // Web doesn't have direct file system access, so we return a dummy path
    return 'web_temp/$filename';
  }

  static Future<bool> deleteFile(String path) async {
    // Web doesn't have direct file system access, so we just return true
    return true;
  }
}
