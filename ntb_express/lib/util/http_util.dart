import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as hparser;
import 'package:ntbexpress/model/file_holder.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';

class HttpUtil {
  static Future<void> get(String url,
      {Map<String, String> headers,
      ValueChanged<http.Response> onResponse,
      VoidCallback onTimeout}) async {
    if (Utils.isNullOrEmpty(url) ||
        SessionUtil.instance() == null ||
        Utils.isNullOrEmpty(SessionUtil.instance().authToken)) return;
    Map<String, String> _headers = {
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}'
    };

    if (headers != null) {
      _headers.addAll(headers);
    }

    http.Response resp;
    try {
      resp = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: timeout), onTimeout: () {
        onTimeout?.call();
        return null;
      });
    } catch (e) {
      // ignored
    }
    if (onResponse != null) {
      onResponse(resp);
    }
  }

  static Future<void> getNotAuth(String url,
      {Map<String, String> headers,
        ValueChanged<http.Response> onResponse,
        VoidCallback onTimeout}) async {
    if (Utils.isNullOrEmpty(url)) return;
    Map<String, String> _headers = {};

    if (headers != null) {
      _headers.addAll(headers);
    }

    http.Response resp;
    try {
      resp = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: timeout), onTimeout: () {
        onTimeout?.call();
        return null;
      });
    } catch (e) {
      // ignored
    }
    if (onResponse != null) {
      onResponse(resp);
    }
  }

  static Future<void> head(String url,
      {Map<String, String> headers,
      ValueChanged<http.Response> onResponse,
      VoidCallback onTimeout}) async {
    if (Utils.isNullOrEmpty(url) ||
        SessionUtil.instance() == null ||
        Utils.isNullOrEmpty(SessionUtil.instance().authToken)) return;
    Map<String, String> _headers = {
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}'
    };

    if (headers != null) {
      _headers.addAll(headers);
    }

    http.Response resp;
    try {
      resp = await http
          .head(url, headers: _headers)
          .timeout(const Duration(seconds: timeout), onTimeout: () {
        onTimeout?.call();
        return null;
      });
    } catch (e) {
      // ignored
    }
    if (onResponse != null) {
      onResponse(resp);
    }
  }

  static Future<void> put(String url,
      {Map<String, String> headers,
      Map<String, dynamic> body,
      ValueChanged<http.Response> onResponse,
      VoidCallback onTimeout}) async {
    if (Utils.isNullOrEmpty(url) ||
        SessionUtil.instance() == null ||
        Utils.isNullOrEmpty(SessionUtil.instance().authToken)) return;
    Map<String, String> _headers = {
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}'
    };

    if (headers != null) {
      _headers.addAll(headers);
    }

    http.Response resp;
    try {
      resp = await http
          .put(url, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: timeout), onTimeout: () {
        onTimeout?.call();
        return null;
      });
    } catch (e) {
      // ignored
    }
    if (onResponse != null) {
      onResponse(resp);
    }
  }

  static Future<void> delete(String url,
      {Map<String, String> headers,
        ValueChanged<http.Response> onResponse,
        VoidCallback onTimeout}) async {
    if (Utils.isNullOrEmpty(url) ||
        SessionUtil.instance() == null ||
        Utils.isNullOrEmpty(SessionUtil.instance().authToken)) return;
    Map<String, String> _headers = {
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}'
    };

    if (headers != null) {
      _headers.addAll(headers);
    }

    http.Response resp;
    try {
      resp = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: timeout), onTimeout: () {
        onTimeout?.call();
        return null;
      });
    } catch (e) {
      // ignored
    }
    if (onResponse != null) {
      onResponse(resp);
    }
  }

  static Future<void> post(String url,
      {Map<String, String> headers,
      Map<String, dynamic> body,
      ValueChanged<http.Response> onResponse,
      VoidCallback onTimeout,
      ValueChanged<dynamic> onError}) async {
    if (Utils.isNullOrEmpty(url) ||
        SessionUtil.instance() == null ||
        Utils.isNullOrEmpty(SessionUtil.instance().authToken)) return;
    Map<String, String> _headers = {
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}'
    };

    if (headers != null) {
      _headers.addAll(headers);
    }

    http.Response resp;

    try {
      resp = await http
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: timeout), onTimeout: () {
        onTimeout?.call();
        return null;
      });
    } catch (e) {
      // ignored
      onError?.call(e);
    }

    if (onResponse != null) {
      onResponse(resp);
    } else {
      onError?.call(null);
    }
  }

  static Future<void> postOrder(String url,
      {Order order,
      List<FileHolder> files,
      ValueChanged<http.Response> onDone,
      VoidCallback onTimeout}) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(http.MultipartFile.fromString(
      'orderDTO',
      jsonEncode(order.toJson()),
      filename: 'orderDTO',
      contentType: hparser.MediaType.parse('application/json; charset=utf-8'),
    ));
    if (files != null && files.isNotEmpty) {
      files.forEach((f) {
        if (f != null && f.file != null) {
          final fileName = _getFileName(f.file);
          final extension = _getExtension(fileName);

          request.files.add(http.MultipartFile.fromBytes(
              'orderImages', f.file.readAsBytesSync(),
              filename: fileName,
              contentType: hparser.MediaType('image', extension)));
        }
      });
    }
    request.headers.addAll({
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}',
    });

    var response = await request
        .send()
        .timeout(const Duration(seconds: timeout), onTimeout: () {
      onTimeout?.call();
      return null;
    });

    if (onDone != null) {
      var resp = await http.Response.fromStream(response);
      onDone(resp);
    }
  }

  static Future<void> postUser(String url,
      {User user,
      FileHolder avatar,
      bool update = false,
      ValueChanged<http.Response> onDone,
      VoidCallback onTimeout}) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(http.MultipartFile.fromString(
      'userDTO',
      jsonEncode(user.toJson()),
      filename: 'userDTO',
      contentType: hparser.MediaType.parse('application/json; charset=utf-8'),
    ));
    if (avatar != null) {
      final fileName = _getFileName(avatar.file);
      final extension = _getExtension(fileName);

      request.files.add(http.MultipartFile.fromBytes(
          'avatarImg', avatar.file.readAsBytesSync(),
          filename: fileName,
          contentType: hparser.MediaType('image', extension)));
    }
    request.headers.addAll({
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}',
    });

    var response = await request
        .send()
        .timeout(const Duration(seconds: timeout), onTimeout: () {
      onTimeout?.call();
      return null;
    });

    if (onDone != null) {
      var resp = await http.Response.fromStream(response);
      onDone(resp);
    }
  }

  static Future<void> postRegister(String url,
      {User user,
        ValueChanged<http.Response> onDone,
        VoidCallback onTimeout}) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(http.MultipartFile.fromString(
      'userDTO',
      jsonEncode(user.toJson()),
      filename: 'userDTO',
      contentType: hparser.MediaType.parse('application/json; charset=utf-8'),
    ));
    var response = await request
        .send()
        .timeout(const Duration(seconds: timeout), onTimeout: () {
      onTimeout?.call();
      return null;
    });

    if (onDone != null) {
      var resp = await http.Response.fromStream(response);
      onDone(resp);
    }
  }

  static String _getFileName(File file) {
    return file.path.substring(file.path.lastIndexOf('/') + 1);
  }

  static String _getExtension(String fileName) {
    return fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
  }

  static Future<bool> updateOrderTrackingStatus(String orderId, int status,
      {ConfirmationStatus confirmStatus, ValueChanged<dynamic> error}) async {
    final c = Completer<bool>();

    var data = {'orderId': orderId, 'actionType': status};
    if (confirmStatus != null) {
      if (confirmStatus.packCount != null && confirmStatus.packCount > 0) {
        data['packCount'] = confirmStatus.packCount;
      }
      if (!Utils.isNullOrEmpty(confirmStatus.nextWarehouse)) {
        data['nextWarehouse'] = confirmStatus.nextWarehouse;
      }
      if (!Utils.isNullOrEmpty(confirmStatus.note)) {
        data['note'] = confirmStatus.note;
      }
    }

    post(
      ApiUrls.instance().getUpdateTrackStatusUrl(),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: data,
      onResponse: (resp) async {
        // check if need to append files => do it
        if (confirmStatus != null &&
            confirmStatus.files != null &&
            confirmStatus.files.isNotEmpty &&
            resp != null &&
            resp.statusCode == 200) {
          await appendFiles(ApiUrls.instance().getOrderAppendFilesUrl(),
              orderId, confirmStatus.files);
          c.complete(resp != null && resp.statusCode == 200);
        } else {
          c.complete(resp != null && resp.statusCode == 200);
        }
      },
      onTimeout: () {
        c.complete(false);
      },
      onError: (e) {
        error?.call(e);
      }
    );

    return c.future;
  }

  static Future<void> appendFiles(
      String url, String orderId, List<File> files) async {
    if (Utils.isNullOrEmpty(url) ||
        Utils.isNullOrEmpty(orderId) ||
        files == null ||
        files.isEmpty) return;

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields['orderId'] = orderId;
    files.forEach((f) {
      if (f != null) {
        final fileName = _getFileName(f);
        final extension = _getExtension(fileName);

        request.files.add(http.MultipartFile.fromBytes(
            'orderImages', f.readAsBytesSync(),
            filename: fileName,
            contentType: hparser.MediaType('image', extension)));
      }
    });
    request.headers.addAll({
      'Authorization': 'Bearer ${SessionUtil.instance().authToken}',
    });

    await request.send().timeout(const Duration(seconds: timeout),
        onTimeout: () {
      print('#appendFiles(...) - REQUEST TIMED OUT!');
      return null;
    });
  }

  static Future<Order> getOrder(String orderId) async {
    final c = Completer<Order>();

    HttpUtil.get(
      ApiUrls.instance().getOrderUrl(orderId),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      onResponse: (resp) async {
        if (resp != null && resp.statusCode == 200) {
          dynamic json = Utils.isNullOrEmpty(resp.body)
              ? null
              : jsonDecode(utf8.decode(resp.bodyBytes));
          if (json == null) {
            c.complete(null);
            return;
          }
          Order order = Order.fromJson(json);
          if (order == null) {
            c.complete(null);
            return;
          }

          c.complete(order);
        }
      },
      onTimeout: () {
        c.complete(null);
      },
    );

    return c.future;
  }

  static Future<File> download(String url) async {
    final c = Completer<File>();
    HttpClient client = new HttpClient();
    var _downloadData = List<int>();
    final extension = url.substring(url.lastIndexOf('.'));

    client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      response.listen((d) => _downloadData.addAll(d), onDone: () {
        c.complete(MemoryFileSystem()
            .file('${DateTime.now().millisecondsSinceEpoch}$extension')
              ..writeAsBytesSync(_downloadData));
      });
    }).timeout(Duration(seconds: timeout), onTimeout: () {
      c.complete(null);
    });

    return c.future;
  }

  static Future<void> updateLocale(String deviceId, String locale) async {
    String _locale =
        locale == 'vi' ? 'vi_VN' : locale == 'en' ? 'en_US' : 'zh_CN';
    post(
      ApiUrls.instance().getUpdateDeviceLocaleUrl(),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: {'deviceId': deviceId, 'locale': _locale},
      onResponse: (resp) {
        if (resp != null && resp.statusCode == 200) {
          print('Update device locale success for $deviceId');
          return;
        }

        print('Update device locale failed for $deviceId');
      },
      onTimeout: () {},
    );
  }
}
