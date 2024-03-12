import 'package:json_annotation/json_annotation.dart';

part 'tcco_file.g.dart';

@JsonSerializable()
class TCCOFile {
  String? atchFleSeq;
  String? fleTP;
  String? flePath;
  String? fleNm;
  String? newFleNm;
  String? fleSz;
  String? descrpt;
  String? insId;
  num? insDt;
  num? uptDt;
  String? fleUri;

  TCCOFile(
      {this.atchFleSeq,
      this.fleTP,
      this.flePath,
      this.fleNm,
      this.newFleNm,
      this.fleSz,
      this.descrpt,
      this.insId,
      this.insDt,
      this.uptDt,
      this.fleUri});

  factory TCCOFile.fromJson(Map<String, dynamic> json) => _$TCCOFileFromJson(json);

  Map<String, dynamic> toJson() => _$TCCOFileToJson(this);
}
