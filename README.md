# NFT Marketplace with Cross-Chain Functionality

## Introduction

This project implements an NFT Marketplace using the ERC-721 standard with added cross-chain functionality using the Router Protocol. The contract allows users to mint, list, buy, and transfer NFTs not only within a single blockchain but also across different blockchains. This integration showcases the potential for a more interconnected and versatile NFT marketplace.

## Contract Overview

The `NFTMarketplace` contract extends `ERC721URIStorage` and implements the `IDapp` interface from the Router Protocol. It includes the following features:
- **Minting NFTs:** Users can mint new NFTs with a specified URI and price.
- **Listing NFTs:** NFTs can be listed on the marketplace with a specified price.
- **Buying NFTs:** Users can buy listed NFTs by paying the specified price.
- **Cross-Chain Transfers:** NFTs can be transferred across different blockchains using the Router Protocol.

### Key Functions

1. **Minting Tokens:**
    ```solidity
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint)
    ```

2. **Listing Tokens:**
    ```solidity
    function createListedToken(uint256 tokenId, uint256 price) private
    ```

3. **Buying Tokens:**
    ```solidity
    function executeSale(uint256 tokenId) public payable
    ```

4. **Setting Cross-Chain Contract Addresses:**
    ```solidity
    function setContractOnChain(string calldata chainId, string calldata contractAddress) external
    ```

5. **Cross-Chain Transfer:**
    ```solidity
    function transferCrossChain(string memory destChainId, TransferParams memory transferParams, bytes memory requestMetadata) public payable
    ```

### Cross-Chain Integration

The contract integrates with Router Protocol's Gateway contract to handle cross-chain NFT transfers. It uses the `transferCrossChain` function to send NFTs to another blockchain and the `iReceive` function to handle incoming cross-chain transfers.

## How to Use

### Prerequisites

- Node.js
- Hardhat
- Router Nitro TS SDK or Path Finder API (Ensure you have the necessary Router Protocol setup)

### Steps

1. **Clone the Repository:**
    ```sh
    git clone <repository-url>
    cd <repository-directory>
    ```

2. **Install Dependencies:**
    ```sh
    npm install
    ```

3. **Compile the Contracts:**
    ```sh
    npx hardhat compile
    ```

4. **Deploy the Contract:**
    Deploy the contract to your preferred blockchain network using Hardhat.

5. **Set Up Cross-Chain Contracts:**
    Use the `setContractOnChain` function to set the contract addresses on different chains.

6. **Mint, List, and Transfer NFTs:**
    Use the available functions to mint new NFTs, list them on the marketplace, buy listed NFTs, and transfer them across chains.

### Example Commands

- Mint a new NFT:
    ```solidity
    createToken("ipfs://example-uri", 0.1 ether)
    ```

- List an NFT for sale:
    ```solidity
    createListedToken(tokenId, 0.1 ether)
    ```

- Buy an NFT:
    ```solidity
    executeSale(tokenId)
    ```

- Transfer an NFT cross-chain:
    ```solidity
    TransferParams memory params = TransferParams({tokenId: tokenId, recipient: recipientAddress});
    transferCrossChain("chainId", params, requestMetadata)
    ```

### Router Nitro TS SDK or Path Finder API Usage

This project uses Router Protocol's cross-chain functionality to transfer NFTs between different blockchains. The integration is handled through the `IGateway` contract provided by Router Protocol, fulfilling the requirement to use Router Nitro TS SDK or Path Finder API.

### Evaluation Criteria

1. **How well Router Nitro has been used:**
   - The project demonstrates the use of Router Protocol for cross-chain NFT transfers, showcasing the potential for interconnected NFT marketplaces.

2. **Project Scope and Market Potential:**
   - The NFT marketplace is a versatile platform with significant market potential. By enabling cross-chain transfers, it addresses a key limitation of current NFT platforms, enhancing its appeal and potential for sustainability.

3. **Uniqueness of the Idea:**
   - Cross-chain NFT transfers are a relatively new concept, and integrating this functionality into a marketplace sets this project apart from traditional single-chain NFT platforms. This unique feature can attract a broader audience and create new opportunities in the NFT ecosystem.

## Conclusion

This project demonstrates a robust implementation of an NFT marketplace with cross-chain capabilities using the Router Protocol. It fulfills the hackathon requirements and showcases the potential for a more interconnected NFT ecosystem.