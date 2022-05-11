# Chia Crypto Utils

This repository seeks to provide a working example of Chia Wallet fundamentals

- Generating hardened and unhardened keys from a 24 word mnemonic seed
- Standard transaction (XCH) coin spend with change back and fee
- CAT
- DID
- NFT

## Dependencies

This repository is written in [Dart](https://dart.dev/get-dart) to enable mobile and web usage.

## Installation

```console
dart pub global activate rps
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## Build and Test

```console
dart test

00:00 +0: test/wallet_service_test.dart: (suite)
  Skip: Integration test
00:08 +223 ~1: test/utils_test/utils_test.dart: should generate correct puzzle hashes from mnemonic
Fingerprint: 3109357790
Master public key (m): 901acd53bf61a63120f15442baf0f2a656267b08ba42c511b9bb543e31c32a9b49a0e0aa5e897bc81878d703fcd889f3
Farmer public key (m/12381/8444/0/0): 8351d5afd1ab40bf37565d25600c9b147dcda344e19d413b2c468316d1efd312f61a1eca02a74f8d5f0d6e79911c23ca
Pool public key (m/12381/8444/1/0: 926c9b71f4cfc3f8a595fc77d7edc509e2f426704489eaba6f86728bc391c628c402e00190ba3617931649d8c53b5520
First wallet address: txch1v8vergyvwugwv0tmxwnmeecuxh3tat5jaskkunnn79zjz0muds0qlg2szv
01:02 +896 ~1: All tests passed!
```

For integration test, run the following command:

```console
rps integration_tests

> integration_tests
$ dart test integration_test/ --concurrency=1

00:28 +6: integration_test/network/mainnet_test.dart(suite)
  Skip: Test provided for reference, not nominally run
00:28 +6 ~1: integration_test/network/testnet10_test.dart: (suite)
  Skip: Test provided for reference, not nominally run
00:47 +14 ~2: All tests passed!
```

## Keychain

### Initializing keychain

```dart
const mnemonic = ['elder', 'quality', 'this', ...];

// these should never be stored in memory, only in encrypted storage if at all
final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);

// generate keys, addresses, puzzlehashes at desired derivation index (both hardened and unhardened)
final walletKeyAddressSet = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, 0);

final keychain = WalletKeychain([walletKeyAddressSet])
```

### Adding CAT outer puzzle hashes for a given asset ID to your keychain

```dart
keychain.addOuterPuzzleHashesForAssetId(assetId);
```

## Context

```dart
// context that is passed into wallet services to give them knowledge of whatever blockchain is passed in
Context context = NetworkContext.makeContext(Network.mainnet);
```

## Pushing a standard transaction

```dart
// initializing WalletKeychain
const mnemonic = ['elder', 'quality', 'this', ...];
KeychainCoreSecret keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);

L walletsSetList = <WalletSet>[];
for (var i = 0; i < 10; i++) {
  final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
  walletsSetList.add(set1);
}
final keychain = WalletKeychain(walletsSetList);

// initializing FullNodeInterface
final fullNodeRpc  = FullNodeHttpRpc(
  'https://localhost:8555',
  certBytes: myPrivateCertBytes,
  keyBytes: myPrivateKeyBytes
);

final fullNode = ChiaFullNodeInterface(fullNodeRpc);

// initializing Service
Context context = NetworkContext.makeContext(Network.mainnet);
StandardWalletService standardWalletService = StandardWalletService(context);

// getting puzzlehashes to search for
List<Puzzlehash> myPuzzlehashes = keychain.unhardenedMap.values
  .map((walletVector) => walletVector.puzzlehash);

List<Coin> myCoins = await fullNode.getCoinsByPuzzleHashes(myPuzzlehashes);

// creating and pushing spend bundle
final spendBundle = standardWalletService.createSpendBundle(
    [
      Payment(amountToSendA, destinstionPuzzlehashA),
      Payment(amountToSendB, destinstionPuzzlehashB)
    ],
    myCoins,
    changePuzzlehash,
    keychain,
    fee: fee,
);

await fullNode.pushTransaction(spendBundle);
```

## Pushing a CAT transaction

```dart
// initializing WalletKeychain
const mnemonic = ['elder', 'quality', 'this', ...];
final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);

final walletsSetList = <WalletSet>[];
for (var i = 0; i < 10; i++) {
  final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
  walletsSetList.add(set1);
}

// outer puzzle hashes must be added to keychain so it can look up the correct keys, used when creating a spendbundle
final keychain = WalletKeychain(walletsSetList)
  ..addOuterPuzzleHashesForAssetId(assetId);

// initializing FullNodeInterface
final fullNodeRpc  = FullNodeHttpRpc(
  'https://localhost:8555',
  certBytes: myPrivateCertBytes,
  keyBytes: myPrivateKeyBytes
);

final fullNode = ChiaFullNodeInterface(fullNodeRpc);

// initializing Service
final context = NetworkContext.makeContext(Network.mainnet);
final catWalletService = CatWalletService(context);

// get outer puzzle hashes from keychain
final myOuterPuzzlehashes = keychain.getOuterPuzzleHashesForAssetId(assetId);

List<CatCoin> myCatCoins = await fullNode.getCatCoinsByOuterPuzzleHashes(myOuterPuzzlehashes);

// creating and pushing spend bundle
final spendBundle = catWalletService.createSpendBundle(
    [
      Payment(amountToSendA, destinstionPuzzlehashA),
      Payment(amountToSendB, destinstionPuzzlehashB)
    ],
    myCatCoins,
    changePuzzlehash,
    keychain,
);

await fullNode.pushTransaction(spendBundle);
```
