import { Pool } from "pg";
import { ethers } from "ethers";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";

dotenv.config({ path: path.join(__dirname, "../../.env") });

// PostgreSQL Connection Pool
export const db = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Load Contract Address dynamically from our deployment script output
const addressesPath = path.join(__dirname, "../../deployments/addresses.json");
let contractAddress = "";
if (fs.existsSync(addressesPath)) {
  const data = JSON.parse(fs.readFileSync(addressesPath, "utf8"));
  contractAddress = data.ZKRollupPayments;
} else {
  console.warn(
    "Deployments file not found. Ensure Hardhat deployment has run.",
  );
}

// Ethers.js Setup
export const provider = new ethers.JsonRpcProvider(
  process.env.RPC_URL || "http://127.0.0.1:8545",
);

const abi = [
  "function deposits(address) view returns (uint256)",
  "function currentStateRoot() view returns (bytes32)",
  "function batchCount() view returns (uint256)",
  "function commitBatch(bytes32,bytes32,uint256,bytes,uint256[]) external",
  "event Deposited(address indexed user, uint256 amount, uint256 newBalance)",
  "event BatchCommitted(uint256 indexed batchIndex, bytes32 newStateRoot, bytes32 batchHash, uint256 txCount, address relayer)",
  "event Withdrawn(address indexed user, uint256 amount)",
];

export const rollupContract = new ethers.Contract(
  contractAddress,
  abi,
  provider,
);
