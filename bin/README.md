# Bin

First clone module with Mozilla's CA cert bundle in the root directory:

```console
git clone https://github.com/Chia-Network/mozilla-ca.git
```

## Get Coin Records
Use this command to get coin records for a given puzzlehash or address. Only one of these parameters is required.   

```console
dart bin/chia_crypto_utils.dart Get-CoinRecords --full-node-url <FULL_NODE_URL> --puzzlehash <PUZZLEHASH> --address <ADDRESS> 
```

Can include optional parameter to specify whether to include spent coins, which defaults to false.

```console
dart bin/chia_crypto_utils.dart Get-CoinRecords --full-node-url <FULL_NODE_URL> --puzzlehash <PUZZLEHASH> --address <ADDRESS> --includeSpentCoins 'true'
```

## Create Wallet With PlotNFT

Use this command to create a wallet with a new plotNFT:

```console
dart bin/chia_crypto_utils.dart Create-WalletWithPlotNFT --full-node-url <FULL_NODE_URL> --faucet-request-url <FAUCET_URL> --faucet-request-payload '{"address": "SEND_TO_ADDRESS", "amount": 0.0000000001}'
```

Can also omit the faucet url and payload if you would like to manually send the XCH needed to create the PlotNFT:

```console
dart bin/chia_crypto_utils.dart Create-WalletWithPlotNFT --full-node-url <FULL_NODE_URL>
```

## Get Farming Status

Use this command to get the farming status of a mnemonic:

```console
echo "the mnemonic seed" | dart bin/chia_crypto_utils.dart Get-FarmingStatus --full-node-url <FULL_NODE_URL>
```

## Exchange BTC and XCH

Use the below command to initiate an atomic swap between XCH and BTC. You must coordinate with your counter party such that they synchronously run the same command. This feature is adapted from https://github.com/richardkiss/chiaswap

```console
dart bin/chia_crypto_utils.dart Exchange-Btc --full-node-url https://chia.irulast-prod.com
```