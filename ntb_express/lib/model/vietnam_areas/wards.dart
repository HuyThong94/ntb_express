import 'package:json_annotation/json_annotation.dart';
import 'package:ntbexpress/model/vietnam_areas/location.dart';

part 'wards.g.dart';

@JsonSerializable()
class Wards implements Location {
  int? id;
  String? name;
  String? location;
  String? type;
  @JsonKey(name: 'huyen_id')
  int? districtId;

  Wards({this.id, this.name, this.location, this.type, this.districtId});

  factory Wards.fromJson(Map<String, dynamic> json) => _$WardsFromJson(json);

  Map<String, dynamic> toJson() => _$WardsToJson(this);
}
