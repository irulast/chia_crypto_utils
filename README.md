# Chia Crypto Utils

An SDK for interacting with Chia primitives serving as a basis for a Chia client.

- Generating hardened and unhardened keys from a 24 word mnemonic seed
- Standard transaction (XCH) coin spend
- CAT
- PlotNFT
- NFT
- Offer
- Integration tests using the Chia simulator
- Serialization and deserialization to and from Bytes for easy integration into secure storage
- Atomic swap between Chia and Bitcoin

## Dependencies

This repository is written in [Dart](https://dart.dev/get-dart) to enable mobile and web usage. You may install either the Dart SDK or the [Flutter SDK](https://docs.flutter.dev/get-started/install), which also includes Dart. 

## Build and Test

```console
dart test
```

```console
00:00 +0: test/wallet_service_test.dart: (suite)
  Skip: Integration test
00:08 +223 ~1: test/utils_test/utils_test.dart: should generate correct puzzle hashes from mnemonic
Fingerprint: 3109357790
Master public key (m): 901acd53bf61a63120f15442baf0f2a656267b08ba42c511b9bb543e31c32a9b49a0e0aa5e897bc81878d703fcd889f3
Farmer public key (m/12381/8444/0/0): 8351d5afd1ab40bf37565d25600c9b147dcda344e19d413b2c468316d1efd312f61a1eca02a74f8d5f0d6e79911c23ca
Pool public key (m/12381/8444/1/0): 926c9b71f4cfc3f8a595fc77d7edc509e2f426704489eaba6f86728bc391c628c402e00190ba3617931649d8c53b5520
First wallet address: txch1v8vergyvwugwv0tmxwnmeecuxh3tat5jaskkunnn79zjz0muds0qlg2szv
01:02 +896 ~1: All tests passed!
```

For integration tests, execute the following script:

```console
bash ./integration_test/run_tests.sh
```

```console
00:28 +6: integration_test/network/mainnet_test.dart(suite)
  Skip: Test provided for reference, not nominally run
00:28 +6 ~1: integration_test/network/testnet10_test.dart: (suite)
  Skip: Test provided for reference, not nominally run
00:47 +14 ~2: All tests passed!
```

To run integration tests from VS Code UI, add the following json file to chia-crypto-utils root
    
simulator_gen_path.json
```json
{
    "path":"absolute_path_to_simulator_gen_folder"
}
```

## Example
```dart
 // Initialize keychain
const mnemonic = 'abandon broom kind...';

final keychainSecret = KeychainCoreSecret.fromMnemonicString(mnemonic);

final keychain = WalletKeychain.fromCoreSecret(
  keychainSecret,
  walletSize: 50,
);

// Initialize full node
final certBytes = File('CERT_PATH').readAsBytesSync();
final keyBytes = File('KEY_PATH').readAsBytesSync();

final fullNode = ChiaFullNodeInterface.fromURL(
  'FULL_NODE_URL',
  certBytes: Bytes(certBytes),
  keyBytes: Bytes(keyBytes),
);

final wallet = ColdWallet(
  fullNode: fullNode,
  keychain: keychain,
);

await wallet.sendXch(
  Address('RECEIVER_ADDRESS').toPuzzlehash(),
  amount: 1000000000,
);
```

## Coverage 

### Dependencies

Install [Flutter](https://docs.flutter.dev/get-started/install) and add the flutter tool to your path.

[LCOV](https://ltp.sourceforge.net/coverage/lcov.php) is used to create a coverage report in HTML format.

### Generate Coverage Report

Run tests
```console
bash ./integration_test/run_tests.sh
flutter test test --coverage --coverage-path=coverage/test.info
```

Merge coverage files
```console
lcov --add-tracefile coverage/test.info --add-tracefile coverage/integration_test.info --output-file coverage/merged_coverage.info
```

Generate coverage report
```console
genhtml coverage/merged_coverage.info -o coverage
```

View the coverage report
```console
open coverage/index.html
```
