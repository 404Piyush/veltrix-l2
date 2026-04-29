# Veltrix L2 Roadmap

This roadmap outlines the journey from initial concept to a production-ready budget-conscious Ethereum L2.

## Phase 1: Foundations & Local Devnet (Current)
- [x] Project scaffolding and directory structure.
- [x] Smart contract environment initialization (Foundry).
- [x] Infrastructure configuration templates (.env, docker-compose).
- [ ] Local genesis generation and rollup configuration.
- [ ] Successful local devnet launch (L1 + L2).
- [ ] Basic deposit/withdrawal testing on local devnet.

## Phase 2: Private Testnet (Sepolia)
- [ ] Deployment of L1 standard bridge contracts to Sepolia.
- [ ] Configuration of `op-node`, `op-batcher`, and `op-proposer` for Sepolia.
- [ ] Internal team testing of bridge flows and transaction lifecycle.
- [ ] Setting up initial monitoring (Prometheus/Grafana).

## Phase 3: Public Testnet
- [ ] Public RPC endpoints (via Alchemy/Infura).
- [ ] Faucet for testnet ETH.
- [ ] Block explorer integration (Blockscout).
- [ ] Documentation for developers to deploy dApps.
- [ ] Community testing and feedback.

## Phase 4: Hardening & Security
- [ ] Comprehensive fuzzing and static analysis of any custom contracts.
- [ ] Security rehearsals (sequencer failure, backup restoration).
- [ ] External security review/audit.
- [ ] Finalizing tokenomics and governance model.

## Phase 5: Mainnet Candidate
- [ ] Mainnet deployment rehearsal.
- [ ] L1 data-posting budget and operational funding.
- [ ] Official Mainnet launch.
