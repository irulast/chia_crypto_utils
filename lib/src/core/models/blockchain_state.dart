class BlockchainState {
  int difficulty;
  Peak? peak;

  BlockchainState({
    required this.difficulty,
    this.peak,
  });

  factory BlockchainState.fromJson(Map<String, dynamic> json) {
    return BlockchainState(
      difficulty: json['difficulty'] as int,
      peak: json['peak'] != null ? Peak.fromJson(json['peak'] as Map<String, dynamic>) : null,
    );
  }
}

class Peak {
  int height;

  Peak({
    required this.height,
  });

  factory Peak.fromJson(Map<String, dynamic> json) {
    return Peak(height: json['height'] as int);
  }
}
