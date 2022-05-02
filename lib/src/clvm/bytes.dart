// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes, prefer_constructors_over_static_methods, lines_longer_than_80_chars

import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

class Puzzlehash extends Bytes {
  Puzzlehash(List<int> bytesList) : super(bytesList) {
    if (bytesList.length != bytesLength) {
      throw ArgumentError('Puzzlehash must have 32 bytes');
    }
  }

  factory Puzzlehash.fromHex(String phHex) {
    return Puzzlehash(Bytes.fromHex(phHex));
  }

  static const bytesLength = 32;
}

class Bytes implements List<int> {
  final Uint8List _byteList;
  Bytes(List<int> bytesList) : _byteList = Uint8List.fromList(bytesList);

  static String bytesPrefix = '0x';

  String toHex() => const HexEncoder().convert(_byteList);

  Uint8List get uint8List => _byteList;

  static Bytes get empty => Bytes([]);

  factory Bytes.fromHex(String hex) {
    if (hex.startsWith(bytesPrefix)) {
      return Bytes(
        const HexDecoder().convert(hex.replaceFirst(bytesPrefix, '')),
      );
    }
    return Bytes(const HexDecoder().convert(hex));
  }

  @override
  bool operator ==(Object other) =>
      other is Bytes &&
      other.runtimeType == runtimeType &&
      other.toHex() == toHex();

  @override
  int get hashCode => toHex().hashCode;

  @override
  String toString() => toHex();

  Bytes sha256Hash() {
    return Bytes(sha256.convert(_byteList).bytes);
  }

  String get hexWithBytesPrefix {
    return bytesPrefix + toHex();
  }

  @override
  int get first {
    return _byteList.first;
  }

  @override
  set first(int value) {
    _byteList.first = value;
  }

  @override
  int get last {
    return _byteList.last;
  }

  @override
  set last(int value) {
    _byteList.last = value;
  }

  @override
  int get length {
    return _byteList.length;
  }

  @override
  set length(int value) {
    _byteList.length = value;
  }

  @override
  Bytes operator +(List<int> other) {
    return Bytes(_byteList + other);
  }

  @override
  int operator [](int index) {
    return _byteList[index];
  }

  @override
  void operator []=(int index, int value) {
    _byteList[index] = value;
  }

  @override
  void add(int value) {
    _byteList.add(value);
  }

  @override
  void addAll(Iterable<int> iterable) {
    _byteList.addAll(iterable);
  }

  @override
  bool any(bool Function(int element) test) {
    return _byteList.any(test);
  }

  @override
  Map<int, int> asMap() {
    return _byteList.asMap();
  }

  @override
  List<R> cast<R>() {
    return _byteList.cast<R>();
  }

  @override
  void clear() {
    _byteList.clear();
  }

  @override
  bool contains(Object? element) {
    return _byteList.contains(element);
  }

  @override
  int elementAt(int index) {
    return _byteList.elementAt(index);
  }

  @override
  bool every(bool Function(int element) test) {
    return _byteList.every(test);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(int element) toElements) {
    return _byteList.expand(toElements);
  }

  @override
  void fillRange(int start, int end, [int? fillValue]) {
    _byteList.fillRange(start, end, fillValue);
  }

  @override
  int firstWhere(bool Function(int element) test, {int Function()? orElse}) {
    return _byteList.firstWhere(test, orElse: orElse);
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, int element) combine) {
    return _byteList.fold(initialValue, combine);
  }

  @override
  Iterable<int> followedBy(Iterable<int> other) {
    return _byteList.followedBy(other);
  }

  @override
  void forEach(void Function(int element) action) {
    _byteList.forEach(action);
  }

  @override
  Iterable<int> getRange(int start, int end) {
    return _byteList.getRange(start, end);
  }

  @override
  int indexOf(int element, [int start = 0]) {
    return _byteList.indexOf(element, start);
  }

  @override
  int indexWhere(bool Function(int element) test, [int start = 0]) {
    return _byteList.indexWhere(test, start);
  }

  @override
  void insert(int index, int element) {
    _byteList.insert(index, element);
  }

  @override
  void insertAll(int index, Iterable<int> iterable) {
    _byteList.insertAll(index, iterable);
  }

  @override
  bool get isEmpty => _byteList.isEmpty;

  @override
  bool get isNotEmpty => _byteList.isNotEmpty;

  @override
  Iterator<int> get iterator => _byteList.iterator;

  @override
  String join([String separator = '']) {
    return _byteList.join(separator);
  }

  @override
  int lastIndexOf(int element, [int? start]) {
    return _byteList.lastIndexOf(element, start);
  }

  @override
  int lastIndexWhere(bool Function(int element) test, [int? start]) {
    return _byteList.lastIndexWhere(test, start);
  }

  @override
  int lastWhere(bool Function(int element) test, {int Function()? orElse}) {
    return _byteList.lastWhere(test, orElse: orElse);
  }

  @override
  Iterable<T> map<T>(T Function(int e) toElement) {
    return _byteList.map(toElement);
  }

  @override
  int reduce(int Function(int value, int element) combine) {
    return _byteList.reduce(combine);
  }

  @override
  bool remove(Object? value) {
    return _byteList.remove(value);
  }

  @override
  int removeAt(int index) {
    return _byteList.removeAt(index);
  }

  @override
  int removeLast() {
    return _byteList.removeLast();
  }

  @override
  void removeRange(int start, int end) {
    _byteList.removeRange(start, end);
  }

  @override
  void removeWhere(bool Function(int element) test) {
    _byteList.removeWhere(test);
  }

  @override
  void replaceRange(int start, int end, Iterable<int> replacements) {
    _byteList.replaceRange(start, end, replacements);
  }

  @override
  void retainWhere(bool Function(int element) test) {
    _byteList.retainWhere(test);
  }

  @override
  Bytes get reversed => Bytes(_byteList.reversed.toList());

  @override
  void setAll(int index, Iterable<int> iterable) {
    _byteList.setAll(index, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    _byteList.setRange(start, end, iterable);
  }

  @override
  void shuffle([Random? random]) {
    throw UnimplementedError();
  }

  @override
  int get single => _byteList.single;

  @override
  int singleWhere(bool Function(int element) test, {int Function()? orElse}) {
    return _byteList.singleWhere(test, orElse: orElse);
  }

  @override
  Bytes skip(int count) {
    return Bytes(_byteList.skip(count).toList());
  }

  @override
  Bytes skipWhile(bool Function(int value) test) {
    return Bytes(_byteList.skipWhile(test).toList());
  }

  @override
  void sort([int Function(int a, int b)? compare]) {
    throw UnimplementedError();
  }

  @override
  Bytes sublist(int start, [int? end]) {
    return Bytes(_byteList.sublist(start, end));
  }

  @override
  Bytes take(int count) {
    return Bytes(_byteList.take(count).toList());
  }

  @override
  Bytes takeWhile(bool Function(int value) test) {
    return Bytes(_byteList.takeWhile(test).toList());
  }

  @override
  List<int> toList({bool growable = true}) {
    return _byteList.toList();
  }

  @override
  Set<int> toSet() {
    throw UnimplementedError();
  }

  @override
  Bytes where(bool Function(int element) test) {
    return Bytes(_byteList.where(test).toList());
  }

  @override
  Iterable<T> whereType<T>() {
    throw UnimplementedError();
  }
}
