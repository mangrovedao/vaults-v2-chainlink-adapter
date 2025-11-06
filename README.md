## Vaults v2 feed

Let the underlying tokens A and B with decimals `a` and `b` respectively.

Let each token have a feed `F_A` and `F_B` with decimals `f_A` and `f_B` respectively that prices them agains USD.

Finally let the vault have `S` shares with `s` decimals.

We first need to compute our decimals for pricing calculations. For that we will take the maximum of the two feed decimals: `f = max(f_A, f_B)`.

Then we will compute the scaling factors for the two feeds: `scale_A = 10^(a + f - f_A)` and `scale_B = 10^(b + f - f_B)`.

Then we need to compute the balances of the two tokens in the vault scaled in USD with `f` decimals: `USDbalance_A = balance_A * scale_A * 10^f / F_A` and `USDbalance_B = balance_B * scale_B * 10^f / F_B`.

Finally we can compute the price of a share of the vault: `price = (USDbalance_A + USDbalance_B) * 10^s / S`.