// PublicOS QR Code Generator
//
// Zero-dependency QR code matrix generator + customizable Flutter widget.
// Inlined from the `qr` package (MIT, github.com/kevmoo/qr.dart) to eliminate
// supply chain risk. Only dart:core, dart:typed_data, dart:collection, dart:math,
// dart:convert, and Flutter's painting/widgets are used.
//
// Usage:
//   // Just the matrix (no Flutter dependency):
//   final matrix = QrMatrix.fromData('https://publicos.dev/u/0x...');
//   matrix.moduleCount; // e.g. 29
//   matrix.isDark(row, col); // true/false
//
//   // Flutter widget:
//   PublicOSQr(data: 'publicos://pay/0x...?amount=10')

import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

// ============================================================================
// QR MATRIX GENERATOR (pure Dart, no Flutter)
// ============================================================================

// ---- Error correction levels ----

class QrErrorCorrection {
  static const int low = 1;
  static const int medium = 0;
  static const int quartile = 3;
  static const int high = 2;

  static const List<int> levels = [low, medium, quartile, high];
}

// ---- Encoding modes ----

const int _modeNumber = 1 << 0;
const int _modeAlphaNum = 1 << 1;
const int _mode8bitByte = 1 << 2;
const int _modeKanji = 1 << 3;

// ---- Bit buffer ----

class _BitBuffer extends Object with ListMixin<bool> {
  final List<int> _buffer = <int>[];
  int _length = 0;

  @override
  void operator []=(int index, bool value) =>
      throw UnsupportedError('cannot change');

  @override
  bool operator [](int index) {
    final bufIndex = index ~/ 8;
    return ((_buffer[bufIndex] >> (7 - index % 8)) & 1) == 1;
  }

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('Cannot change');

  int getByte(int index) => _buffer[index];

  void put(int number, int length) {
    for (var i = 0; i < length; i++) {
      final bit = ((number >> (length - i - 1)) & 1) == 1;
      putBit(bit);
    }
  }

  void putBit(bool bit) {
    final bufIndex = _length ~/ 8;
    if (_buffer.length <= bufIndex) {
      _buffer.add(0);
    }
    if (bit) {
      _buffer[bufIndex] |= 0x80 >> (_length % 8);
    }
    _length++;
  }
}

// ---- Data encoding ----

abstract class _QrDatum {
  int get mode;
  int get length;
  void write(_BitBuffer buffer);
}

class _QrByte implements _QrDatum {
  @override
  final int mode = _mode8bitByte;
  final Uint8List _data;

  factory _QrByte(String input) =>
      _QrByte.fromUint8List(utf8.encoder.convert(input));

  _QrByte.fromUint8List(Uint8List input) : _data = input;

  @override
  int get length => _data.length;

  @override
  void write(_BitBuffer buffer) {
    for (final v in _data) {
      buffer.put(v, 8);
    }
  }
}

// ---- GF(256) math ----

final Uint8List _expTable = _createExpTable();
final Uint8List _logTable = _createLogTable();

int _glog(int n) => (n >= 1) ? _logTable[n] : throw ArgumentError('glog($n)');
int _gexp(int n) => _expTable[n % 255];

Uint8List _createExpTable() {
  final list = Uint8List(256);
  for (var i = 0; i < 8; i++) {
    list[i] = 1 << i;
  }
  for (var i = 8; i < 256; i++) {
    list[i] = list[i - 4] ^ list[i - 5] ^ list[i - 6] ^ list[i - 8];
  }
  return list;
}

Uint8List _createLogTable() {
  final list = Uint8List(256);
  for (var i = 0; i < 255; i++) {
    list[_expTable[i]] = i;
  }
  return list;
}

// ---- Polynomial ----

class _Polynomial {
  final Uint8List _values;

  factory _Polynomial(List<int> thing, int shift) {
    var offset = 0;
    while (offset < thing.length && thing[offset] == 0) {
      offset++;
    }
    final values = Uint8List(thing.length - offset + shift);
    for (var i = 0; i < thing.length - offset; i++) {
      values[i] = thing[i + offset];
    }
    return _Polynomial._internal(values);
  }

  _Polynomial._internal(this._values);

  int operator [](int index) => _values[index];
  int get length => _values.length;

  _Polynomial multiply(_Polynomial e) {
    final List<int> foo = Uint8List(length + e.length - 1);
    for (var i = 0; i < length; i++) {
      for (var j = 0; j < e.length; j++) {
        foo[i + j] ^= _gexp(_glog(this[i]) + _glog(e[j]));
      }
    }
    return _Polynomial(foo, 0);
  }

  _Polynomial mod(_Polynomial e) {
    if (length - e.length < 0) return this;
    final ratio = _glog(this[0]) - _glog(e[0]);
    final value = Uint8List(length);
    for (var i = 0; i < length; i++) {
      value[i] = this[i];
    }
    for (var i = 0; i < e.length; i++) {
      value[i] ^= _gexp(_glog(e[i]) + ratio);
    }
    return _Polynomial(value, 0).mod(e);
  }
}

// ---- Reed-Solomon blocks ----

class _RsBlock {
  final int totalCount;
  final int dataCount;
  _RsBlock(this.totalCount, this.dataCount);

