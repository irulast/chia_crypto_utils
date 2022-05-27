# Chia Crypto Utils

This repository provides an object model for working with Chia primitives serving as a basis for a Chia client.

- Generating hardened and unhardened keys from a 24 word mnemonic seed
- Standard transaction (XCH) coin spend
- CAT
- PlotNFT
- Integration tests using the Chia simulator
- Serialization and deserialization to and from Bytes for easy integration into secure storage

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

For integration tests, run the following command:

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
