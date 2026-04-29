# 🌐 Veltrix L2

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status: Devnet](https://img.shields.io/badge/Status-In_Development-yellow.svg)]()

Veltrix is a modular, high-performance Ethereum Layer 2 rollup built on the **OP Stack**. Designed for developers who need extreme operational efficiency without compromising on Ethereum's security.

---

## 🚀 Vision
Veltrix aims to be the go-to execution environment for budget-conscious dApp developers. By leveraging the modularity of the OP Stack, we provide a L2 that scales with demand while keeping fees at a bare minimum.

## 🏗️ Technical Architecture
- **Framework**: [Optimism OP Stack](https://stack.optimism.io/)
- **Data Availability**: Ethereum (Sepolia)
- **Execution Engine**: Custom-tuned `op-geth`
- **Consensus Layer**: `op-node`
- **Smart Contracts**: Foundry-powered Solidity development
- **Deployment**: Automated via Docker & custom orchestration scripts

## 📁 Repository Overview
| Directory | Description |
| :--- | :--- |
| `contracts/` | Smart contract source code and test suites. |
| `ops/` | Infrastructure orchestration (docker-compose, deployment scripts). |
| `configs/` | Genesis state, rollup parameters, and devnet configurations. |
| `docs/` | Documentation for developers and contributors. |

## 🛠️ Getting Started
Ensure you have **Docker** and **Foundry** installed.

1. **Clone the repo**: `git clone https://github.com/[YOUR-USERNAME]/veltrix-l2.git`
2. **Launch the stack**: `./ops/start-veltrix.sh`
3. **Run contracts**: `cd contracts && forge test`

## 🛣️ Roadmap
- [x] Foundation & Scaffolding
- [x] Foundry Integration
- [x] Infrastructure Orchestration
- [ ] Chain Spec & Genesis Finalization
- [ ] Cross-chain Bridge Testing
- [ ] Public Testnet Launch

---
*Built with ❤️ by Piyush Utkar. Follow the journey.*