  static List<_RsBlock> getRSBlocks(int typeNumber, int errorCorrectLevel) {
    final rsBlock = _getRsBlockTable(typeNumber, errorCorrectLevel);
    final length = rsBlock.length ~/ 3;
    final list = <_RsBlock>[];
    for (var i = 0; i < length; i++) {
      final count = rsBlock[i * 3 + 0];
      final totalCount = rsBlock[i * 3 + 1];
      final dataCount = rsBlock[i * 3 + 2];
      for (var j = 0; j < count; j++) {
        list.add(_RsBlock(totalCount, dataCount));
      }
    }
    return list;
  }
}

List<int> _getRsBlockTable(int typeNumber, int errorCorrectLevel) =>
    switch (errorCorrectLevel) {
      QrErrorCorrection.low => _rsBlockTable[(typeNumber - 1) * 4 + 0],
      QrErrorCorrection.medium => _rsBlockTable[(typeNumber - 1) * 4 + 1],
      QrErrorCorrection.quartile => _rsBlockTable[(typeNumber - 1) * 4 + 2],
      QrErrorCorrection.high => _rsBlockTable[(typeNumber - 1) * 4 + 3],
      _ => throw ArgumentError(
          'bad rs block @ typeNumber: $typeNumber/errorCorrectLevel:$errorCorrectLevel',
        )
    };

// ---- Mask patterns ----

bool _mask(int maskPattern, int i, int j) => switch (maskPattern) {
      0 => (i + j).isEven,
      1 => i.isEven,
      2 => j % 3 == 0,
      3 => (i + j) % 3 == 0,
      4 => ((i ~/ 2) + (j ~/ 3)).isEven,
      5 => (i * j) % 2 + (i * j) % 3 == 0,
      6 => ((i * j) % 2 + (i * j) % 3).isEven,
      7 => ((i * j) % 3 + (i + j) % 2).isEven,
      _ => throw ArgumentError('bad maskPattern:$maskPattern')
    };

// ---- Utility functions ----

const List<List<int>> _patternPositionTable = [
  [],
  [6, 18],
  [6, 22],
  [6, 26],
  [6, 30],
  [6, 34],
  [6, 22, 38],
  [6, 24, 42],
  [6, 26, 46],
  [6, 28, 50],
  [6, 30, 54],
  [6, 32, 58],
  [6, 34, 62],
  [6, 26, 46, 66],
  [6, 26, 48, 70],
  [6, 26, 50, 74],
  [6, 30, 54, 78],
  [6, 30, 56, 82],
  [6, 30, 58, 86],
  [6, 34, 62, 90],
  [6, 28, 50, 72, 94],
  [6, 26, 50, 74, 98],
  [6, 30, 54, 78, 102],
  [6, 28, 54, 80, 106],
  [6, 32, 58, 84, 110],
  [6, 30, 58, 86, 114],
  [6, 34, 62, 90, 118],
  [6, 26, 50, 74, 98, 122],
  [6, 30, 54, 78, 102, 126],
  [6, 26, 52, 78, 104, 130],
  [6, 30, 56, 82, 108, 134],
  [6, 34, 60, 86, 112, 138],
  [6, 30, 58, 86, 114, 142],
  [6, 34, 62, 90, 118, 146],
  [6, 30, 54, 78, 102, 126, 150],
  [6, 24, 50, 76, 102, 128, 154],
  [6, 28, 54, 80, 106, 132, 158],
  [6, 32, 58, 84, 110, 136, 162],
  [6, 26, 54, 82, 110, 138, 166],
  [6, 30, 58, 86, 114, 142, 170],
];

const int _g15 =
    (1 << 10) | (1 << 8) | (1 << 5) | (1 << 4) | (1 << 2) | (1 << 1) | (1 << 0);
const int _g18 = (1 << 12) |
    (1 << 11) |
    (1 << 10) |
    (1 << 9) |
    (1 << 8) |
    (1 << 5) |
    (1 << 2) |
    (1 << 0);
const _g15Mask = (1 << 14) | (1 << 12) | (1 << 10) | (1 << 4) | (1 << 1);

int _bchTypeInfo(int data) {
  var d = data << 10;
  while (_bchDigit(d) - _bchDigit(_g15) >= 0) {
    d ^= _g15 << (_bchDigit(d) - _bchDigit(_g15));
  }
  return ((data << 10) | d) ^ _g15Mask;
}

int _bchTypeNumber(int data) {
  var d = data << 12;
  while (_bchDigit(d) - _bchDigit(_g18) >= 0) {
    d ^= _g18 << (_bchDigit(d) - _bchDigit(_g18));
  }
  return (data << 12) | d;
}

int _bchDigit(int data) {
  var digit = 0;
  while (data != 0) {
    digit++;
    data >>= 1;
  }
  return digit;
}

List<int> _patternPosition(int typeNumber) =>
    _patternPositionTable[typeNumber - 1];

// ---- QR code encoder ----

class _QrCode {
  final int typeNumber;
  final int errorCorrectLevel;
  final int moduleCount;
  List<int>? _dataCache;
  final _dataList = <_QrDatum>[];

