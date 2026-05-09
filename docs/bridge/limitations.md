# Bridge Limitations

Current status: functional first milestone, not final product.

## Functional Now

- Connect wallet.
- Load Sepolia L1 balance.
- Load Veltrix L2 balance.
- Deposit ETH from Sepolia through `OptimismPortal.depositTransaction`.
- Initiate ETH withdrawals on Veltrix L2 through `L2ToL1MessagePasser.initiateWithdrawal`.
- Display submitted transactions in the local UI session.
- Show a static withdrawal lifecycle panel.

## Not Yet In UI

- Withdrawal proof action.
- Withdrawal finalization action.
- Automatic deposit status tracking by L1 block.
- Automatic withdrawal status tracking by L2 block and dispute-game state.
- Persistent bridge history.
- Token bridge UI for ERC-20 assets.
- Public faucet integration.
- Production RPC/domain configuration in deployed environment.

## Script-Based Today

Run proof/finalization through:

```bash
cd /Users/piyushutkar/Desktop/Veltrix
L2_RPC=http://localhost:9546 WITHDRAWAL_CHECK_TIMEOUT=5m \
  bash ./ops/finalize-sepolia-withdrawal.sh \
  <withdrawal_tx_hash>
```

For the latest proven withdrawal:

```bash
L2_RPC=http://localhost:9546 WITHDRAWAL_CHECK_TIMEOUT=5m \
  bash ./ops/finalize-sepolia-withdrawal.sh \
  0x388625362bfdae7e5d300e787a472d6b13a20ce752af9d9786dfd72f815e6254
```

This withdrawal has now been finalized:

```text
Finalize tx: 0xeacca9d2e70560e4ebe972a8f09849628a0b1f0b49045c74a2ecb135ba30772f
Portal finalized flag: true
```

## User Messaging

Use this wording until proof/finalize are in the UI:

```text
The bridge UI currently supports deposits and withdrawal initiation. Withdrawal proof and finalization are operational but still handled through scripts while the full UI flow is being built.
```
