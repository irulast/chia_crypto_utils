import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:chia_crypto_utils/src/clvm/program.dart';

class Token {
  final String text;
  final int index;
  Token(this.text, this.index);
}

class Position {
  final int index;
  late final int line;
  late final int column;
  Position(String source, this.index) {
    var line = 1;
    var column = 1;
    final runes = source.replaceAll('\r\n', '\n').runes.toList();
    for (var i = 0; i < index; i++) {
      if (runes[i] == 0x000A) {
        line++;
        column = 1;
      } else {
        column++;
      }
    }
    this.line = line;
    this.column = column;
  }
  @override
  String toString() => '$line:$column';
}

bool isSpace(String char) {
  return RegExp(
    r'^[\u0020\u202F\u205F\u2028\u2029\u3000\u0085\u1680\u00A0\u2000-\u200A\u0009-\u000D\u001C-\u001F]$',
  ).hasMatch(char);
}

int consumeWhitespace(String text, int index) {
  while (true) {
    while (index < text.length && isSpace(text[index])) {
      index++;
    }
    if (index >= text.length || text[index] != ';') {
      break;
    }
    while (index < text.length && !'\n\r'.contains(text[index])) {
      index++;
    }
  }
  return index;
}

Token consumeUntilWhitespace(String text, int index) {
  final start = index;
  while (index < text.length && !isSpace(text[index]) && text[index] != ')') {
    index++;
  }
  return Token(text.substring(start, index), index);
}

Program tokenizeCons(String source, Iterator<Token> tokens) {
  var token = tokens.current;
  if (token.text == ')') {
    return Program.nil..at(Position(source, token.index));
  }
  final consStart = token.index;
  final first = tokenizeExpr(source, tokens);
  if (!tokens.moveNext()) {
    throw StateError('Unexpected end of source at ${Position(source, token.index)}.');
  }
  token = tokens.current;
  Program rest;
  if (token.text == '.') {
    final dotStart = token.index;
    if (!tokens.moveNext()) {
      throw StateError('Unexpected end of source at ${Position(source, token.index)}.');
    }
    token = tokens.current;
    rest = tokenizeExpr(source, tokens);
    if (!tokens.moveNext()) {
      throw StateError('Unexpected end of source at ${Position(source, token.index)}.');
    }
    token = tokens.current;
    if (token.text != ')') {
      throw StateError('Illegal dot expression at ${Position(source, dotStart)}.');
    }
  } else {
    rest = tokenizeCons(source, tokens);
  }
  return Program.cons(first, rest)..at(Position(source, consStart));
}

Program? tokenizeInt(String source, Token token) {
  return RegExp(r'^[+\-]?[0-9]+(?:_[0-9]+)*$').hasMatch(token.text)
      ? (Program.fromBigInt(BigInt.parse(token.text.replaceAll('_', '')))
        ..at(Position(source, token.index)))
      : null;
}

Program? tokenizeHex(String source, Token token) {
  if (token.text.length >= 2 && token.text.substring(0, 2).toUpperCase() == '0X') {
    var hex = token.text.substring(2);
    if (hex.length % 2 == 1) {
      hex = '0$hex';
    }
    try {
      return Program.fromHex(hex)..at(Position(source, token.index));
    } catch (e) {
      throw StateError('Invalid hex at ${token.index}: ${token.text}.');
    }
  } else {
    return null;
  }
}

Program? tokenizeQuotes(String source, Token token) {
  if (token.text.length < 2) {
    return null;
  }
  final quote = token.text[0];
  if (!'"\''.contains(quote)) {
    return null;
  }
  if (token.text[token.text.length - 1] != quote) {
    throw StateError('Unterminated string ${token.text} at ${Position(source, token.index)}.');
  }
  return Program.fromString(token.text.substring(1, token.text.length - 1))
    ..at(Position(source, token.index));
}

Program? tokenizeSymbol(String source, Token token) {
  var text = token.text;
  if (text.startsWith('#')) {
    text = text.substring(1);
  }
  final keyword = keywords[text];
  return (keyword != null ? Program.fromBigInt(keyword) : Program.fromString(text))
    ..at(Position(source, token.index));
}

Program tokenizeExpr(String source, Iterator<Token> tokens) {
  final token = tokens.current;
  if (token.text == '(') {
    if (!tokens.moveNext()) {
      throw StateError('Unexpected end of source at ${Position(source, token.index)}.');
    }
    return tokenizeCons(source, tokens);
  }
  final result = tokenizeInt(source, token) ??
      tokenizeHex(source, token) ??
      tokenizeQuotes(source, token) ??
      tokenizeSymbol(source, token);
  return result!;
}

Iterable<Token> tokenStream(String source) sync* {
  var index = 0;
  while (index < source.length) {
    index = consumeWhitespace(source, index);
    if (index >= source.length) {
      break;
    }
    final char = source[index];
    if ('(.)'.contains(char)) {
      yield Token(char, index);
      index++;
      continue;
    }
    if ('"\''.contains(char)) {
      final start = index;
      final quote = source[index];
      index++;
      while (index < source.length && source[index] != quote) {
        index++;
      }
      if (index < source.length) {
        yield Token(source.substring(start, index + 1), start);
        index++;
        continue;
      } else {
        throw StateError(
          'Unterminated string ${source.substring(start)} at ${Position(source, index)}.',
        );
      }
    }
    final token = consumeUntilWhitespace(source, index);
    yield Token(token.text, index);
    index = token.index;
  }
}