  _QrCode(this.typeNumber, this.errorCorrectLevel)
      : moduleCount = typeNumber * 4 + 17 {
    RangeError.checkValueInInterval(typeNumber, 1, 40, 'typeNumber');
  }

  factory _QrCode.fromData({
    required String data,
    required int errorCorrectLevel,
  }) {
    final typeNumber = _calculateTypeNumberFromData(
      errorCorrectLevel,
      [_QrByte(data)],
    );
    return _QrCode(typeNumber, errorCorrectLevel)..addData(data);
  }

  static int _calculateTypeNumberFromData(
    int errorCorrectLevel,
    List<_QrDatum> dataList,
  ) {
    int typeNumber;
    for (typeNumber = 1; typeNumber < 40; typeNumber++) {
      final rsBlocks = _RsBlock.getRSBlocks(typeNumber, errorCorrectLevel);
      final buffer = _BitBuffer();
      var totalDataCount = 0;
      for (var i = 0; i < rsBlocks.length; i++) {
        totalDataCount += rsBlocks[i].dataCount;
      }
      for (var i = 0; i < dataList.length; i++) {
        final data = dataList[i];
        buffer
          ..put(data.mode, 4)
          ..put(data.length, _lengthInBits(data.mode, typeNumber));
        data.write(buffer);
      }
      if (buffer.length <= totalDataCount * 8) break;
    }
    return typeNumber;
  }

  void addData(String data) {
    _dataList.add(_QrByte(data));
    _dataCache = null;
  }

  List<int> get dataCache =>
      _dataCache ??= _createData(typeNumber, errorCorrectLevel, _dataList);
}

const int _pad0 = 0xEC;
const int _pad1 = 0x11;

List<int> _createData(
  int typeNumber,
  int errorCorrectLevel,
  List<_QrDatum> dataList,
) {
  final rsBlocks = _RsBlock.getRSBlocks(typeNumber, errorCorrectLevel);
  final buffer = _BitBuffer();

  for (var i = 0; i < dataList.length; i++) {
    final data = dataList[i];
    buffer
      ..put(data.mode, 4)
      ..put(data.length, _lengthInBits(data.mode, typeNumber));
    data.write(buffer);
  }

  var totalDataCount = 0;
  for (var i = 0; i < rsBlocks.length; i++) {
    totalDataCount += rsBlocks[i].dataCount;
  }

  final totalByteCount = totalDataCount * 8;
  if (buffer.length > totalByteCount) {
    throw StateError(
        'Input too long: ${buffer.length} > $totalByteCount bits');
  }

  if (buffer.length + 4 <= totalByteCount) {
    buffer.put(0, 4);
  }

  while (buffer.length % 8 != 0) {
    buffer.putBit(false);
  }

  final bitDataCount = totalDataCount * 8;
  var count = 0;
  for (;;) {
    if (buffer.length >= bitDataCount) break;
    buffer.put((count++).isEven ? _pad0 : _pad1, 8);
  }

  return _createBytes(buffer, rsBlocks);
}

List<int> _createBytes(_BitBuffer buffer, List<_RsBlock> rsBlocks) {
  var offset = 0;
  var maxDcCount = 0;
  var maxEcCount = 0;

  final dcData = List<List<int>?>.filled(rsBlocks.length, null);
  final ecData = List<List<int>?>.filled(rsBlocks.length, null);

  for (var r = 0; r < rsBlocks.length; r++) {
    final dcCount = rsBlocks[r].dataCount;
    final ecCount = rsBlocks[r].totalCount - dcCount;

    maxDcCount = math.max(maxDcCount, dcCount);
    maxEcCount = math.max(maxEcCount, ecCount);

    final dcItem = dcData[r] = Uint8List(dcCount);
    for (var i = 0; i < dcItem.length; i++) {
      dcItem[i] = 0xff & buffer.getByte(i + offset);
    }
    offset += dcCount;

    final rsPoly = _errorCorrectPolynomial(ecCount);
    final rawPoly = _Polynomial(dcItem, rsPoly.length - 1);
    final modPoly = rawPoly.mod(rsPoly);
    final ecItem = ecData[r] = Uint8List(rsPoly.length - 1);

    for (var i = 0; i < ecItem.length; i++) {
      final modIndex = i + modPoly.length - ecItem.length;
      ecItem[i] = (modIndex >= 0) ? modPoly[modIndex] : 0;
    }
  }

  final data = <int>[];
  for (var i = 0; i < maxDcCount; i++) {
    for (var r = 0; r < rsBlocks.length; r++) {
      if (i < dcData[r]!.length) {
        data.add(dcData[r]![i]);
      }
    }
  }
  for (var i = 0; i < maxEcCount; i++) {
    for (var r = 0; r < rsBlocks.length; r++) {
      if (i < ecData[r]!.length) {
        data.add(ecData[r]![i]);
      }
    }
  }
  return data;
}

