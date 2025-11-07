## Vaults v2 feed

The goal of this project is to create a price feed for a Mangrove V2 vault. There needs to be 2 chainlink compatible sources, 1 for the base asset and 1 for the quote asset. The price feed will be a Chainlink AggregatorV2V3-style price-feed adapter for a V2-style vault.

### Math

The basic math behind the vault is we first compute the value held in the vault and divide by the number of shares.

The complexity lies in the decimal shifting that will be done.

### The final decimals

The vault price decimals will be the maximum between the base feed decimals and the quote feed decimals.

Let `D_vaultFeed = max(D_baseFeed, D_quoteFeed)`.

### The formulas

the actual math formula ignoring fixed point arithemtic is:

```
value = (B_base * P_base) + (B_quote * P_quote)
price = value / B_vault
```

With `B_base` and `B_quote` being the balances of the base and quote assets in the vault and `P_base` and `P_quote` being the prices of the base and quote assets in the feed and `B_vault` being the number of shares in the vault.

But we need to scale it so the final value answer is expressed in `D_vaultFeed` decimals.

```
value = (B_base * P_base * 10^(D_vaultFeed - D_baseFeed)) / 10^(D_base) + (B_quote * P_quote * 10^(D_vaultFeed - D_quoteFeed)) / 10^(D_quote)
price = value * 10^(D_vault) / B_vault
```

### Edge cases

When there is no shares in the vault, the price is defined as the price of the quote asset, this is indeed the price of a share on initial minting.

When one of the feeds or the vault fails to answer, the data will revert.

### Additional notes

- The vault only has one round that is 1.
- The latest updatedAt is the minimum of the base and quote feed updatedAt.

## Deployment

```sh
git clone git@github.com:mangrovedao/vaults-v2-chainlink-adapter.git
cd vaults-v2-chainlink-adapter
forge install
forge build
forge create src/VaultsV2Feed.sol:VaultsV2Feed $VAULT_ADDRESS $BASE_FEED $QUOTE_FEED --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```
