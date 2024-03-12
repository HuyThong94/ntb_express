import 'package:ntbexpress/model/fee_item.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/util/utils.dart';

const timeout = 30;
const commonDateFormat = 'HH:mm dd-MM-yyyy';
final List<FeeItem> feeTable = [];

enum PriceType {
  normal, fixed
}

class NextWarehouse {
  static const String uongbi = 'UB';
  static const String hanoi = 'HN';
  static const String saigon = 'SG';
}

class AppRouter {
  static const String login = '/login';
  static const String homeScreen = '/home_screen';
}

class VietnamAreas {
  static String province =
      'https://raw.githubusercontent.com/aug04/DiaGioiHanhChinhVN/master/json/tinh.json';
  static String district =
      'https://raw.githubusercontent.com/aug04/DiaGioiHanhChinhVN/master/json/huyen.json';
  static String wards =
      'https://raw.githubusercontent.com/aug04/DiaGioiHanhChinhVN/master/json/xa.json';
}

class PrefsKey {
  static const String username = 'usr';
  static const String password = 'pwd';
  static const String remember = 'remember';
  static const String logged = 'logged';
  static const String languageCode = 'language_code';
  static const String requestPushPermissions = 'pn_setting';
}

class ApiUrls {
  ApiUrls._() {
    // _baseUrl = 'http://117.4.244.25:8888';
    _baseUrl = 'http://vanchuyendailong.com:8888';
  }

  static late ApiUrls _instance;

  static ApiUrls instance() {
    if (_instance != null) return _instance;

    _instance = ApiUrls._();
    return _instance;
  }

  late final String _baseUrl;

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String? getLoginUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/login';
  }

  String? getUserInfoUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/users/current-login';
  }

  String? getOrdersUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/orders';
  }

  String? getOrderUrl(String orderId) {
    if (Utils.isNullOrEmpty(_baseUrl) || Utils.isNullOrEmpty(orderId))
      return null;
    return '$_baseUrl/orders/$orderId';
  }

  String? getAddressListByUserUrl(String username) {
    if (Utils.isNullOrEmpty(_baseUrl) || Utils.isNullOrEmpty(username))
      return null;
    return '$_baseUrl/addresses/username/$username';
  }

  String? getPromotionListByOrderUrl(Order order) {
    if (Utils.isNullOrEmpty(_baseUrl) || order == null) return null;
    return '$_baseUrl/promotions?${order.toPromotionQueryString()}';
  }

  String? getFeeTableUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/fee-tables';
  }

  String? getDeviceRegisterUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/app/deviceRegister';
  }

  String ?getUpdateTrackStatusUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/orders/action-type';
  }

  String? getUsersUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/users';
  }

  String? getSaveAddressUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/addresses';
  }

  String? getForgotPasswordUrl(String username) {
    if (Utils.isNullOrEmpty(_baseUrl) || Utils.isNullOrEmpty(username))
      return null;
    return '$_baseUrl/users/verify-code/$username';
  }

  String? getChangePasswordUrl() {
    if (Utils.isNullOrEmpty(_baseUrl))
      return null;
    return '$_baseUrl/users/password/change';
  }

  String? getOrderAppendFilesUrl() {
    if (Utils.isNullOrEmpty(_baseUrl))
      return null;
    return '$_baseUrl/orders/uploadFiles';
  }

  String? getUpdateDeviceLocaleUrl() {
    if (Utils.isNullOrEmpty(_baseUrl))
      return null;
    return '$_baseUrl/app/updateLocale';
  }

  String? getDeleteUserUrl(String username) {
    if (Utils.isNullOrEmpty(_baseUrl) || Utils.isNullOrEmpty(username))
      return null;
    return '$_baseUrl/users/customer/delete/$username';
  }

  String? getRegisterUrl() {
    if (Utils.isNullOrEmpty(_baseUrl)) return null;
    return '$_baseUrl/users/register';
  }
}

class UserType {
  /// Quản trị viên
  static const int admin = 1;

  /// Nhân viên bán hàng
  static const int saleStaff = 2;

  /// Nhân viên kho TQ
  static const int chineseWarehouseStaff = 3;

  /// Nhân viên kho Uông Bí
  static const int uongbiWarehouseStaff = 4;

  /// Nhân viên kho Hà Nội
  static const int hanoiWarehouseStaff = 5;

  /// Nhân viên kho Sài Gòn
  static const int saigonWarehouseStaff = 6;

  /// Khách hàng
  static const int customer = 7;
}

class UserStatus {
  /// Kích hoạt
  static const int active = 1;

  /// Chưa kích hoạt
  static const int inactive = 0;
}

class ActionType {
  /// Tạo đơn hàng mới
  static const int createNewOrder = 1;