int _lengthInBits(int mode, int type) {
  if (1 <= type && type < 10) {
    return switch (mode) {
      _modeNumber => 10,
      _modeAlphaNum => 9,
      _mode8bitByte => 8,
      _modeKanji => 8,
      _ => throw ArgumentError('mode:$mode')
    };
  } else if (type < 27) {
    return switch (mode) {
      _modeNumber => 12,
      _modeAlphaNum => 11,
      _mode8bitByte => 16,
      _modeKanji => 10,
      _ => throw ArgumentError('mode:$mode')
    };
  } else if (type < 41) {
    return switch (mode) {
      _modeNumber => 14,
      _modeAlphaNum => 13,
      _mode8bitByte => 16,
      _modeKanji => 12,
      _ => throw ArgumentError('mode:$mode')
    };
  } else {
    throw ArgumentError('type:$type');
  }
}

_Polynomial _errorCorrectPolynomial(int errorCorrectLength) {
  var a = _Polynomial([1], 0);
  for (var i = 0; i < errorCorrectLength; i++) {
    a = a.multiply(_Polynomial([1, _gexp(i)], 0));
  }
  return a;
}

// ============================================================================
// QR MATRIX — the public API for the raw grid
// ============================================================================

/// A computed QR code matrix. Each cell is either dark (true) or light (false).
///
/// ```dart
/// final matrix = QrMatrix.fromData('https://publicos.dev');
/// for (var row = 0; row < matrix.moduleCount; row++) {
///   for (var col = 0; col < matrix.moduleCount; col++) {
///     print(matrix.isDark(row, col) ? '##' : '  ');
///   }
/// }
/// ```
class QrMatrix {
  final int moduleCount;
  final List<List<bool?>> _modules;

  QrMatrix._(this.moduleCount, this._modules);

  /// Generate a QR matrix from a string.
  ///
  /// [errorCorrection] defaults to [QrErrorCorrection.medium].
  factory QrMatrix.fromData(
    String data, {
    int errorCorrection = QrErrorCorrection.medium,
  }) {
    final qrCode = _QrCode.fromData(
      data: data,
      errorCorrectLevel: errorCorrection,
    );

    // Try all 8 mask patterns, pick the one with the lowest penalty score.
    var minLostPoint = 0.0;
    QrMatrix? best;

    for (var mask = 0; mask < 8; mask++) {
      final test = QrMatrix._build(qrCode, mask);
      final lostPoint = _lostPoint(test);
      if (mask == 0 || minLostPoint > lostPoint) {
        minLostPoint = lostPoint;
        best = test;
      }
    }

    return best!;
  }

  factory QrMatrix._build(_QrCode qrCode, int maskPattern) {
    final moduleCount = qrCode.moduleCount;
    final modules = <List<bool?>>[];
    for (var row = 0; row < moduleCount; row++) {
      modules.add(List<bool?>.filled(moduleCount, null));
    }

    final matrix = QrMatrix._(moduleCount, modules);
    matrix._makeImpl(qrCode, maskPattern, false);
    return matrix;
  }

  /// Returns true if the module at [row], [col] is dark.
  bool isDark(int row, int col) {
    if (row < 0 || moduleCount <= row || col < 0 || moduleCount <= col) {
      throw ArgumentError('$row , $col');
    }
    return _modules[row][col]!;
  }

  /// Returns true if [row], [col] is part of one of the three finder patterns
  /// (the big squares in the corners).
  bool isFinderPattern(int row, int col) {
    const limit = 7;
    final isTopLeft = row < limit && col < limit;
    final isTopRight = row < limit && col >= moduleCount - limit;
    final isBottomLeft = row >= moduleCount - limit && col < limit;
    return isTopLeft || isTopRight || isBottomLeft;
  }

  void _makeImpl(_QrCode qrCode, int maskPattern, bool test) {
    _setupPositionProbePattern(0, 0);
    _setupPositionProbePattern(moduleCount - 7, 0);
    _setupPositionProbePattern(0, moduleCount - 7);
    _setupPositionAdjustPattern(qrCode.typeNumber);
    _setupTimingPattern();
    _setupTypeInfo(maskPattern, qrCode.errorCorrectLevel, test);
    if (qrCode.typeNumber >= 7) {
      _setupTypeNumber(qrCode.typeNumber, test);
    }
    _mapData(qrCode.dataCache, maskPattern);
  }

  void _setupPositionProbePattern(int row, int col) {
    for (var r = -1; r <= 7; r++) {
      if (row + r <= -1 || moduleCount <= row + r) continue;
      for (var c = -1; c <= 7; c++) {
        if (col + c <= -1 || moduleCount <= col + c) continue;
        if ((0 <= r && r <= 6 && (c == 0 || c == 6)) ||
            (0 <= c && c <= 6 && (r == 0 || r == 6)) ||
            (2 <= r && r <= 4 && 2 <= c && c <= 4)) {
          _modules[row + r][col + c] = true;
        } else {
          _modules[row + r][col + c] = false;
        }
      }
    }
  }

  void _setupPositionAdjustPattern(int typeNumber) {
    final pos = _patternPosition(typeNumber);
    for (var i = 0; i < pos.length; i++) {
      for (var j = 0; j < pos.length; j++) {
        final row = pos[i];
        final col = pos[j];
        if (_modules[row][col] != null) continue;
        for (var r = -2; r <= 2; r++) {
          for (var c = -2; c <= 2; c++) {
            if (r == -2 || r == 2 || c == -2 || c == 2 || (r == 0 && c == 0)) {
              _modules[row + r][col + c] = true;
            } else {
              _modules[row + r][col + c] = false;
            }
          }
        }
      }
    }
  }

