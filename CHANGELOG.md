# Changelog

## 1.0.6

- Address model is immutable
- Breaking: `Program.deserializeHexFile` receive a `File` instead of a `String`
- New constructor `Program.deserializeHexFilePath` (formerly `Program.deserializeHexFile`)
- Fix for `Program.deserializeHexFilePath` test

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
