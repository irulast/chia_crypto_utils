## CSV generation procedure
1. Import wallet from testMnemonic (in `tests/utils_test/utils_test.dart`)
2. Grab puzzle hashes, public keys from wallet sqlite file (`.chia/testnet10/wallet/db/blockchain_wallet_v2_testnet10_3109357790.sqlite`)
     - `SELECT derivation_index, pubkey, puzzle_hash from derivation_paths LIMIT 20`
3. Move items with same derivation to the same line (maintaining same order)
4. Remove `derivation_index` column, whitespaces