  void _setupTimingPattern() {
    for (var r = 8; r < moduleCount - 8; r++) {
      if (_modules[r][6] != null) continue;
      _modules[r][6] = r.isEven;
    }
    for (var c = 8; c < moduleCount - 8; c++) {
      if (_modules[6][c] != null) continue;
      _modules[6][c] = c.isEven;
    }
  }

  void _setupTypeInfo(int maskPattern, int errorCorrectLevel, bool test) {
    final data = (errorCorrectLevel << 3) | maskPattern;
    final bits = _bchTypeInfo(data);

    for (var i = 0; i < 15; i++) {
      final mod = !test && ((bits >> i) & 1) == 1;
      if (i < 6) {
        _modules[i][8] = mod;
      } else if (i < 8) {
        _modules[i + 1][8] = mod;
      } else {
        _modules[moduleCount - 15 + i][8] = mod;
      }
    }

    for (var i = 0; i < 15; i++) {
      final mod = !test && ((bits >> i) & 1) == 1;
      if (i < 8) {
        _modules[8][moduleCount - i - 1] = mod;
      } else if (i < 9) {
        _modules[8][15 - i - 1 + 1] = mod;
      } else {
        _modules[8][15 - i - 1] = mod;
      }
    }

    _modules[moduleCount - 8][8] = !test;
  }

  void _setupTypeNumber(int typeNumber, bool test) {
    final bits = _bchTypeNumber(typeNumber);
    for (var i = 0; i < 18; i++) {
      final mod = !test && ((bits >> i) & 1) == 1;
      _modules[i ~/ 3][i % 3 + moduleCount - 8 - 3] = mod;
    }
    for (var i = 0; i < 18; i++) {
      final mod = !test && ((bits >> i) & 1) == 1;
      _modules[i % 3 + moduleCount - 8 - 3][i ~/ 3] = mod;
    }
  }

  void _mapData(List<int> data, int maskPattern) {
    var inc = -1;
    var row = moduleCount - 1;
    var bitIndex = 7;
    var byteIndex = 0;

    for (var col = moduleCount - 1; col > 0; col -= 2) {
      if (col == 6) col--;
      for (;;) {
        for (var c = 0; c < 2; c++) {
          if (_modules[row][col - c] == null) {
            var dark = false;
            if (byteIndex < data.length) {
              dark = ((data[byteIndex] >> bitIndex) & 1) == 1;
            }
            if (_mask(maskPattern, row, col - c)) {
              dark = !dark;
            }
            _modules[row][col - c] = dark;
            bitIndex--;
            if (bitIndex == -1) {
              byteIndex++;
              bitIndex = 7;
            }
          }
        }
        row += inc;
        if (row < 0 || moduleCount <= row) {
          row -= inc;
          inc = -inc;
          break;
        }
      }
    }
  }
}

double _lostPoint(QrMatrix qr) {
  final moduleCount = qr.moduleCount;
  var lostPoint = 0.0;
  int row, col;

  // LEVEL1
  for (row = 0; row < moduleCount; row++) {
    for (col = 0; col < moduleCount; col++) {
      var sameCount = 0;
      final dark = qr.isDark(row, col);
      for (var r = -1; r <= 1; r++) {
        if (row + r < 0 || moduleCount <= row + r) continue;
        for (var c = -1; c <= 1; c++) {
          if (col + c < 0 || moduleCount <= col + c) continue;
          if (r == 0 && c == 0) continue;
          if (dark == qr.isDark(row + r, col + c)) {
            sameCount++;
          }
        }
      }
      if (sameCount > 5) {
        lostPoint += 3 + sameCount - 5;
      }
    }
  }

  // LEVEL2
  for (row = 0; row < moduleCount - 1; row++) {
    for (col = 0; col < moduleCount - 1; col++) {
      var count = 0;
      if (qr.isDark(row, col)) count++;
      if (qr.isDark(row + 1, col)) count++;
      if (qr.isDark(row, col + 1)) count++;
      if (qr.isDark(row + 1, col + 1)) count++;
      if (count == 0 || count == 4) {
        lostPoint += 3;
      }
    }
  }

  // LEVEL3
  for (row = 0; row < moduleCount; row++) {
    for (col = 0; col < moduleCount - 6; col++) {
      if (qr.isDark(row, col) &&
          !qr.isDark(row, col + 1) &&
          qr.isDark(row, col + 2) &&
          qr.isDark(row, col + 3) &&
          qr.isDark(row, col + 4) &&
          !qr.isDark(row, col + 5) &&
          qr.isDark(row, col + 6)) {
        lostPoint += 40;
      }
    }
  }

  for (col = 0; col < moduleCount; col++) {
    for (row = 0; row < moduleCount - 6; row++) {
      if (qr.isDark(row, col) &&
          !qr.isDark(row + 1, col) &&
          qr.isDark(row + 2, col) &&
          qr.isDark(row + 3, col) &&
          qr.isDark(row + 4, col) &&
          !qr.isDark(row + 5, col) &&
          qr.isDark(row + 6, col)) {
        lostPoint += 40;
      }
    }
  }

  // LEVEL4
  var darkCount = 0;
  for (col = 0; col < moduleCount; col++) {
    for (row = 0; row < moduleCount; row++) {
      if (qr.isDark(row, col)) darkCount++;
    }
  }
  final ratio = (100 * darkCount / moduleCount / moduleCount - 50).abs() / 5;
  return lostPoint + ratio * 10;
}