  /// Hủy đơn hàng
  static const int cancelOrder = 2;

  /// Nhập kho TQ
  static const int chineseWarehouse = 3;

  /// Gửi yêu cầu xác nhận đóng Gỗ
  static const int sendConfirmationWoodenPacking = 4;

  /// Xác nhận yêu cầu đóng Gỗ
  static const int confirmWoodenPacking = 5;

  /// Xuất kho TQ
  static const int chineseStockOut = 6;

  /// Nhập kho Uông Bí
  static const int uongbiWarehouse = 7;

  /// Nhập kho Hà Nội
  static const int hanoiWarehouse = 8;

  /// Nhập kho Sài Gòn
  static const int saigonWarehouse = 9;

  /// Xuất kho Uông Bí
  static const int outputUongBi = 10;

  /// Xuất kho Hà Nội
  static const int outputHaNoi = 11;

  /// Xuất kho Sài Gòn
  static const int outputSaiGon = 12;

  /// Giao hàng
  static const int delivery = 13;

  /// Đã giao
  static const int delivered = 14;

  /// Xong
  static const int completed = 15;
}

class OrderStatus {
  /// Mới tạo
  static const int newlyCreated = 1;

  /// Đã hủy
  static const int aborted = 2;

  /// Đã nhập kho TQ
  static const int chineseWarehoused = 3;

  /// Chờ đóng Gỗ
  static const int pendingWoodenPacking = 4;

  /// Đã xuất kho TQ
  static const int chineseShippedOut = 5;

  /// Đã nhập kho Uông Bí
  static const int uongbiWarehoused = 6;

  /// Đã nhập kho Hà Nội
  static const int hanoiWarehoused = 7;

  /// Đã nhập kho Sài Gòn
  static const int saigonWarehoused = 8;

  /// Đã xuất kho Uông Bí
  static const int outputUongBi = 9;

  /// Đã xuất kho Hà Nội
  static const int outputHaNoi = 10;

  /// Đã xuất kho Sài Gòn
  static const int outputSaiGon = 11;

  /// Đang giao
  static const int delivery = 12;

  /// Đã giao
  static const int delivered = 13;

  /// Hoàn thành
  static const int completed = 14;

  static const List<int> values = [
    newlyCreated,
    aborted,
    chineseWarehoused,
    pendingWoodenPacking,
    chineseShippedOut,
    uongbiWarehoused,
    hanoiWarehoused,
    saigonWarehoused,
    outputUongBi,
    outputHaNoi,
    outputSaiGon,
    delivery,
    delivered,
    completed
  ];
}

class GoodsType {
  /// Hàng nhái
  static const int fake = 1;

  /// Mỹ phẩm
  static const int cosmetic = 2;

  /// Thực phẩm
  static const int food = 3;

  /// Thuốc
  static const int medicine = 4;

  /// Chất lỏng
  static const int liquid = 5;

  /// Dễ vỡ
  static const int fragile = 6;

  /// Quần áo
  static const int clothes = 7;

  /// Điện tử
  static const int electronic = 8;

  /// Hàng tạp đóng sẵn
  static const int prepackagedGroceries = 9;

  /// Thông thường
  static const int normal = 10;

  /// Siêu nặng
  static const int superHeavy = 11;

  /// Đặc biệt
  static const int special = 12;
}

