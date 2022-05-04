import 'dart:io';

import 'package:path/path.dart' as path;

File loadLocalFile(String relativeFilepath) {
  var fullFilepath = path.join(path.current, relativeFilepath);
  fullFilepath = path.normalize(fullFilepath);
  return File(fullFilepath);
}
