# Changelog

## 1.0.8

- Added CAT minting and reference TAILs
- Improved support for interaction with mainnet, testnet10
- Added convenience method for establishing network context
- Added a cold wallet generation example
- Enhanced full node interaction and API

## 1.0.7

- Added full node simulator

## 1.0.6

- Breaking: `Program.deserializeHexFile` receives `File` instead of `String`
- New constructor `Program.deserializeHexFilePath` (formerly `Program.deserializeHexFile`)
- Fixed `Program.deserializeHexFilePath` test
- `Address`, `WalletVector`, `MasterKeyPair`, and `Coin` are immutable

## 1.0.5

- Added support for Chia Asset Token (CAT)

## 1.0.4

- Added support for Flutter Mobile
- Optimization for FieldExtBase.toBool() method
- JacobianPoint is immutable
- FullNode and Client are immutable
- breaking: Program.at() returns void instead of Program because it is now thought to be used with cascade operator

## 1.0.3

- Added spend bundle validation. Minor bug fixes.

## 1.0.2

- Added standard transaction support and core Chia models.

## 1.0.1

- Added wallet tools.

## 1.0.0

- Initial version.
