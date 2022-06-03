# Example

## Keychain

### Initializing keychain

```dart
const mnemonic = ['elder', 'quality', 'this', ...];

// these should never be stored in memory, only in encrypted storage if at all
final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);

// generate keys, addresses, puzzlehashes at desired derivation index (both hardened and unhardened)
final walletKeyAddressSet = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, 0);

final keychain = WalletKeychain.fromWalletSets([walletKeyAddressSet])
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

final walletsSetList = <WalletSet>[];
for (var i = 0; i < 10; i++) {
  final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
  walletsSetList.add(set1);
}
final keychain = WalletKeychain.fromWalletSets(walletsSetList);

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
final keychain = WalletKeychain.fromWalletSets(walletsSetList)
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
