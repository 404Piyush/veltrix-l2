# Veltrix Sepolia Contracts

Public contract and operator addresses for the Veltrix Sepolia-backed L2.

## Chain

- L1: Sepolia
- L1 chain ID: `11155111`
- L2: Veltrix Sepolia L2
- L2 chain ID: `42069`
- L2 chain ID hex: `0xa455`
- Native token: `ETH`
- Block time: `2s`

## Core L1 Contracts

| Contract | Address |
| --- | --- |
| `OptimismPortalProxy` | `0x9d6954E55297f9ae78e5c0dc2353c18b31aeA0b3` |
| `L1StandardBridgeProxy` | `0x138c79a5b92D31c8C48e9C8AAFFaAc06e732678A` |
| `L1CrossDomainMessengerProxy` | `0xA657bC1DAFdf553D85944e3889Ed85156A777585` |
| `SystemConfigProxy` | `0xfA2F9ad613A238EE2AD5D9307bE13a5003706Bfb` |
| `DisputeGameFactoryProxy` | `0xEEFd9e073235CB75074403711c13B477822FdfC4` |
| `AnchorStateRegistryProxy` | `0x20d2E9e8DC222A54EB0A31D899Fa0598C5AB6236` |
| `DelayedWETHProxy` | `0x0095681478F2387501Ae1d921fE9Af316EeF1Eb2` |
| `SuperchainConfigProxy` | `0x6302e70bB51b8bAC47a6b69367b4bF628ADC7604` |
| `ProtocolVersionsProxy` | `0x9277D89F57C602FbAC528243330e2447A7A3f7eB` |
| `OptimismMintableERC20FactoryProxy` | `0x1f5ab65bD1d4B0c5f1DBDc405E70227cEEfb10ad` |

## L2 Predeploys

| Contract | Address |
| --- | --- |
| `L2ToL1MessagePasser` | `0x4200000000000000000000000000000000000016` |

## Operators

These are public addresses only. Do not publish private keys.

| Role | Address |
| --- | --- |
| Deployer | `0x83FEb86BF4BF50092dcB4f5e41bAE2603172eE8E` |
| Sequencer | `0x4A04C47a3e52Ecdd472E8a63e77DAC474E0A828C` |
| Batcher | `0x6184AD388aa263135FA25D9ee48902159Aa7BF8d` |
| Proposer | `0x63748C342eabA529C428a1FEe2030FE5adbaDAB8` |
| Challenger | `0x1Ef40ad488CBF0948B17e00a35Bd13557802Fd2d` |

## Rollup Config

```text
Genesis L1 block: 10780324
Genesis L1 hash: 0xecd1b8cf09d4c16f0651f3d9a782ab674db9544fd0a9b0433bb77ad1b685b7f4
Genesis L2 hash: 0xe83a879518e1293d1b87f1b4163947f1bbe152164cfb7d8ea53fb9cd8847d630
Batch inbox: 0xff0000000000000000000000000000000000a455
Deposit contract: 0x9d6954e55297f9ae78e5c0dc2353c18b31aea0b3
System config: 0xfa2f9ad613a238ee2ad5d9307be13a5003706bfb
```

## Source Files

- `configs/l1-deployments.sepolia.json`
- `configs/sepolia-operators.json`
- `configs/rollup.sepolia.json`
