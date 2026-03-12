import { rollupContract, db } from "./config";

export function startIndexer() {
  console.log("Starting Indexer to listen for on-chain events...");

  rollupContract.on("Deposited", async (user, amount, newBalance, event) => {
    try {
      const txHash = event.log.transactionHash;
      const blockNumber = event.log.blockNumber;

      await db.query(
        `INSERT INTO deposits (user_address, amount_wei, tx_hash, block_number) 
                 VALUES ($1, $2, $3, $4)`,
        [user, amount.toString(), txHash, blockNumber],
      );
      console.log(
        `[INDEXER] Indexed Deposit: ${user} - ${amount.toString()} wei`,
      );
    } catch (error) {
      console.error("[INDEXER] Error indexing deposit:", error);
    }
  });

  rollupContract.on(
    "BatchCommitted",
    async (batchIndex, newStateRoot, batchHash, txCount, relayer, event) => {
      try {
        const txHash = event.log.transactionHash;

        // Upsert the batch record and mark it as committed
        await db.query(
          `UPDATE batches SET 
                 committed_at = NOW(), tx_hash = $1 
                 WHERE batch_hash = $2`,
          [txHash, batchHash],
        );
        console.log(`[INDEXER] Indexed BatchCommitted: Index ${batchIndex}`);
      } catch (error) {
        console.error("[INDEXER] Error indexing batch:", error);
      }
    },
  );

  rollupContract.on("Withdrawn", (user, amount) => {
    console.log(`[WITHDRAW] address=${user} amount=${amount.toString()}`);
  });
}
