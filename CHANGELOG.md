# Changelog

## 1.0.15

- Pooling protocol support
- CLI bindings and utility for interactively generating a PlotNFT
- Bug fixing and code cleanup

## 1.0.14

- Fixes for pub.dev

## 1.0.13

- Refactoring and code cleanup for publishing to pub.dev
- Normalized Chia simulator usage to ease use in packages importing or using Chia Crypto Utils

## 1.0.12

- PlotNFT support

## 1.0.11

- Singleton support
- Added ChiaEnthusiast for ease of testing
- Integration with Taildatabase.com and Hash.green
- Normalized usage of Bytes throughout the codebase
- Serialization and deserialization mechanisms on primitives
- Refactored IoC mechanism to use get_it
- Additional logging controls
- Static analysis warning resolutions
- Bug fixes

## 1.0.10

- Separated integration tests from standard tests per Dart best practices
- Refactor of Field, FieldExtBase, Fq, Fq2, Fq6 and Fq12
- WalletSet is immutable
- WalletVector and UnhardenedWalletVector are immutable
- WalletVector and UnhardenedWalletVector can be serialized and deserialized to bytes and from bytes respectively
- CAT melting
- CAT clsp files for reference
- Added method to serialize SpendBundle toHex for interoperability with Chia Dev Tools

## 1.0.9

- Bug fixes
- Added details for usage of M1 and Intel Mac Simulator Docker container
- Updated FullNode Interface
- Fixed CAT terminology - issuance, minting

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
