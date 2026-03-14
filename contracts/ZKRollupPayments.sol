// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IZKVerifier.sol";

contract ZKRollupPayments {
    IZKVerifier public verifier;
    bytes32 public currentStateRoot;
    uint256 public batchCount;
    mapping(address => uint256) public deposits;
    mapping(address => bool) public relayers;

    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event BatchCommitted(uint256 indexed batchIndex, bytes32 newStateRoot, bytes32 batchHash, uint256 txCount, address relayer);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _verifier) {
        verifier = IZKVerifier(_verifier);
        currentStateRoot = keccak256(abi.encodePacked("GENESIS"));
    }

    modifier onlyRelayer() {
        require(relayers[msg.sender], "Not an authorized relayer");
        _;
    }

    function addRelayer(address _relayer) external {
        relayers[_relayer] = true;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        deposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value, deposits[msg.sender]);
    }

    function commitBatch(
        bytes32 _newStateRoot,
        bytes32 _batchHash,
        uint256 _txCount,
        bytes calldata _proof,
        uint256[] calldata _publicInputs
    ) external onlyRelayer {
        require(verifier.verifyProof(_proof, _publicInputs), "Invalid ZK Proof");

        currentStateRoot = _newStateRoot;
        batchCount++;

        emit BatchCommitted(batchCount, _newStateRoot, _batchHash, _txCount, msg.sender);
    }

    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
}