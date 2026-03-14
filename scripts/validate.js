const ethers = require('ethers');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const API_BASE = `http://localhost:${process.env.API_PORT || 4000}`;
const RPC_URL = process.env.RPC_URL || 'http://127.0.0.1:8545';

const report = { passed: 0, failed: 0, results: [] };

function recordResult(testName, passed, detail) {
    if (passed) report.passed++;
    else report.failed++;
    report.results.push({ test: testName, status: passed ? "pass" : "fail", detail });
    console.log(`[${passed ? 'PASS' : 'FAIL'}] ${testName} - ${detail}`);
}

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function main() {
    console.log("Starting End-to-End System Validation...\n");

    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const userWallet = new ethers.Wallet(process.env.USER_A_PRIVATE_KEY, provider);
    
    // Get contract address from deployments
    const addressesPath = path.join(__dirname, '../deployments/addresses.json');
    if (!fs.existsSync(addressesPath)) throw new Error("Deployments file not found");
    const { ZKRollupPayments } = JSON.parse(fs.readFileSync(addressesPath));

    const contract = new ethers.Contract(
        ZKRollupPayments, 
        ["function deposit() external payable"], 
        userWallet
    );

    try {
        // Test 1: Deposit ETH
        console.log("1. Depositing 0.5 ETH...");
        const depositAmount = ethers.parseEther("0.5");
        const tx = await contract.deposit({ value: depositAmount });
        await tx.wait();
        recordResult("Deposit ETH", true, `Deposited 0.5 ETH in tx: ${tx.hash}`);

        // Test 2: Poll Indexer for Deposit
        console.log("2. Waiting for Indexer to catch deposit...");
        let indexed = false;
        for (let i = 0; i < 15; i++) {
            const res = await fetch(`${API_BASE}/deposits/${userWallet.address}`);
            if (res.ok) {
                const data = await res.json();
                if (BigInt(data.balanceWei) >= depositAmount) {
                    indexed = true;
                    break;
                }
            }
            await sleep(2000);
        }
        recordResult("Index Deposit", indexed, indexed ? "Deposit found in database" : "Deposit not indexed in time");

        // Test 3: Valid Intent
        console.log("3. Submitting valid intent...");
        const validRes = await fetch(`${API_BASE}/intents`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                fromAddress: userWallet.address,
                toAddress: process.env.USER_B_ADDRESS || "0x123",
                amountWei: ethers.parseEther("0.1").toString()
            })
        });
        recordResult("Valid Intent", validRes.status === 201, `Status code: ${validRes.status}`);

        // Test 4: Invalid Intent
        console.log("4. Submitting invalid intent (999 ETH)...");
        const invalidRes = await fetch(`${API_BASE}/intents`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                fromAddress: userWallet.address,
                toAddress: "0x123",
                amountWei: ethers.parseEther("999").toString()
            })
        });
        recordResult("Invalid Intent", invalidRes.status === 400, `Rejected correctly with status: ${invalidRes.status}`);

        // Test 5: Wait for Relayer Batch
        console.log("5. Waiting for Relayer to batch intents (up to 30s)...");
        let batched = false;
        for (let i = 0; i < 15; i++) {
            const stateRes = await fetch(`${API_BASE}/state`);
            if (stateRes.ok) {
                const state = await stateRes.json();
                if (state.batchCount > 0) {
                    batched = true;
                    break;
                }
            }
            await sleep(2000);
        }
        recordResult("Relayer Batching", batched, batched ? "Batch committed on-chain" : "Relayer failed to batch in time");

        // Test 6: Verify API /batches
        const batchesRes = await fetch(`${API_BASE}/batches`);
        const batchesData = await batchesRes.json();
        recordResult("Batch Explorer API", batchesData.batches.length > 0, `Found ${batchesData.batches.length} batches in DB`);

    } catch (error) {
        console.error("Validation script failed critically:", error);
    } finally {
        fs.writeFileSync(path.join(__dirname, '../validation_report.json'), JSON.stringify(report, null, 2));
        console.log("\nValidation complete. Report written to validation_report.json");
    }
}

main();