import 'package:json_annotation/json_annotation.dart';
import 'package:ntbexpress/model/vietnam_areas/location.dart';

part 'province.g.dart';

@JsonSerializable()
class Province implements Location {
  int? id;
  String? name;
  String? location;
  String? type;

  Province({this.id, this.name, this.location, this.type});

  factory Province.fromJson(Map<String, dynamic> json) =>
      _$ProvinceFromJson(json);

  Map<String, dynamic> toJson() => _$ProvinceToJson(this);
}
