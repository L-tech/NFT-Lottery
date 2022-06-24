//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./utils/Base64.sol";

contract NftLottery is ERC721URIStorage, Ownable, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    enum LOTTERY_STATE { OPEN, CLOSED }
    LOTTERY_STATE public lottery_state;
    uint64 public ticketFee;
    uint32 public maxPlayers;
    uint256 luckyWinnerIndex;
    address payable[] public players;
    mapping(address => uint8) public holderTokendIds;
    uint256 public totalFee;
    uint64 public subscriptionId;
    uint256 public requestId;
    uint256[] public s_randomWords;


    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 s_keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;




    constructor(uint64 _ticketFee, uint32 _maxPlayers, uint64 _subscriptionId) ERC721("Anya NFT Lottery", "ANLOT") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        ticketFee = _ticketFee;
        maxPlayers = _maxPlayers;
        subscriptionId = _subscriptionId;
        _tokenIds.increment();

    }

    function mint() external payable {
        require(uint256(lottery_state) == 0, "lottery session is closed");
        require(
            _tokenIds.current() <= maxPlayers,
            "Maximum Numbers of Players Reached"
        );
        require(
            msg.value >= ticketFee,
            "Insufficient Ticket Fee"
        );
        require(
            getTokenId(msg.sender) == 0,
            "Ticket can be minted just once"
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "ANLOT Ticket #',
                        Strings.toString(_tokenIds.current()),
                        '", "description": "A Special Lottery Ticket based on NFT to stand a chance to win a prize", ',
                        '"traits": [{ "trait_type": "Mode", "value": "Lottery" }, { "trait_type": "Winner", "value": "false" }, {"trait_type": "Probabilty", "value": "low"}], ',
                        '"image": "ipfs://QmbjZ7WbZxindsERkShaf6yoGo4VyQAdnedQopZ5zgLuMe" }'
                        )
                    )
            )
        );
        string memory tokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        _safeMint(msg.sender, _tokenIds.current());
        _setTokenURI(_tokenIds.current(), tokenURI);
        totalFee += msg.value;
        players.push(payable(msg.sender));
        _tokenIds.increment();
    }


    function changeLotteryState(LOTTERY_STATE _state) external onlyOwner {
        lottery_state = _state;
    }

    function getTokenId(address _address) public view returns(uint256) {
        return holderTokendIds[_address];
    }

    function getLuckyWinner() external {
        requestId = COORDINATOR.requestRandomWords(
        s_keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
       );
    }

    function fulfillRandomWords(uint256 requestId , uint256[] memory randomWords) internal override {
        // transform the result to a number between 1 and Max players count inclusively
        luckyWinnerIndex = (randomWords[0] % _tokenIds.current()) + 1;
    }


    function awardLuckyWinner() external onlyOwner {
        require(requestId != 0, "randomness not initiated");
        require(uint256(lottery_state) == 1, "lottery session is still opened");
        address payable winner = players[luckyWinnerIndex-1];
        (bool sent, bytes memory data) = winner.call{value: totalFee}("");
        require(sent, "Failed to send Ether");
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "ANLOT Ticket #',
                        Strings.toString(luckyWinnerIndex),
                        '", "description": "Winner Of The Special Lottery Ticket based on NFT by Anya", ',
                        '"traits": [{ "trait_type": "Mode", "value": "Lottery" }, { "trait_type": "Winner", "value": "true" }, {"trait_type": "Probabilty", "value": "low"}], ',
                        '"image": "ipfs://QmbjZ7WbZxindsERkShaf6yoGo4VyQAdnedQopZ5zgLuMe" }'
                        )
                    )
            )
        );
        string memory tokenURI = string(
                abi.encodePacked("data:application/json;base64,", json)
            );
        _setTokenURI(luckyWinnerIndex, tokenURI);
        totalFee = 0;
    }
}