// ============================================================================
// FLUTTER WIDGET — CustomPainter-based QR renderer
// ============================================================================

/// Shape of individual data modules (the small squares/dots).
enum QrModuleShape { square, roundedSquare, circle }

/// Shape of the three finder pattern eyes.
enum QrEyeShape { square, roundedSquare, circle }

/// A fully customizable QR code widget.
///
/// ```dart
/// PublicOSQr(
///   data: 'publicos://u/0xD6D5bc2f8fb68944e9E370338E09f094bA5E1326',
///   size: 200,
///   moduleColor: Color(0xFF1ECAA3),
///   backgroundColor: Color(0xFF1A1F2E),
///   moduleShape: QrModuleShape.roundedSquare,
///   eyeShape: QrEyeShape.roundedSquare,
///   moduleRadius: 0.4,
/// )
/// ```
class PublicOSQr extends StatelessWidget {
  /// The data to encode in the QR code.
  final String data;

  /// Widget size (width = height).
  final double size;

  /// Color of the dark modules.
  final Color moduleColor;

  /// Background color.
  final Color backgroundColor;

  /// Color of the finder pattern eyes. Defaults to [moduleColor].
  final Color? eyeColor;

  /// Shape of data modules.
  final QrModuleShape moduleShape;

  /// Shape of finder pattern eyes.
  final QrEyeShape eyeShape;

  /// Corner radius factor for roundedSquare shapes (0.0 = square, 1.0 = circle).
  final double moduleRadius;

  /// Corner radius factor for eye shapes (0.0 = square, 1.0 = fully rounded).
  final double eyeRadius;

  /// Error correction level. Higher = more redundancy (allows embedded images).
  final int errorCorrection;

  /// Padding around the QR code (quiet zone), in modules.
  final int quietZone;

