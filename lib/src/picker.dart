import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

const _nameChildren = 'children';

const _nameCode = 'code';

const _nameName = 'name';

/// The result object returned by Navigator
class CityResult {
  final String code;
  final String province;
  final String? city;
  final String? county;

  const CityResult({
    required this.code,
    required this.province,
    this.city,
    this.county,
  });

  @override
  String toString() =>
      '$province${city == null ? '' : ',$city'}${county == null ? '' : ',$county'}';
}

/// The picker widget
///
/// Normally put it in a dialog or bottomsheet
class CityPicker extends StatefulWidget {
  /// Default constructor
  ///
  /// All column index will be 0
  const CityPicker({Key? key})
      : code = null,
        province = null,
        city = null,
        county = null,
        super(key: key);

  /// Construct the picker by name provided
  ///
  /// The picker column index will stop at the name provided
  /// If any property is null or not found in dataset, the index after will be 0
  const CityPicker.fromName({Key? key, this.province, this.city, this.county})
      : code = null,
        super(key: key);

  /// Construct the pick by code provided
  ///
  /// The picker column index will stop at the code provided
  /// if code is not in dataset, all column index will be 0
  const CityPicker.fromCode({Key? key, this.code})
      : province = null,
        city = null,
        county = null,
        super(key: key);

  /// the city code, e.g. 110111
  final String? code;

  /// the province name, e.g. 北京市
  final String? province;

  /// the city name, e.g. 北京市
  final String? city;

  /// the county name, e.g. 房山区
  final String? county;

  /// data set from baidu 202104
  /// rootBundle.loadStructuredData will cache the result so no worries
  static Future<List<dynamic>> loadAssets() => rootBundle.loadStructuredData(
      'packages/city_picker_china/assets/data_202104.json',
      (str) async => jsonDecode(str));

  /// Search city infomation by code
  ///
  /// If code is null or not in dataset, null is returned
  static Future<CityResult?> searchWithCode(
    String? code, {
    List<dynamic>? dataSet,
  }) async {
    if (code == null || code.isEmpty) {
      return null;
    }

    final provinces = dataSet ?? await loadAssets();

    for (final province in provinces) {
      if (province[_nameCode] == code) {
        return CityResult(code: code, province: province[_nameName]);
      }
      for (final city in province[_nameChildren]) {
        if (city[_nameCode] == code) {
          return CityResult(
              code: code, province: province[_nameName], city: city[_nameName]);
        }

        for (final county in city[_nameChildren]) {
          if (county[_nameCode] == code) {
            return CityResult(
                code: code,
                province: province[_nameName],
                city: city[_nameName],
                county: county[_nameName]);
          }
        }
      }
    }
    return null;
  }

  /// Search city infomation by names
  ///
  /// If [province] is null or not in dataset, null is returned
  /// If any other name is null or not in dataset, the corresponding will be null
  static Future<CityResult?> searchWithName({
    String? province,
    String? city,
    String? county,
    List<dynamic>? dataSet,
  }) async {
    if (province == null || province.isEmpty) {
      return null;
    }

    final provinces = dataSet ?? await loadAssets();

    final provinceInfo =
        provinces.firstWhereOrNull((element) => element[_nameName] == province);

    if (provinceInfo == null) {
      return null;
    }

    final cityInfo = (city == null || city.isEmpty)
        ? null
        : (provinceInfo[_nameChildren] as List<dynamic>)
            .firstWhereOrNull((element) => element[_nameName] == city);

    if (cityInfo == null) {
      return CityResult(code: provinceInfo[_nameCode], province: province);
    }

    final countyInfo = (county == null || county.isEmpty)
        ? null
        : (cityInfo[_nameChildren] as List<dynamic>)
            .firstWhereOrNull((element) => element[_nameName] == county);

    if (countyInfo == null) {
      return CityResult(
          code: cityInfo[_nameCode], province: province, city: city);
    }

    return CityResult(
        code: countyInfo[_nameCode],
        province: province,
        city: city,
        county: county);
  }

  @override
  _CityPickerState createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  List<dynamic>? _data;

