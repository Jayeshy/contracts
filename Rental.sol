// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rental is Ownable(msg.sender), ERC721URIStorage, ReentrancyGuard {
    uint256 nextTokenId;

    constructor() ERC721("Rental Property", "PROPERTY") {
        nextTokenId = 0;
    }

    struct Property {
        address owner;
        uint256 tokenId;
        string tokenUri;
        uint256 pricePerUnitTime;
        uint256 minimumTime;
        uint256 maximumTime;
        uint256 depositMoney;
    }

    struct Agreement {
        uint256 tokenId;
        address owner;
        address tenant;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 amount;
        uint256 depositMoney;
    }

        struct AgreementRequest {
        uint256 tokenId;
        address owner;
        address tenant;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 amount;
        uint256 depositMoney;
        bool    isRentPaid;
    }

    mapping(uint256 => Property) public properties;
    mapping(uint256 => Agreement) public agreements;
    mapping (uint256 => AgreementRequest) public agreementRequests;

    event PropertyMinted(uint256 tokenId, address owner, string indexed tokenURI);


    function mintProperty(string memory _tokenUri, uint256 pricePerUnitTime, uint256 minimumTime, uint256 maximumTime, uint256 depositMoney) external onlyOwner {
        uint256 tokenId = nextTokenId++;
        Property memory property = Property({owner: msg.sender, tokenId: tokenId, tokenUri: _tokenUri, pricePerUnitTime: pricePerUnitTime, minimumTime:minimumTime, maximumTime: maximumTime, depositMoney: depositMoney});
        properties[tokenId] = property;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenUri);
    }

    function createAgreementRequest(uint256 _tokenId, address _tenant, uint256 startTimestamp, uint256 endTimestamp) public payable {
        Property memory property = properties[_tokenId];
        require(msg.sender == property.owner, "Only owner can create agreement!");
        require(startTimestamp>= block.timestamp, "Incorrect time!");
        require(endTimestamp > block.timestamp, "Invalid time!");
        uint256 duration  = property.pricePerUnitTime;
        require(duration>= property.minimumTime, "Select the time period greater than mentioned by owner!");
        require(duration<= property.maximumTime, "Select the time period less than mentioned by owner!");
        uint256 amount = (endTimestamp-startTimestamp)* duration;
        AgreementRequest memory agreementRequest = AgreementRequest({tokenId: _tokenId, owner: property.owner, tenant: _tenant, startTimestamp: startTimestamp, endTimestamp: endTimestamp, amount: amount, depositMoney: property.depositMoney, isRentPaid: false});
        agreementRequests[_tokenId] = agreementRequest;
    }

    function confirmAgreementAndPayRent(uint256 _tokenId) public payable {
        AgreementRequest storage agreementRequest = agreementRequests[_tokenId];
        require(msg.sender == agreementRequest.tenant, "Only the specified tenant can confirm the agreement!");
        require(msg.value == agreementRequest.amount+ agreementRequest.depositMoney, "Invalid amount!");
        require(!agreementRequest.isRentPaid, "Rent is already paid!");

        agreementRequest.isRentPaid = true;

        agreements[_tokenId] = Agreement({
            tokenId: agreementRequest.tokenId,
            owner: agreementRequest.owner,
            tenant: agreementRequest.tenant,
            startTimestamp: agreementRequest.startTimestamp,
            endTimestamp: agreementRequest.endTimestamp,
            amount: agreementRequest.amount,
            depositMoney: agreementRequest.depositMoney
        });

        payable(agreementRequest.owner).transfer(agreementRequest.amount);
    }
}


