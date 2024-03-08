import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'address.g.dart';

@JsonSerializable()
class Address {
  int addressId;
  @JsonKey(name: 'username')
  String userName;
  @JsonKey(name: 'fullname')
  String fullName;
  String phoneNumber;
  String email;
  String province;
  String district;
  String wards;
  String address;
  String createdId;
  String createdDate;
  String updatedId;
  String updatedDate;

  Address(
      {this.addressId,
      this.userName = '',
      this.fullName = '',
      this.phoneNumber = '',
      this.email = '',
      this.province = '',
      this.district = '',
      this.wards = '',
      this.address = '',
      this.createdId = '',
      this.createdDate = '',
      this.updatedId = '',
      this.updatedDate = ''});

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);

  static Address clone(Address other) {
    final String jsonString = json.encode(other);
    final jsonResponse = json.decode(jsonString);

    return Address.fromJson(jsonResponse as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          addressId == other.addressId &&
          userName == other.userName &&
          fullName == other.fullName &&
          phoneNumber == other.phoneNumber &&
          email == other.email &&
          province == other.province &&
          district == other.district &&
          wards == other.wards &&
          address == other.address &&
          createdId == other.createdId &&
          createdDate == other.createdDate &&
          updatedId == other.updatedId &&
          updatedDate == other.updatedDate;

  @override
  int get hashCode =>
      addressId.hashCode ^
      userName.hashCode ^
      fullName.hashCode ^
      phoneNumber.hashCode ^
      email.hashCode ^
      province.hashCode ^
      district.hashCode ^
      wards.hashCode ^
      address.hashCode ^
      createdId.hashCode ^
      createdDate.hashCode ^
      updatedId.hashCode ^
      updatedDate.hashCode;

  @override
  String toString() {
    return 'Address{addressId: $addressId, userName: $userName, fullName: $fullName, phoneNumber: $phoneNumber, email: $email, province: $province, district: $district, wards: $wards, address: $address, createdId: $createdId, createdDate: $createdDate, updatedId: $updatedId, updatedDate: $updatedDate}';
  }
}
