## Flutter 中国城市地区选择器

数据源： [百度地图行政区划adcode映射表 【更新至21年04月】](https://mapopen-pub-webserviceapi.bj.bcebos.com/geocoding/Township_Area_A_202104.xlsx)

比起国家统计局的数据优点在于

- 数据比较新
- 一定存在第三级地区
- 有港澳台数据

## 使用实例

```dart

void showCityPicker() {

  /// basic
  showModalBottomSheet<CityResult>(context: context, builder: (_) => const CityPicker());

  /// with code
  showModalBottomSheet<CityResult>(context: context, builder: (_) => const CityPicker.fromCode(code: code));

  /// with city name
  showModalBottomSheet<CityResult>(
      context: context, builder: (_) => const CityPicker.formName(province: province, city: city, county: county));
}

```