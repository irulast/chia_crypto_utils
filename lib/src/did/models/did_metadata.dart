import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DidMetadata with ToProgramMixin {
  const DidMetadata(this.map) : _program = null;
  const DidMetadata._(this._program, this.map);
  factory DidMetadata.fromProgram(Program program) {
    return DidMetadata._(
      program,
      Map.fromEntries(
        program.toList().map(
          (e) {
            final cons = e.cons;

            return MapEntry(cons[0].string, cons[1].string);
          },
        ),
      ),
    );
  }

  final Program? _program;
  final Map<String, String> map;

  @override
  Program toProgram() {
    if (_program != null) {
      return _program!;
    }

    return Program.list(
      map.entries
          .map((e) => Program.cons(
              Program.fromString(e.key), Program.fromString(e.value)))
          .toList(),
    );
  }
}

extension ToDidMetadata on Map<String, String> {
  DidMetadata toDidMetadata() {
    return DidMetadata(this);
  }
}
