// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IDapp.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";

contract NFTMarketplace is ERC721URIStorage, IDapp {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address payable owner;
    uint256 listPrice = 0.00001 ether;
    IGateway public gatewayContract;
    mapping(string => string) public ourContractOnChains;

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    mapping(uint256 => ListedToken) private idToListedToken;

    constructor(address payable gatewayAddress, string memory feePayerAddress) ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
        gatewayContract = IGateway(gatewayAddress);
        gatewayContract.setDappMetadata(feePayerAddress);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createListedToken(newTokenId, price);
        return newTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        require(msg.value == listPrice, "Hopefully sending the correct price");
        require(price > 0, "Make sure the price isnt negative");

        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        _transfer(msg.sender, address(this), tokenId);

        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            true
        );
    }

    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        uint currentId;

        for(uint i = 0; i < nftCount; i++) {
            currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return tokens;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;

        for(uint i = 0; i < totalItemCount; i++) {
            if(idToListedToken[i + 1].owner == msg.sender || idToListedToken[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i = 0; i < totalItemCount; i++) {
            if(idToListedToken[i + 1].owner == msg.sender || idToListedToken[i + 1].seller == msg.sender) {
                currentId = i + 1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idToListedToken[tokenId].currentlyListed = false;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);

        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }

    function setContractOnChain(string calldata chainId, string calldata contractAddress) external {
        require(msg.sender == owner, "only owner");
        ourContractOnChains[chainId] = contractAddress;
    }

    struct TransferParams {
        uint256 tokenId;
        address recipient;
    }

    function transferCrossChain(string memory destChainId, TransferParams memory transferParams, bytes memory requestMetadata) public payable {
        require(keccak256(bytes(ourContractOnChains[destChainId])) != keccak256(bytes("")), "contract on dest not set");

        _burn(transferParams.tokenId);

        bytes memory packet = abi.encode(transferParams);
        bytes memory requestPacket = abi.encode(ourContractOnChains[destChainId], packet);

        gatewayContract.iSend{ value: msg.value }(1, 0, "", destChainId, requestMetadata, requestPacket);
    }

    function getRequestMetadata(uint64 destGasLimit, uint64 destGasPrice, uint64 ackGasLimit, uint64 ackGasPrice, uint128 relayerFees, uint8 ackType, bool isReadCall, bytes memory asmAddress) public pure returns (bytes memory) {
        bytes memory requestMetadata = abi.encodePacked(destGasLimit, destGasPrice, ackGasLimit, ackGasPrice, relayerFees, ackType, isReadCall, asmAddress);
        return requestMetadata;
    }

    function iReceive(string calldata requestSender, bytes calldata packet, string calldata srcChainId) external override returns (bytes memory) {
        require(msg.sender == address(gatewayContract), "only gateway");
        require(keccak256(bytes(ourContractOnChains[srcChainId])) == keccak256(bytes(requestSender)), "invalid sender");

        TransferParams memory transferParams = abi.decode(packet, (TransferParams));
        _safeMint(transferParams.recipient, transferParams.tokenId);
        return "";
    }

    function iAck(uint256 requestIdentifier, bool execFlag, bytes memory execData) external override {}

    function setGateway(address gateway) external {
        require(msg.sender == owner, "only owner");
        gatewayContract = IGateway(gateway);
    }

    function setDappMetadata(string memory feePayerAddress) external {
        require(msg.sender == owner, "only owner");
        gatewayContract.setDappMetadata(feePayerAddress);
    }
}
