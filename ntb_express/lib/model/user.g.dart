// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    username: json['username'] as String,
    password: json['password'] as String,
    fullName: json['fullname'] as String,
    email: json['email'] as String,
    avatarImg: json['avatarImg'] as String,
    userType: json['userType'] as int,
    status: json['status'] as int,
    langKey: json['langKey'] as String,
    createdId: json['createdId'] as String,
    createdDate: json['createdDate'] as num,
    updatedId: json['updatedId'] as String,
    updatedDate: json['updatedDate'] as num,
    address: json['address'] as String,
    phoneNumber: json['phoneNumber'] as String,
    customerId: json['customerId'] as String,
    managerId: json['managerId'] as String,
    commission: (json['commission'] as num)?.toDouble(),
    dob: json['dob'] as num,
    avatarImgDTO: json['avatarImgDTO'] == null
        ? null
        : TCCOFile.fromJson(json['avatarImgDTO'] as Map<String, dynamic>),
    refId: json['refId'] as String,
    resetToken: json['resetToken'] as String,
    isCreate: json['isCreate'] as num,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'fullname': instance.fullName,
      'email': instance.email,
      'avatarImg': instance.avatarImg,
      'userType': instance.userType,
      'status': instance.status,
      'langKey': instance.langKey,
      'createdId': instance.createdId,
      'createdDate': instance.createdDate,
      'updatedId': instance.updatedId,
      'updatedDate': instance.updatedDate,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
      'customerId': instance.customerId,
      'managerId': instance.managerId,
      'commission': instance.commission,
      'dob': instance.dob,
      'avatarImgDTO': instance.avatarImgDTO,
      'refId': instance.refId,
      'resetToken': instance.resetToken,
      'isCreate': instance.isCreate,
    };
