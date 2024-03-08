import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:ntbexpress/model/file_holder.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/image_gallery.dart';

class FileHolderParser {
  final File file;
  final ByteData fileByteData;
  final String fileName;

  FileHolderParser({this.file, this.fileByteData, this.fileName});
}

class ImagePickerWidget extends StatefulWidget {
  final ImagePickerController controller;
  final Widget child;
  final bool allowToDelete;
  final bool confirmDelete;
  final ValueChanged<FileHolder> onAdd;
  final ValueChanged<FileHolder> onRemove;
  final bool readonly;
  final int maxImages;

  const ImagePickerWidget(
      {Key key,
      this.controller,
      this.child,
      this.allowToDelete = true,
      this.confirmDelete = true,
      this.onAdd,
      this.onRemove,
      this.readonly = false,
      this.maxImages = 15})
      : assert(child != null),
        super(key: key);

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final List<FileHolder> _files = [];
  final ImagePicker picker = ImagePicker();

  Future<void> _getImage() async {
    showModalBottomSheet(
        context: context,
        builder: (_) => Container(
              child: Wrap(
                children: [
                  ListTile(
                    leading: Icon(Icons.image),
                    title: Text('${Utils.getLocale(context).cameraRoll}'),
                    onTap: _cameraRoll,
                  ),
                  ListTile(
                    leading: Icon(Icons.camera),
                    title: Text('${Utils.getLocale(context).takeAPhoto}'),
                    onTap: _takePhoto,
                  ),
                ],
              ),
            ));

    return;
  }

  Future<void> _cameraRoll() async {
    Navigator.of(context).pop(); // hide bottom sheet
    List<Asset> files;
    try {
      files = await MultiImagePicker.pickImages(
          maxImages: widget.maxImages - _files.length, enableCamera: true);
    } catch (e) {
      Utils.alert(context,
          title: Utils.getLocale(context).errorOccurred,
          message: 'Error occurred when trying to pick multiple images!');
      print('Error occurred when trying to pick multiple images!');
      return;
    }

    if (files == null) return;
    files.removeWhere((a) => a == null); // cleanup
    _files.addAll(files.map((e) => null).toList());
    setState(() {});

    for (Asset a in files) {
      ByteData byteData = await a.getByteData();
      if (byteData == null) continue;

      final fileHolder = FileHolder(
          file: await compute(_computeFile,
              FileHolderParser(fileByteData: byteData, fileName: a.name)));
      int index = -1;
      for (int i = 0; i < _files.length; i++) {
        if (_files[i] == null) {
          index = i;
          break;
        }
      }

      _files.replaceRange(index, index + 1, [fileHolder]);
      if (widget.onAdd != null) {
        widget.onAdd(fileHolder);
      }

      setState(() {});
      widget?.controller?.files = _files;
    }
  }

  Future<void> _takePhoto() async {
    Navigator.of(context).pop(); // hide bottom sheet
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if (mounted) {
      var file = File(pickedFile.path);
      if (file == null) return;

      setState(() => _files.add(null));

      final fileHolder = FileHolder(
          file: await compute(
              _computeFile,
              FileHolderParser(
                  file: file,
                  fileName:
                      file.path.substring(file.path.lastIndexOf('/') + 1))));

      int index = -1;
      for (int i = 0; i < _files.length; i++) {
        if (_files[i] == null) {
          index = i;
          break;
        }
      }

      _files.replaceRange(index, index + 1, [fileHolder]);
      if (widget.onAdd != null) {
        widget.onAdd(fileHolder);
      }

      setState(() {});
      widget?.controller?.files = _files;
    }
  }

  static Future<File> _computeFile(FileHolderParser parser) async {
    if (parser == null ||
        (parser.fileByteData == null && parser.file == null) ||
        Utils.isNullOrEmpty(parser.fileName)) return null;

    return await Utils.resizeImage(MemoryFileSystem().file(parser.fileName)
      ..writeAsBytesSync(parser.file == null
          ? parser.fileByteData.buffer.asUint8List()
          : parser.file.readAsBytesSync()));
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller.files != null) {
      widget.controller.addListener(() {
        setState(() {
          _files
            ..clear()
            ..addAll(widget.controller.files);
        });
      });
    }
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.readonly ? null : _getImage,
      child: Card(
        child: Icon(
          Icons.add,
          color: Theme.of(context).disabledColor,
          size: 35.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: null,
            child: widget.child,
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (orientation == Orientation.portrait) ? 4 : 6,
            ),
            itemCount: widget.readonly
                ? _files.length
                : _files.length == widget.maxImages
                    ? _files.length
                    : _files.length + 1,
            itemBuilder: (context, index) {
              if (!widget.readonly && index == _files.length)
                return _buildAddButton();

              final fileHolder = _files.elementAt(index);

              if (fileHolder == null) {
                return Card(
                  child: Center(
                    child: Text(
                      '${Utils.getLocale(context).processing}...',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 10.0,
                      ),
                    ),
                  ),
                );
              }

              return Card(
                child: GestureDetector(
                  onTap: () {
                    // Show gallery
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GalleryPhotoViewWrapper(
                          galleryItems: _files,
                          backgroundDecoration: const BoxDecoration(
                            color: Colors.black,
                          ),
                          initialIndex: index,
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                    );
                  },
                  child: GridTile(
                    child: fileHolder == null
                        ? Text('${Utils.getLocale(context).empty}')
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              fileHolder.isNetworkImage
                                  ? Image.network(
                                      fileHolder.fileUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      fileHolder.file,
                                      fit: BoxFit.cover,
                                    ),
                              !widget.allowToDelete
                                  ? SizedBox()
                                  : Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!widget.confirmDelete) {
                                            if (widget.onRemove != null) {
                                              widget.onRemove(fileHolder);
                                            }
                                            widget.controller
                                                .remove(fileHolder);
                                            return;
                                          }

                                          Utils.confirm(
                                            context,
                                            title:
                                                '${Utils.getLocale(context).confirmation}',
                                            message:
                                                '${Utils.getLocale(context).confirmDeleteFileMessage}',
                                            onAccept: () {
                                              if (widget.onRemove != null) {
                                                widget.onRemove(fileHolder);
                                              }
                                              widget.controller
                                                  .remove(fileHolder);
                                            },
                                          );
                                        },
                                        child: Container(
                                          color: Colors.black45,
                                          child: Icon(
                                            Icons.clear,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ImagePickerController extends ValueNotifier<List<FileHolder>> {
  ImagePickerController({List<FileHolder> files}) : super(files ?? []);

  List<FileHolder> get files => value;

  set files(List<FileHolder> files) {
    value = value
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  void add(FileHolder file) {
    value.add(file);
    notifyListeners();
  }

  void remove(FileHolder file) {
    value.remove(file);
    notifyListeners();
  }

  void clear() {
    value.clear();
    notifyListeners();
  }
}
