import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

abstract class ChiaWalletInfo {
  int get id;
  String? get name;
  ChiaWalletType get type;
  String get data;
  Map<String, dynamic> get meta;
}

extension ToJson on ChiaWalletInfo {
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.chiaIndex,
      'data': data,
      'meta': meta,
    };
  }
}

extension StripData on ChiaWalletInfo {
  ChiaWalletInfoImp stripData() {
    return ChiaWalletInfoImp(
      id: id,
      name: name,
      type: type,
      meta: meta,
    );
  }
}

class ChiaWalletInfoImp implements ChiaWalletInfo {
  ChiaWalletInfoImp({
    required this.id,
    this.name = '',
    required this.type,
    this.data = '',
    required this.meta,
  });

  factory ChiaWalletInfoImp.fromJson(Map<String, dynamic> json) {
    return ChiaWalletInfoImp(
      id: pick(json, 'id').asIntOrThrow(),
      name: pick(json, 'name').asStringOrNull() ?? '',
      type: ChiaWalletType.fromIndex(pick(json, 'type').asIntOrThrow()),
      data: pick(json, 'data').asStringOrNull() ?? '',
      meta: pick(json, 'meta').letJsonOrThrow((json) => json),
    );
  }

  @override
  final int id;
  @override
  final String? name;
  @override
  final ChiaWalletType type;
  @override
  final String data;
  @override
  final Map<String, dynamic> meta;
}

mixin WalletInfoDecorator implements ChiaWalletInfo {
  ChiaWalletInfo get delegate;

  @override
  int get id => delegate.id;

  @override
  String? get name => delegate.name;

  @override
  ChiaWalletType get type => delegate.type;

  @override
  String get data => delegate.data;

  @override
  Map<String, dynamic> get meta => delegate.meta;
}

enum ChiaWalletType {
  standard(0),
  atomicSwap(2),
  authorizedPayee(3),
  multiSig(4),
  custody(5),
  cat(6),
  recoverable(7),
  did(8),
  pool(9),
  nft(10),
  dataLayer(11),
  dataLayerOffer(12);

  const ChiaWalletType(this.chiaIndex);
  factory ChiaWalletType.fromString(String typeString) {
    return ChiaWalletType.values
        .where((type) => typeString.split('_').first == type.name)
        .single;
  }

  factory ChiaWalletType.fromIndex(int index) {
    return ChiaWalletType.values
        .where((type) => type.chiaIndex == index)
        .single;
  }

  final int chiaIndex;
}

extension WalletsOfType on Map<int, ChiaWalletInfo> {
  Map<int, T> _getWalletsOfType<T>(
    ChiaWalletType type, [
    List<int> walletIds = const [],
  ]) {
    final filteredMap = Map<int, ChiaWalletInfo>.from(this)
      ..removeWhere(
        (key, value) =>
            value.type != type ||
            (walletIds.isNotEmpty && !walletIds.contains(key)),
      );

    return filteredMap.map((key, value) => MapEntry(key, value as T));
  }

  Map<int, NftWalletInfoWithNftInfos> nftWallets([
    List<int> walletIds = const [],
  ]) =>
      _getWalletsOfType(ChiaWalletType.nft, walletIds);

  Map<int, CatWalletInfo> catWallets([List<int> walletIds = const []]) =>
      _getWalletsOfType(ChiaWalletType.cat, walletIds);

  Map<int, DIDWalletInfo> didWallets([List<int> walletIds = const []]) =>
      _getWalletsOfType(ChiaWalletType.did, walletIds);
}

extension AssetIdsGetterX on Map<int, CatWalletInfo> {
  Map<int, Puzzlehash> get assetIdMap =>
      map((key, value) => MapEntry(key, value.assetId));

  List<Puzzlehash> get assetIds => assetIdMap.values.toList();
}

extension NftInfosGetterX on Map<int, NftWalletInfoWithNftInfos> {
  Map<int, List<NftInfo>> get nftInfosMap =>
      map((key, value) => MapEntry(key, value.nftInfos));

  List<NftInfo> get nftInfos {
    final nftInfos = <NftInfo>[];

    for (final value in nftInfosMap.values) {
      nftInfos.addAll(value);
    }

    return nftInfos;
  }

  Map<int, List<Bytes>> get launcherIdsMap => map(
        (key, value) => MapEntry(
          key,
          value.nftInfos.map((nftInfo) => nftInfo.launcherId).toList(),
        ),
      );

  List<Bytes> get launcherIds => launcherIdsMap.values.toList().flatten();
}

extension NftInfosListGetterX on List<NftWalletInfoWithNftInfos> {
  List<NftInfo> get nftInfos {
    final nftInfos = <NftInfo>[];
    for (final nftWallet in this) {
      nftInfos.addAll(nftWallet.nftInfos);
    }

    return nftInfos;
  }

  List<Bytes> get launcherIds =>
      nftInfos.map((nftInfo) => nftInfo.launcherId).toList();
}

extension DIDs on Map<int, DIDWalletInfo> {
  Map<int, Bytes> get didMap =>
      map((key, value) => MapEntry(key, value.didInfoWithOriginCoin.did));

  List<Bytes> get dids => didMap.values.toList();
}
