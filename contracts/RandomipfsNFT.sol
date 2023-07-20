// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "base64-sol/base64.sol";

error RandomNft__RangeOutOfBounds();
error RandomNft__NeedMoreETHSent();
error RandomNft__TransferFailed();

/**
 * @title A hybid smart contrat for a random NFT creation with svg images stored on-chain
 * @author Gabriel ANDREI
 * @notice This contract is a demo built in my training process, based on knowledge gained from Patrick Collins
 */

contract RandomNFT is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    enum Category {
        One,
        Two,
        Three
    }
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // NFT Variables
    uint256 private immutable i_mintFee;
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_TokenUris;

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Category category, address minter);

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // also known as keyHash
        uint256 mintFee,
        uint32 callbackGasLimit,
        string[] memory TokenUris
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Random NFT Gabriel", "GBL") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_mintFee = mintFee;
        i_callbackGasLimit = callbackGasLimit;
        //s_TokenUris = TokenUris; //is kind of a metadata for each category, 3 in total
        s_tokenCounter = 0;
        s_TokenUris = _initializeTokenURI(TokenUris);
    }

    function _initializeTokenURI(
        string[] memory imgURIs
    ) private pure returns (string[] memory) {
        string[] memory newArray = new string[](imgURIs.length);
        for (uint256 i = 0; i < imgURIs.length; i++) {
            string memory transformedItem = svgToImageURI(imgURIs[i]);
            string memory transformedItem2 = formatTokenURI(transformedItem);
            newArray[i] = transformedItem2;
        }
        return newArray;
    }

    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        // example:
        // <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
        // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI(
        string memory imageURI
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "SVG NFT", // You can add whatever name here
                                '", "description":"An NFT based on SVG!", "attributes":"whatever", "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomNft__NeedMoreETHSent();
        }
        //generates a random number
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        //associate that random number to the sender
        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address Owner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;

        //transform randomWords in a number between 0-99
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        // based un the resulted number above, the function below will generate a Category(0-type1,1-type2,3-type3)
        Category resultedNumber = getCategoryFromModdedRng(moddedRng);
        s_tokenCounter++;
        //create nft
        _safeMint(Owner, newTokenId);
        //set the TokenURI, that means some RANDOM features: Category and an associated image URL
        //remember resultedNumber will be one,two or three but needs to be transform in uint256 (0,1,2)
        _setTokenURI(newTokenId, s_TokenUris[uint256(resultedNumber)]); //  <=> set _setTokenURI( 1, s_TokenUris[0/1/2] )
        emit NftMinted(resultedNumber, Owner);
    }

    function getCategoryFromModdedRng(
        uint256 moddedRng
    ) public pure returns (Category) {
        //based on input number(0-99) and based on the array of changes, this function returns the category
        //on which belong (0, 1 or 2)
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            // Category1 = 0 - 9  (10%)
            // Category2 = 10 - 39  (30%)
            // Category3 = 40 = 99 (60%)
            if (moddedRng >= cumulativeSum && moddedRng < chanceArray[i]) {
                return Category(i);
            }
            cumulativeSum = chanceArray[i];
        }
        revert RandomNft__RangeOutOfBounds();
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomNft__TransferFailed();
        }
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 40, MAX_CHANCE_VALUE];
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getTokenUris(uint256 index) public view returns (string memory) {
        return s_TokenUris[index];
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
