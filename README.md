# ZK-Rollup Payments

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Solidity](https://img.shields.io/badge/Solidity-363636?style=for-the-badge&logo=solidity&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

A full-stack, ZK-rollup-inspired payment system demonstrating a Layer 2 scaling solution on Ethereum.

## 🚀 Project Overview

This project implements a simplified Zero-Knowledge (ZK) Rollup payment system. It provides a Layer 2 scaling solution where users can deposit ETH from Layer 1, perform instant and gasless off-chain transactions on Layer 2, and have these transactions securely batched and verified back on the main chain.

The core idea is to move computation and state storage off-chain, leveraging a backend relayer to bundle hundreds of transactions into a single on-chain transaction. The validity of this batch is guaranteed by a (stubbed) zero-knowledge proof, which is efficiently verified by the Layer 1 smart contract.

## 🏛️ System Architecture

The system follows a modular, multi-tiered architecture that separates on-chain and off-chain concerns. The data flows from the user's browser to the L1 blockchain and back.

**Architectural Flow:**
`User -> Frontend (Flutter) -> Backend API (Node.js) -> Database (PostgreSQL) -> Relayer Service -> Smart Contract (Solidity)`

A detailed breakdown of each component can be found in the [Architecture Details](#-architecture-details) section at the end of this document.

## ✅ Prerequisites

Before you begin, ensure you have the following installed:

*   [Docker](https://www.docker.com/get-started) & Docker Compose
*   [Node.js](https://nodejs.org/en/download/) (LTS version recommended)

## 🏁 End-to-End Validation: A Step-by-Step Guide

This is the primary guide for setting up and validating the entire system. Following these steps will run the automated end-to-end test, which is the core evaluation criterion.

### Step 1: Configure Environment

Clone the repository and create a local environment file by copying the provided example.

```sh
cp .env.example .env
```
This file is pre-populated with default values for the Dockerized environment. You will add the necessary private keys in a later step.

### Step 2: Start All Services

Build and start all services in detached mode using Docker Compose.

```sh
docker-compose up -d --build
```
This command orchestrates the entire system, including the Hardhat blockchain, database, contract deployment, backend, and frontend.

### Step 3: Populate Private Keys

The `hardhat` service, when it starts, generates a list of test accounts and their private keys. You need to copy two of these keys into your `.env` file for the validation script to work.

1.  **View the Hardhat logs** to find the keys:
    ```sh
    docker-compose logs hardhat
    ```
2.  **Copy the private key** for the first account (Account #0) and paste it as the value for `RELAYER_PRIVATE_KEY` in your `.env` file.
3.  **Copy the private key** for the second account (Account #1) and paste it as the value for `USER_A_PRIVATE_KEY` in your `.env` file. Your `.env` file should look something like this:
    ```env
    # ... other variables
    RELAYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    USER_A_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
    # ... other variables
    ```

### Step 4: Run the Validation Script

With the services running and keys configured, execute the end-to-end validation script from your host machine.

```sh
node scripts/validate.js
```
This script simulates a full user journey: depositing ETH, submitting valid and invalid intents, waiting for the relayer to batch them, and verifying the final state on-chain and in the database.

### Step 5: Check the Validation Report

The script generates a `validation_report.json` file in the project root. A successful run is indicated by a `failed` count of `0`.

```json
{
  "passed": 6,
  "failed": 0,
  "results": [
    {
      "test": "User A deposits 0.5 ETH",
      "status": "pass",
      "detail": "Deposit successful and indexed."
    },
    // ... other results
  ]
}
```
**This report is the primary artifact for evaluating the system's correctness.** If `failed` is `0`, the project is working as expected.

---

## 💻 Exploring the System Manually

After successful validation, you can explore the running application.

*   **Frontend UI**: [http://localhost:8081](http://localhost:8081)
    *   Use the wallet addresses from the `docker-compose logs hardhat` output to explore balances and history.
*   **Backend API**: [http://localhost:4000](http://localhost:4000)
    *   Check API status: `curl http://localhost:4000/state`
    *   View batches: `curl http://localhost:4000/batches`

## 📂 Project Structure

The repository is organized into distinct directories, each with a specific responsibility:
```
.
├── backend/         # Node.js backend (API, Relayer, Indexer)
├── contracts/       # Solidity smart contracts
├── flutter_app/     # Flutter frontend application
├── scripts/         # Deployment and validation scripts
├── docker-compose.yml # Orchestrates all services
├── hardhat.config.js  # Hardhat configuration
└── README.md        # This file
```

## 🏛️ Architecture Details

1.  **Smart Contracts (Solidity/Hardhat)**: The on-chain anchor of the system.
    -   `ZKRollupPayments.sol`: Holds user deposits in escrow, verifies proofs submitted by the Relayer, and maintains the rollup's state root. It is the ultimate source of truth.
    -   `StubZKVerifier.sol`: A placeholder contract that simulates ZK proof verification by always returning `true`.

2.  **Backend (Node.js/Express)**: A powerful backend that serves three primary roles:
    -   **API**: Exposes REST endpoints for the frontend to submit payment "intents" and query indexed blockchain data.
    -   **Indexer**: Listens for on-chain events (`Deposited`, `BatchCommitted`) and populates the PostgreSQL database. This provides a fast, queryable cache of on-chain data.
    -   **Relayer**: A background worker that periodically fetches pending intents from the database, groups them into a "batch", computes a new state root, and calls the `commitBatch` function on the `ZKRollupPayments` contract.

3.  **Database (PostgreSQL)**: An off-chain database that stores payment intents, batch details, and indexed deposit events for fast and efficient querying.

4.  **Frontend (Flutter Web)**: The user-facing interface where users can manage their wallet, deposit funds into the L1 contract, initiate off-chain transfers, and view transaction history and batch details.
