import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  final mainnetAddresses = _CryptoAddresses(
    xchAddress:
        'xch1076qvs03vfdj8kyzzs9uulg3pzj5d8y9k0tzxp5ph06svu6wx0us6vltu9',
    btcAddresses: [
      '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2', //P2PKH
      '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy', //P2SH
      'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq', //Bech32
      'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297', // taproot
    ],
  );

  final addresses = {
    Network.mainnet: mainnetAddresses,
  };

  group('Should parse addresses correctly', () {
    for (final network in addresses.keys) {
      test('for ${network.name}', () {
        ChiaNetworkContextWrapper().registerNetworkContext(network);

        final validCryptoAddresses = addresses[network]!;

        for (final address in validCryptoAddresses.btcAddresses) {
          final parsedAddress = BtcAddress.tryParse(address);
          expect(parsedAddress!.address, address);
        }

        expect(
          Address.tryParse(
            validCryptoAddresses.xchAddress,
          )!
              .address,
          validCryptoAddresses.xchAddress,
        );
      });
    }
  });

  test('Addresses should maintin equality and hash code', () {
    final addressString = mainnetAddresses.xchAddress;
    final address = Address(addressString);
    final walletAddress = WalletAddress(addressString, derivationIndex: 1);

    expect(address, walletAddress);

    expect(address.hashCode, walletAddress.hashCode);

    final set = <Address>{address};

    expect(set.contains(walletAddress), isTrue);

    set.remove(address);

    expect(set, isEmpty);

    set.add(walletAddress);

    expect(set.contains(address), isTrue);
  });
}

class _CryptoAddresses {
  _CryptoAddresses({required this.xchAddress, required this.btcAddresses});

  final String xchAddress;

  final List<String> btcAddresses;
}
