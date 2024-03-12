import 'package:flutter/material.dart';
import 'package:ntbexpress/model/vietnam_areas/district.dart';
import 'package:ntbexpress/model/vietnam_areas/location.dart';
import 'package:ntbexpress/model/vietnam_areas/province.dart';
import 'package:ntbexpress/model/vietnam_areas/wards.dart';
import 'package:ntbexpress/util/utils.dart';

enum AreaTarget { province, district, wards }

class SelectAreaScreen extends StatefulWidget {
  final AreaTarget target;
  final String? currentProvince;
  final String? currentDistrict;
  final String? currentWards;
  final String title;

  SelectAreaScreen(
      {required this.target,
      this.currentProvince,
      this.currentDistrict,
      this.currentWards,
      required this.title})
      : assert(target != null),
        assert(title != null);

  @override
  _SelectAreaScreenState createState() => _SelectAreaScreenState();
}

class _SelectAreaScreenState extends State<SelectAreaScreen> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    switch (widget.target) {
      case AreaTarget.province:
        _currentValue = widget.currentProvince!;
        break;
      case AreaTarget.district:
        _currentValue = widget.currentDistrict!;
        break;
      case AreaTarget.wards:
        _currentValue = widget.currentWards!;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_currentValue),
          icon: Icon(Icons.arrow_back),
        ),
        title: Text(widget.title),
      ),
      body: Container(
        child: _content(),
      ),
    );
  }

  Widget _content() {
    Widget result = SizedBox();
    switch (widget.target) {
      case AreaTarget.province:
        result = _province();
        break;
      case AreaTarget.district:
        result = _district();
        break;
      case AreaTarget.wards:
        result = _wardsList();
        break;
    }

    return result;
  }

  Widget _province() {
    return _location(Utils.getProvinceList());
  }

  Future<Future<List<District>>?> _getDistrictList() async {
    List<Province> provinceList = await Utils.getProvinceList();
    if (provinceList != null && provinceList.isNotEmpty) {
      int provinceId = provinceList
              .firstWhere((province) =>
                  province.name!.toLowerCase() ==
                  widget.currentProvince!.toLowerCase())
              ?.id ??
          0;

      return provinceId == 0
          ? null
          : Utils.getDistrictList(provinceId: provinceId);
    }

    return null;
  }

  Widget _district() {
    return _location(_getDistrictList() as Future<List<Location>>);
  }

  Future<Future<List<Wards>>?> _getWardsList() async {
    List<District> districtList = (await _getDistrictList()) as List<District>;
    if (districtList != null && districtList.isNotEmpty) {
      int districtId = districtList
              .firstWhere((district) =>
                  district.name!.toLowerCase() ==
                  widget.currentDistrict!.toLowerCase())
              ?.id ??
          0;

      return districtId == 0
          ? null
          : Utils.getWardsList(districtId: districtId);
    }

    return null;
  }

  Widget _wardsList() {
    return _location(_getWardsList() as Future<List<Location>>);
  }

  Widget _location(Future<List<Location>> targetMethod) {
    return FutureBuilder<List<Location>>(
      future: targetMethod,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              '${Utils.getLocale(context).empty}',
              style: TextStyle(color: Theme.of(context).disabledColor),
            ));
          }

          return ListView.separated(
              itemBuilder: (context, index) => ListTile(
                    onTap: () {
                      if (mounted) {
                        setState(
                            () => _currentValue = snapshot.data![index].name!);
                        Navigator.of(context).pop(_currentValue);
                      }
                    },
                    leading: Text(snapshot.data![index].name!),
                    trailing: snapshot.data![index].name!.toLowerCase() ==
                            _currentValue?.toLowerCase()
                        ? Icon(
                            Icons.done,
                            color: Utils.accentColor,
                          )
                        : SizedBox(),
                  ),
              separatorBuilder: (context, index) => Divider(height: 0.5),
              itemCount: snapshot.data!.length);
        }

        return SizedBox();
      },
    );
  }
}
