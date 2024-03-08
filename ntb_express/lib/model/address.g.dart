// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) {
  return Address(
    addressId: json['addressId'] as int,
    userName: json['username'] as String,
    fullName: json['fullname'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String,
    province: json['province'] as String,
    district: json['district'] as String,
    wards: json['wards'] as String,
    address: json['address'] as String,
    createdId: json['createdId'] as String,
    createdDate: json['createdDate'] as String,
    updatedId: json['updatedId'] as String,
    updatedDate: json['updatedDate'] as String,
  );
}

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'addressId': instance.addressId,
      'username': instance.userName,
      'fullname': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'province': instance.province,
      'district': instance.district,
      'wards': instance.wards,
      'address': instance.address,
      'createdId': instance.createdId,
      'createdDate': instance.createdDate,
      'updatedId': instance.updatedId,
      'updatedDate': instance.updatedDate,
    };