const List<ProvinceGroup> provinces = [
  ProvinceGroup('BNH', 'Tỉnh Bắc Ninh', 1),
  ProvinceGroup('TNN', 'Tỉnh Thái Nguyên', 1),
  ProvinceGroup('TBH', 'Tỉnh Thái Bình', 1),
  ProvinceGroup('HPH', 'Thành phố Hải Phòng', 1),
  ProvinceGroup('SLA', 'Tỉnh Sơn La', 1),
  ProvinceGroup('DBN', 'Tỉnh Điện Biên', 1),
  ProvinceGroup('LSN', 'Tỉnh Lạng Sơn', 1),
  ProvinceGroup('HYN', 'Tỉnh Hưng Yên', 1),
  ProvinceGroup('HNM', 'Tỉnh Hà Nam', 1),
  ProvinceGroup('HNI', 'Thành phố Hà Nội', 1),
  ProvinceGroup('QNH', 'Tỉnh Quảng Ninh', 1),
  ProvinceGroup('HDG', 'Tỉnh Hải Dương', 1),
  ProvinceGroup('LCU', 'Tỉnh Lai Châu', 1),
  ProvinceGroup('CBG', 'Tỉnh Cao Bằng', 1),
  ProvinceGroup('VPC', 'Tỉnh Vĩnh Phúc', 1),
  ProvinceGroup('BGG', 'Tỉnh Bắc Gian', 1),
  ProvinceGroup('BKN', 'Tỉnh Bắc Kạn', 1),
  ProvinceGroup('HAG', 'Tỉnh Hà Giang', 1),
  ProvinceGroup('NDH', 'Tỉnh Nam Định', 1),
  ProvinceGroup('YBI', 'Tỉnh Yên Bái', 1),
  ProvinceGroup('TQG', 'Tỉnh Tuyên Quang', 1),
  ProvinceGroup('PTO', 'Tỉnh Phú Thọ', 1),
  ProvinceGroup('LCI', 'Tỉnh Lào Cai', 1),
  ProvinceGroup('HBH', 'Tỉnh Hòa Bình', 1),
  ProvinceGroup('QBH', 'Tỉnh Quảng Bình', 2),
  ProvinceGroup('NBH', 'Tỉnh Ninh Bình', 2),
  ProvinceGroup('NAN', 'Tỉnh Nghệ An', 2),
  ProvinceGroup('HTH', 'Tỉnh Hà Tĩnh', 2),
  ProvinceGroup('DNG', 'Thành phố Đà Nẵng', 2),
  ProvinceGroup('THA', 'Tỉnh Thanh Hóa', 2),
  ProvinceGroup('QTI', 'Tỉnh Quảng Trị', 2),
  ProvinceGroup('TTH', 'Tỉnh Thừa Thiên Huế', 2),
  ProvinceGroup('TNH', 'Tỉnh Tây Ninh', 3),
  ProvinceGroup('VLG', 'Tỉnh Vĩnh Long', 3),
  ProvinceGroup('NTN', 'Tỉnh Ninh Thuận', 3),
  ProvinceGroup('TVH', 'Tỉnh Trà Vinh', 3),
  ProvinceGroup('TGG', 'Tỉnh Tiền Giang', 3),
  ProvinceGroup('BDG', 'Tỉnh Bình Dương', 3),
  ProvinceGroup('PYN', 'Tỉnh Phú Yên', 3),
  ProvinceGroup('STG', 'Tỉnh Sóc Trăng', 3),
  ProvinceGroup('QNI', 'Tỉnh Quảng Ngãi', 3),
  ProvinceGroup('QNM', 'Tỉnh Quảng Nam', 3),
  ProvinceGroup('LAN', 'Tỉnh Long An', 3),
  ProvinceGroup('ANG', 'Tỉnh An Giang', 3),
  ProvinceGroup('CTO', 'Thành phố Cần Thơ', 3),
  ProvinceGroup('CMU', 'Tỉnh Cà Mau', 3),
  ProvinceGroup('BTN', 'Tỉnh Bình Thuận', 3),
  ProvinceGroup('BPC', 'Tỉnh Bình Phước', 3),
  ProvinceGroup('BDH', 'Tỉnh Bình Định', 3),
  ProvinceGroup('BTE', 'Tỉnh Bến Tre', 3),
  ProvinceGroup('BLU', 'Tỉnh Bạc Liêu', 3),
  ProvinceGroup('DLK', 'Tỉnh Đắc Lắc', 3),
  ProvinceGroup('DKG', 'Tỉnh Đắc Nông', 3),
  ProvinceGroup('DNI', 'Tỉnh Đồng Nai', 3),
  ProvinceGroup('LDG', 'Tỉnh Lâm Đồng', 3),
  ProvinceGroup('KTM', 'Tỉnh Kon Tum', 3),
  ProvinceGroup('KGG', 'Tỉnh Kiên Giang', 3),
  ProvinceGroup('KHA', 'Tỉnh Khánh Hòa', 3),
  ProvinceGroup('HCM', 'Thành phố Hồ Chí Minh', 3),
  ProvinceGroup('HGG', 'Tỉnh Hậu Giang', 3),
  ProvinceGroup('GLI', 'Tỉnh Gia Lai', 3),
  ProvinceGroup('DTP', 'Tỉnh Đồng Tháp', 3),
  ProvinceGroup('BRV', 'Tỉnh Bà Rịa - Vũng Tàu', 3)
];

class ProvinceGroup {
  final String code;
  final String name;
  final int group;

  const ProvinceGroup(this.code, this.name, this.group);
}

class PromotionType {
  static const int percent = 1;
  static const int specificValue = 2;
  static const int samePrice = 3;
}

enum AllowAction {
  create,
  edit,
  cancel,
  confirmWoodenPacking,
  importChineseWarehouse,
  exportChineseWarehouse,
  importUongBiWarehouse,
  importHaNoiWarehouse,
  importSaiGonWarehouse,
  outputUongBi,
  outputHaNoi,
  outputSaiGon,
  delivery,
  delivered,
  complete
}