  const PublicOSQr({
    super.key,
    required this.data,
    this.size = 200,
    this.moduleColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.eyeColor,
    this.moduleShape = QrModuleShape.square,
    this.eyeShape = QrEyeShape.square,
    this.moduleRadius = 0.5,
    this.eyeRadius = 0.5,
    this.errorCorrection = QrErrorCorrection.medium,
    this.quietZone = 1,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = QrMatrix.fromData(data, errorCorrection: errorCorrection);
    return Container(
      width: size,
      height: size,
      color: backgroundColor,
      child: CustomPaint(
        size: Size(size, size),
        painter: _QrPainter(
          matrix: matrix,
          moduleColor: moduleColor,
          eyeColor: eyeColor ?? moduleColor,
          moduleShape: moduleShape,
          eyeShape: eyeShape,
          moduleRadius: moduleRadius,
          eyeRadius: eyeRadius,
          quietZone: quietZone,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final QrMatrix matrix;
  final Color moduleColor;
  final Color eyeColor;
  final QrModuleShape moduleShape;
  final QrEyeShape eyeShape;
  final double moduleRadius;
  final double eyeRadius;
  final int quietZone;

  _QrPainter({
    required this.matrix,
    required this.moduleColor,
    required this.eyeColor,
    required this.moduleShape,
    required this.eyeShape,
    required this.moduleRadius,
    required this.eyeRadius,
    required this.quietZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalModules = matrix.moduleCount + (quietZone * 2);
    final pixelSize = size.shortestSide / totalModules;
    final offset = quietZone * pixelSize;

    // Draw data modules (skip finder pattern areas — we draw those separately)
    final modulePaint = Paint()
      ..color = moduleColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var row = 0; row < matrix.moduleCount; row++) {
      for (var col = 0; col < matrix.moduleCount; col++) {
        if (matrix.isFinderPattern(row, col)) continue;
        if (!matrix.isDark(row, col)) continue;

        final left = offset + col * pixelSize;
        final top = offset + row * pixelSize;
        final rect = Rect.fromLTWH(left, top, pixelSize, pixelSize);

        switch (moduleShape) {
          case QrModuleShape.square:
            canvas.drawRect(rect, modulePaint);
          case QrModuleShape.roundedSquare:
            final r = pixelSize * moduleRadius * 0.5;
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(r)),
              modulePaint,
            );
          case QrModuleShape.circle:
            canvas.drawCircle(
              rect.center,
              pixelSize * 0.45,
              modulePaint,
            );
        }
      }
    }

    // Draw finder patterns
    _drawFinderPattern(canvas, offset, offset, pixelSize);
    _drawFinderPattern(
      canvas,
      offset + (matrix.moduleCount - 7) * pixelSize,
      offset,
      pixelSize,
    );
    _drawFinderPattern(
      canvas,
      offset,
      offset + (matrix.moduleCount - 7) * pixelSize,
      pixelSize,
    );
  }

  void _drawFinderPattern(
    Canvas canvas,
    double left,
    double top,
    double pixelSize,
  ) {
    final eyePaint = Paint()
      ..color = eyeColor
      ..isAntiAlias = true;

    final outerSize = pixelSize * 7;
    final outerRect = Rect.fromLTWH(left, top, outerSize, outerSize);

    final innerSize = pixelSize * 5;

    final dotOffset = pixelSize * 2;
    final dotSize = pixelSize * 3;
    final dotRect = Rect.fromLTWH(
      left + dotOffset,
      top + dotOffset,
      dotSize,
      dotSize,
    );

    switch (eyeShape) {
      case QrEyeShape.square:
        // Outer border
        eyePaint.style = PaintingStyle.stroke;
        eyePaint.strokeWidth = pixelSize;
        canvas.drawRect(
          outerRect.deflate(pixelSize / 2),
          eyePaint,
        );
        // Inner dot
        eyePaint.style = PaintingStyle.fill;
        canvas.drawRect(dotRect, eyePaint);

      case QrEyeShape.roundedSquare:
        final outerR = outerSize * eyeRadius * 0.2;
        final dotR = dotSize * eyeRadius * 0.25;
        // Outer border
        eyePaint.style = PaintingStyle.stroke;
        eyePaint.strokeWidth = pixelSize;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            outerRect.deflate(pixelSize / 2),
            Radius.circular(outerR),
          ),
          eyePaint,
        );
        // Inner dot
        eyePaint.style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(dotRect, Radius.circular(dotR)),
          eyePaint,
        );

      case QrEyeShape.circle:
        // Outer ring
        eyePaint.style = PaintingStyle.stroke;
        eyePaint.strokeWidth = pixelSize;
        canvas.drawCircle(
          outerRect.center,
          (outerSize - pixelSize) / 2,
          eyePaint,
        );
        // Inner dot
        eyePaint.style = PaintingStyle.fill;
        canvas.drawCircle(
          dotRect.center,
          dotSize / 2,
          eyePaint,
        );
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) =>
      matrix != oldDelegate.matrix ||
      moduleColor != oldDelegate.moduleColor ||
      eyeColor != oldDelegate.eyeColor ||
      moduleShape != oldDelegate.moduleShape ||
      eyeShape != oldDelegate.eyeShape ||
      moduleRadius != oldDelegate.moduleRadius ||
      eyeRadius != oldDelegate.eyeRadius;
}

// ============================================================================
// RS BLOCK TABLE (QR spec data, versions 1-40)
// ============================================================================

const List<List<int>> _rsBlockTable = [
  // 1
  [1, 26, 19],
  [1, 26, 16],
  [1, 26, 13],
  [1, 26, 9],
  // 2
  [1, 44, 34],
  [1, 44, 28],
  [1, 44, 22],
  [1, 44, 16],
  // 3
  [1, 70, 55],
  [1, 70, 44],
  [2, 35, 17],
  [2, 35, 13],
  // 4
  [1, 100, 80],
  [2, 50, 32],
  [2, 50, 24],
  [4, 25, 9],
  // 5
  [1, 134, 108],
  [2, 67, 43],
  [2, 33, 15, 2, 34, 16],
  [2, 33, 11, 2, 34, 12],
  // 6
  [2, 86, 68],
  [4, 43, 27],
  [4, 43, 19],
  [4, 43, 15],
  // 7
  [2, 98, 78],
  [4, 49, 31],
  [2, 32, 14, 4, 33, 15],
  [4, 39, 13, 1, 40, 14],
  // 8
  [2, 121, 97],
  [2, 60, 38, 2, 61, 39],
  [4, 40, 18, 2, 41, 19],
  [4, 40, 14, 2, 41, 15],
  // 9
  [2, 146, 116],
  [3, 58, 36, 2, 59, 37],
  [4, 36, 16, 4, 37, 17],
  [4, 36, 12, 4, 37, 13],
  // 10
  [2, 86, 68, 2, 87, 69],
  [4, 69, 43, 1, 70, 44],
  [6, 43, 19, 2, 44, 20],
  [6, 43, 15, 2, 44, 16],
  // 11
  [4, 101, 81],
  [1, 80, 50, 4, 81, 51],
  [4, 50, 22, 4, 51, 23],
  [3, 36, 12, 8, 37, 13],
  // 12
  [2, 116, 92, 2, 117, 93],
  [6, 58, 36, 2, 59, 37],
  [4, 46, 20, 6, 47, 21],
  [7, 42, 14, 4, 43, 15],
  // 13
  [4, 133, 107],
  [8, 59, 37, 1, 60, 38],
  [8, 44, 20, 4, 45, 21],
  [12, 33, 11, 4, 34, 12],
  // 14
  [3, 145, 115, 1, 146, 116],
  [4, 64, 40, 5, 65, 41],
  [11, 36, 16, 5, 37, 17],
  [11, 36, 12, 5, 37, 13],
  // 15
  [5, 109, 87, 1, 110, 88],
  [5, 65, 41, 5, 66, 42],
  [5, 54, 24, 7, 55, 25],
  [11, 36, 12],
  // 16
  [5, 122, 98, 1, 123, 99],
  [7, 73, 45, 3, 74, 46],
  [15, 43, 19, 2, 44, 20],
  [3, 45, 15, 13, 46, 16],
  // 17
  [1, 135, 107, 5, 136, 108],
  [10, 74, 46, 1, 75, 47],
  [1, 50, 22, 15, 51, 23],
  [2, 42, 14, 17, 43, 15],
  // 18
  [5, 150, 120, 1, 151, 121],
  [9, 69, 43, 4, 70, 44],
  [17, 50, 22, 1, 51, 23],
  [2, 42, 14, 19, 43, 15],
  // 19
  [3, 141, 113, 4, 142, 114],
  [3, 70, 44, 11, 71, 45],
  [17, 47, 21, 4, 48, 22],
  [9, 39, 13, 16, 40, 14],
  // 20
  [3, 135, 107, 5, 136, 108],
  [3, 67, 41, 13, 68, 42],
  [15, 54, 24, 5, 55, 25],
  [15, 43, 15, 10, 44, 16],
  // 21
  [4, 144, 116, 4, 145, 117],
  [17, 68, 42],
  [17, 50, 22, 6, 51, 23],
  [19, 46, 16, 6, 47, 17],
  // 22
  [2, 139, 111, 7, 140, 112],
  [17, 74, 46],
  [7, 54, 24, 16, 55, 25],
  [34, 37, 13],
  // 23
  [4, 151, 121, 5, 152, 122],
  [4, 75, 47, 14, 76, 48],
  [11, 54, 24, 14, 55, 25],
  [16, 45, 15, 14, 46, 16],
  // 24
  [6, 147, 117, 4, 148, 118],
  [6, 73, 45, 14, 74, 46],
  [11, 54, 24, 16, 55, 25],
  [30, 46, 16, 2, 47, 17],
  // 25
  [8, 132, 106, 4, 133, 107],
  [8, 75, 47, 13, 76, 48],
  [7, 54, 24, 22, 55, 25],
  [22, 45, 15, 13, 46, 16],
  // 26
  [10, 142, 114, 2, 143, 115],
  [19, 74, 46, 4, 75, 47],
  [28, 50, 22, 6, 51, 23],
  [33, 46, 16, 4, 47, 17],
  // 27
  [8, 152, 122, 4, 153, 123],
  [22, 73, 45, 3, 74, 46],
  [8, 53, 23, 26, 54, 24],
  [12, 45, 15, 28, 46, 16],
  // 28
  [3, 147, 117, 10, 148, 118],
  [3, 73, 45, 23, 74, 46],
  [4, 54, 24, 31, 55, 25],
  [11, 45, 15, 31, 46, 16],
  // 29
  [7, 146, 116, 7, 147, 117],
  [21, 73, 45, 7, 74, 46],
  [1, 53, 23, 37, 54, 24],
  [19, 45, 15, 26, 46, 16],
  // 30
  [5, 145, 115, 10, 146, 116],
  [19, 75, 47, 10, 76, 48],
  [15, 54, 24, 25, 55, 25],
  [23, 45, 15, 25, 46, 16],
  // 31
  [13, 145, 115, 3, 146, 116],
  [2, 74, 46, 29, 75, 47],
  [42, 54, 24, 1, 55, 25],
  [23, 45, 15, 28, 46, 16],
  // 32
  [17, 145, 115],
  [10, 74, 46, 23, 75, 47],
  [10, 54, 24, 35, 55, 25],
  [19, 45, 15, 35, 46, 16],
  // 33
  [17, 145, 115, 1, 146, 116],
  [14, 74, 46, 21, 75, 47],
  [29, 54, 24, 19, 55, 25],
  [11, 45, 15, 46, 46, 16],
  // 34
  [13, 145, 115, 6, 146, 116],
  [14, 74, 46, 23, 75, 47],
  [44, 54, 24, 7, 55, 25],
  [59, 46, 16, 1, 47, 17],
  // 35
  [12, 151, 121, 7, 152, 122],
  [12, 75, 47, 26, 76, 48],
  [39, 54, 24, 14, 55, 25],
  [22, 45, 15, 41, 46, 16],
  // 36
  [6, 151, 121, 14, 152, 122],
  [6, 75, 47, 34, 76, 48],
  [46, 54, 24, 10, 55, 25],
  [2, 45, 15, 64, 46, 16],
  // 37
  [17, 152, 122, 4, 153, 123],
  [29, 74, 46, 14, 75, 47],
  [49, 54, 24, 10, 55, 25],
  [24, 45, 15, 46, 46, 16],
  // 38
  [4, 152, 122, 18, 153, 123],
  [13, 74, 46, 32, 75, 47],
  [48, 54, 24, 14, 55, 25],
  [42, 45, 15, 32, 46, 16],
  // 39
  [20, 147, 117, 4, 148, 118],
  [40, 75, 47, 7, 76, 48],
  [43, 54, 24, 22, 55, 25],
  [10, 45, 15, 67, 46, 16],
  // 40
  [19, 148, 118, 6, 149, 119],
  [18, 75, 47, 31, 76, 48],
  [34, 54, 24, 34, 55, 25],
  [20, 45, 15, 61, 46, 16],
];
