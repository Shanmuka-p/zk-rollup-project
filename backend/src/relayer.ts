import { ethers } from "ethers";
import { db, rollupContract, provider } from "./config";

export function startRelayer() {
  console.log("Starting Relayer worker (runs every 15s)...");

  // Connect a wallet using the relayer private key
  const privateKey = process.env.RELAYER_PRIVATE_KEY;
  if (!privateKey) {
    console.error("RELAYER_PRIVATE_KEY is missing in .env");
    return;
  }
  const wallet = new ethers.Wallet(privateKey, provider);
  const contractWithSigner = rollupContract.connect(wallet) as ethers.Contract;

  setInterval(async () => {
    try {
      // 1. Fetch up to 10 pending intents
      const res = await db.query(
        `SELECT * FROM payment_intents WHERE status = 'pending' LIMIT 10`,
      );
      const intents = res.rows;

      if (intents.length === 0) return; // Nothing to batch

      console.log(`[RELAYER] Processing ${intents.length} pending intents...`);

      // 2. Compute Hashes
      const currentStateRoot = await contractWithSigner.currentStateRoot();

      // Concatenate intent IDs and hash them
      const concatenatedIds = intents.map((i) => i.id).join("");
      const batchHash = ethers.keccak256(ethers.toUtf8Bytes(concatenatedIds));

      // Simulate Merkle root update: keccak256(currentStateRoot + batchHash)
      const newStateRoot = ethers.solidityPackedKeccak256(
        ["bytes32", "bytes32"],
        [currentStateRoot, batchHash],
      );

      // 3. Submit to Layer 1
      const tx = await contractWithSigner.commitBatch(
        newStateRoot,
        batchHash,
        intents.length,
        "0x00", // Dummy proof for our stub
        [], // Dummy public inputs
      );

      const receipt = await tx.wait();

      // 4. Update Database on Success
      const intentIds = intents.map((i) => i.id);
      await db.query(
        `UPDATE payment_intents SET status = 'batched' WHERE id = ANY($1::uuid[])`,
        [intentIds],
      );

      await db.query(
        `INSERT INTO batches (new_state_root, batch_hash, tx_count, relayer_address) 
                 VALUES ($1, $2, $3, $4)`,
        [newStateRoot, batchHash, intents.length, wallet.address],
      );

      console.log(
        `[RELAYER] Batch committed successfully in tx: ${receipt.hash}`,
      );
    } catch (error) {
      console.error("[RELAYER] Failed to commit batch:", error);
      // If it fails, we should ideally mark these intents as 'failed', but for simplicity
      // in this simulated environment, we'll let the error log and catch it on the next run.
    }
  }, 15000); // 15 seconds
}
