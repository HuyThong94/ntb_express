import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:ntbexpress/model/tcco_file.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  String username;
  String password;
  @JsonKey(name: 'fullname')
  String fullName;
  String email;
  String avatarImg;
  int userType;
  int status;
  String langKey;
  String createdId;
  num? createdDate;
  String updatedId;
  num? updatedDate;
  String address;
  String phoneNumber;
  String customerId;
  String managerId;
  double commission;
  num? dob;
  TCCOFile? avatarImgDTO;
  String refId;
  String resetToken;
  int? isCreate;

  User(
      {this.username = '',
      this.password = '',
      this.fullName = '',
      this.email = '',
      this.avatarImg = '',
      this.userType = 0,
      this.status = 0,
      this.langKey = '',
      this.createdId = '',
      this.createdDate,
      this.updatedId = '',
      this.updatedDate,
      this.address = '',
      this.phoneNumber = '',
      this.customerId = '',
      this.managerId = '',
      this.commission = 0.0,
      this.dob,
      this.avatarImgDTO,
      this.refId = '',
      this.resetToken = '',
      this.isCreate});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  static User clone(User other) {
    final String jsonString = json.encode(other);
    final jsonResponse = json.decode(jsonString);

    return User.fromJson(jsonResponse as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          password == other.password &&
          fullName == other.fullName &&
          email == other.email &&
          avatarImg == other.avatarImg &&
          status == other.status &&
          langKey == other.langKey &&
          createdId == other.createdId &&
          createdDate == other.createdDate &&
          updatedId == other.updatedId &&
          updatedDate == other.updatedDate &&
          address == other.address &&
          phoneNumber == other.phoneNumber &&
          customerId == other.customerId &&
          managerId == other.managerId &&
          commission == other.commission &&
          dob == other.dob &&
          avatarImgDTO == other.avatarImgDTO &&
          refId == other.refId &&
          resetToken == other.resetToken;

  @override
  int get hashCode =>
      username.hashCode ^
      password.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      avatarImg.hashCode ^
      status.hashCode ^
      langKey.hashCode ^
      createdId.hashCode ^
      createdDate.hashCode ^
      updatedId.hashCode ^
      updatedDate.hashCode ^
      address.hashCode ^
      phoneNumber.hashCode ^
      customerId.hashCode ^
      managerId.hashCode ^
      commission.hashCode ^
      dob.hashCode ^
      avatarImgDTO.hashCode ^
      refId.hashCode ^
      resetToken.hashCode;

  @override
  String toString() {
    return 'User{username: $username, password: $password, fullName: $fullName, email: $email, avatarImg: $avatarImg, status: $status, langKey: $langKey, createdId: $createdId, createdDate: $createdDate, updatedId: $updatedId, updatedDate: $updatedDate, address: $address, phoneNumber: $phoneNumber, customerId: $customerId, managerId: $managerId, commission: $commission, dob: $dob}';
  }
}
