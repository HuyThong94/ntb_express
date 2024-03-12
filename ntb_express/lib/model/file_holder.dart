import 'dart:io';

import 'package:random_string/random_string.dart';

/// Keep file (using for upload image => manager [add, delete])
class FileHolder {
  String? id; // auto generate
  File? file; // file holder
  String? fileUrl; // use when isNetworkImage is true
  bool? isNetworkImage; // set to true if image is a network image
  String? key; // use when wanna store & compare

  FileHolder({this.file, this.key, this.fileUrl, this.isNetworkImage = false}) {
    id = randomAlphaNumeric(16);
  }
}
