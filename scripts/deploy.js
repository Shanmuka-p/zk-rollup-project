const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Starting deployment on local network...");

  // 1. Deploy the StubZKVerifier
  const StubVerifier = await hre.ethers.getContractFactory("StubZKVerifier");
  const verifier = await StubVerifier.deploy();
  await verifier.waitForDeployment();
  const verifierAddress = await verifier.getAddress();
  console.log(`StubZKVerifier deployed to: ${verifierAddress}`);

  // 2. Deploy ZKRollupPayments, passing the verifier address
  const ZKRollup = await hre.ethers.getContractFactory("ZKRollupPayments");
  const rollup = await ZKRollup.deploy(verifierAddress);
  await rollup.waitForDeployment();
  const rollupAddress = await rollup.getAddress();
  console.log(`ZKRollupPayments deployed to: ${rollupAddress}`);

  // 3. Set deployer as initial relayer
  const [deployer] = await hre.ethers.getSigners();
  const tx = await rollup.addRelayer(deployer.address);
  await tx.wait();
  console.log(`Added deployer (${deployer.address}) as initial relayer.`);

  // 4. Write deployment data to addresses.json
  const deploymentsDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  const deploymentData = {
    network: hre.network.name,
    chainId: hre.network.config.chainId,
    rpcUrl: "http://hardhat:8545", // Docker network URL as requested
    ZKRollupPayments: rollupAddress,
    StubZKVerifier: verifierAddress,
    deployedAt: new Date().toISOString()
  };

  fs.writeFileSync(
    path.join(deploymentsDir, "addresses.json"),
    JSON.stringify(deploymentData, null, 2)
  );
  
  console.log("Deployment addresses written to deployments/addresses.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});