  List<String>? _provinces;
  List<String>? _cities;
  List<String>? _counties;

  final _provinceController = FixedExtentScrollController();
  final _cityController = FixedExtentScrollController();
  final _countyController = FixedExtentScrollController();

  @override
  void initState() {
    super.initState();
    () async {
      _data = await CityPicker.loadAssets();

      final result = widget.code != null
          ? await CityPicker.searchWithCode(widget.code!, dataSet: _data)
          : await CityPicker.searchWithName(
              province: widget.province,
              city: widget.city,
              county: widget.county,
              dataSet: _data);

      int indexProvince = 0;
      int indexCity = 0;
      int indexCounty = 0;

      _provinces = _data!.mapIndexed<String>((index, element) {
        final name = element[_nameName];
        if (name == result?.province) {
          indexProvince = index;
        }
        return name;
      }).toList();

      final dataCities = _data![indexProvince][_nameChildren] as List<dynamic>;
      _cities = dataCities.mapIndexed<String>((index, element) {
        final name = element[_nameName];
        if (name == result?.city) {
          indexCity = index;
        }
        return name;
      }).toList();

      final dataCounties = _data![indexProvince][_nameChildren][indexCity]
          [_nameChildren] as List<dynamic>;
      _counties = dataCounties.mapIndexed<String>((index, element) {
        final name = element[_nameName];
        if (name == result?.county) {
          indexCounty = index;
        }
        return name;
      }).toList();

      setState(() {});

      SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
        _provinceController.jumpToItem(indexProvince);
        _cityController.jumpToItem(indexCity);
        _countyController.jumpToItem(indexCounty);
      });
    }();
  }

  @override
  void dispose() {
    super.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _countyController.dispose();
  }

  void _updateCities() {
    final list = _data![_provinceController.selectedItem][_nameChildren]
        as List<dynamic>;
    _cities = list.map<String>((e) => e[_nameName]).toList();
  }

  void _updateCounties() {
    final list = _data![_provinceController.selectedItem][_nameChildren]
        [_cityController.selectedItem][_nameChildren] as List<dynamic>;
    _counties = list.map<String>((e) => e[_nameName]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            CupertinoButton(
              onPressed: () {
                CityResult? result;
                if (_data == null) {
                  result = null;
                } else {
                  final indexProvince = _provinceController.selectedItem;
                  final indexCity = _cityController.selectedItem;
                  final indexCounty = _countyController.selectedItem;

                  result = CityResult(
                    code: _data![indexProvince][_nameChildren][indexCity]
                        [_nameChildren][indexCounty][_nameCode],
                    province: _provinces![indexProvince],
                    city: _cities![indexCity],
                    county: _counties![indexCounty],
                  );
                }
                Navigator.pop(context, result);
              },
              child: const Text('确定'),
            ),
          ],
        ),
        Expanded(
          child: Row(
            children: [
              _Picker(
                controller: _provinceController,
                data: _provinces ?? [],
                onSelectedItemChanged: () {
                  _cityController.jumpTo(0);
                  _countyController.jumpTo(0);
                  setState(() {
                    _updateCities();
                    _updateCounties();
                  });
                },
              ),
              _Picker(
                controller: _cityController,
                data: _cities ?? [],
                onSelectedItemChanged: () {
                  _countyController.jumpTo(0);
                  setState(() {
                    _updateCounties();
                  });
                },
              ),
              _Picker(
                controller: _countyController,
                data: _counties ?? [],
                onSelectedItemChanged: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    Key? key,
    required this.data,
    required this.onSelectedItemChanged,
    required this.controller,
  }) : super(key: key);

  final List<String> data;
  final VoidCallback onSelectedItemChanged;
  final FixedExtentScrollController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker.builder(
        itemExtent: 40,
        scrollController: controller,
        onSelectedItemChanged: (_) => onSelectedItemChanged(),
        itemBuilder: (_, index) => Center(
          child: FittedBox(
            child: Text(data[index], style: const TextStyle(fontSize: 14)),
          ),
        ),
        childCount: data.length,
      ),
    );
  }
}
