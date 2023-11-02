import 'package:chia_crypto_utils/chia_crypto_utils.dart';

mixin MixedTypeMixin<T, V> {
  Map<GeneralCoinType, Map<Puzzlehash?, T>> get map;
  T get defaultValue;

  T get standard => map[GeneralCoinType.standard]?[null] ?? defaultValue;

  T add(T first, T second);
  T subtract(T first, T second);

  /// prototype pattern
  V clone(Map<GeneralCoinType, Map<Puzzlehash?, T>> map);
  Map<Puzzlehash, T> get cat =>
      map[GeneralCoinType.cat]?.map((key, value) => MapEntry(key!, value)) ??
      {};
  Map<Puzzlehash, T> get nft =>
      map[GeneralCoinType.nft]?.map((key, value) => MapEntry(key!, value)) ??
      {};

  Map<Puzzlehash?, T> toGeneralizedMap() {
    final generalizedMap = <Puzzlehash?, T>{};
    for (final assetMap in map.values) {
      generalizedMap.addAll(assetMap);
    }
    return generalizedMap;
  }

  V operator +(V other_) {
    return _operate(other_, add);
  }

  V operator -(V other_) {
    return _operate(other_, subtract);
  }

  V _operate(V other_, T Function(T first, T second) operator) {
    final other = other_ as MixedTypeMixin<T, V>;
    final newMap = <GeneralCoinType, Map<Puzzlehash?, T>>{};
    for (final type in {...map.keys, ...other.map.keys}) {
      for (final assetId in {
        ...map[type]?.keys ?? <Puzzlehash>[],
        ...other.map[type]?.keys ?? <Puzzlehash>[],
      }) {
        if (!newMap.containsKey(type)) {
          newMap[type] = {};
        }

        newMap[type]![assetId] = operator(
          map[type]?[assetId] ?? defaultValue,
          other.map[type]?[assetId] ?? defaultValue,
        );
      }
    }

    return clone(newMap);
  }
}

enum GeneralCoinType {
  standard,
  nft,
  cat,
}

abstract class MatrixElement {
  dynamic operator +(dynamic other);
}
