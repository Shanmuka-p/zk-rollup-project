import express from "express";
import cors from "cors";
import { execSync } from "child_process";
import { db, rollupContract } from "./config";
import { startIndexer } from "./indexer";
import { startRelayer } from "./relayer";

const app = express();
app.use(cors());
app.use(express.json());

// --- REST API Endpoints ---

// Submit a new intent
app.post("/intents", async (req, res) => {
  const { fromAddress, toAddress, amountWei } = req.body;
  try {
    // Live balance check on L1 contract
    const balance = await rollupContract.deposits(fromAddress);
    if (BigInt(balance.toString()) < BigInt(amountWei)) {
      return res.status(400).json({ error: "Insufficient on-chain deposit" });
    }

    const result = await db.query(
      `INSERT INTO payment_intents (from_address, to_address, amount_wei) 
             VALUES ($1, $2, $3) RETURNING id, status`,
      [fromAddress, toAddress, amountWei],
    );
    res
      .status(201)
      .json({ intentId: result.rows[0].id, status: result.rows[0].status });
  } catch (error) {
    res.status(500).json({ error: "Failed to submit intent" });
  }
});

// Get intents with optional filtering
app.get("/intents", async (req, res) => {
  const { address, status } = req.query;
  let query = `SELECT * FROM payment_intents WHERE 1=1`;
  const values: any[] = [];

  if (address) {
    values.push(address);
    query += ` AND from_address = $${values.length}`;
  }
  if (status) {
    values.push(status);
    query += ` AND status = $${values.length}`;
  }

  query += ` ORDER BY created_at DESC`;

  const result = await db.query(query, values);
  res.json({ intents: result.rows });
});

// Get all batches
app.get("/batches", async (req, res) => {
  const result = await db.query(
    `SELECT * FROM batches ORDER BY created_at DESC`,
  );
  res.json({ batches: result.rows });
});

// Get a specific batch by index
app.get("/batches/:batchIndex", async (req, res) => {
  const batchIndex = req.params.batchIndex;
  const batchResult = await db.query(
    `SELECT * FROM batches WHERE batch_index = $1`,
    [batchIndex],
  );

  if (batchResult.rows.length === 0) {
    return res.status(404).json({ error: "Batch not found" });
  }

  // Simplification: In a real app, we'd link intents directly to batch_id.
  // Here we just return the batch data.
  res.json({ batch: batchResult.rows[0], intents: [] });
});

// Get live deposit balance
app.get("/deposits/:address", async (req, res) => {
  try {
    const address = req.params.address;
    const balanceWei = await rollupContract.deposits(address);
    res.json({
      address,
      balanceWei: balanceWei.toString(),
      balanceEth: (Number(balanceWei) / 1e18).toString(),
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch deposits" });
  }
});

// Get live rollup state
app.get("/state", async (req, res) => {
  try {
    const currentStateRoot = await rollupContract.currentStateRoot();
    const batchCount = await rollupContract.batchCount();
    const contractAddress = await rollupContract.getAddress();
    res.json({
      currentStateRoot,
      batchCount: Number(batchCount),
      contractAddress,
    });
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch state" });
  }
});

// --- Bootstrapping ---
const PORT = process.env.API_PORT || 4000;

app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);

  // Automatically run DB migrations on startup
  console.log("Running database migrations...");
  try {
    execSync("npx node-pg-migrate -j sql up", { stdio: "inherit" });
    console.log("Migrations complete.");
  } catch (e) {
    console.error("Migration failed:", e);
  }

  // Start background workers
  startIndexer();
  startRelayer();
});
