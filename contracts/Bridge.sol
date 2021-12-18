// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "hardhat/console.sol";

contract Bridge is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    // using CountersUpgradeable for CountersUpgradeable.Counter;
    // CountersUpgradeable.Counter private _mappedTokensCount;
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 public  CHAIN_ID;

    mapping(uint256 /* ID */ => MapDetail) public tokenPairs;
    mapping(uint256 /* chain ID */ => bool /* status */) public supportedChains;

    event TokenMapRequest(address indexed token0, address indexed token1, uint256 token0ChainId, uint256 token1ChainId, string email);
    event TokenMapped(uint indexed id, address indexed token0, address indexed token1, uint256 token0ChainId, uint256 token1ChainId, string email);
    event NewChainRegistered(address moderator, uint256 indexed chainId);

    struct MapDetail {
        uint256 id;
        address token0;
        address token1;
        uint256 token0ChainId;
        uint256 token1ChainId;
    }

    function initialize(address _moderator) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MODERATOR_ROLE, _msgSender());
        _grantRole(MODERATOR_ROLE, _moderator);
        CHAIN_ID = block.chainid;
    }

    receive() external payable {
        revert("Bridge: ETHER deposit not allowed");
    }

    function submitMapRequest(address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId, string memory _email) external whenNotPaused {
        require(_validateTokens(_token0, _token1, _token0ChainId, _token1ChainId));
        emit TokenMapRequest(_token0, _token1, _token0ChainId, _token1ChainId, _email);
    }

    function executeMapRequest(bytes calldata _data) external onlyRole(MODERATOR_ROLE) whenNotPaused {
        (address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId, string memory _email) = abi.decode(_data, (address, address, uint256, uint256, string));
        require(_validateTokens(_token0, _token1, _token0ChainId, _token1ChainId));
        uint256 _id = _generateId(_token0, _token1);
        emit TokenMapped(_id, _token0, _token1, _token0ChainId, _token1ChainId, _email);
        tokenPairs[_id] = MapDetail(_id, _token0, _token1, _token0ChainId, _token1ChainId);
    }

    function addNewChain(uint256 _chainId) public onlyRole(MODERATOR_ROLE) {
        require(_chainId > 0, "Bridge: Invalid chain ID");
        supportedChains[_chainId] = true;
        emit NewChainRegistered(_msgSender(), _chainId);
    }

    // Helpers functions
    function _isContract(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _validateTokens(address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId) private view returns(bool _status) {
        require(tokenPairs[_generateId(_token0, _token1)].token0 == address(0), "Bridge: Tokens has already been mapped");
        require(_isContract(_token0) && _isContract(_token1), "Bridge: Invalid token addresses received");
        require(_token0ChainId > 0 && _token1ChainId > 0, "Bridge: Invalid chainIds received");
        require(supportedChains[_token0ChainId] && supportedChains[_token1ChainId], "Bridge: Invalid chain IDs received");
        require(_token0ChainId == CHAIN_ID || _token1ChainId == CHAIN_ID, "Bridge: _token0ChainId | _token1ChainId must equal base chainId (CHAIN_ID)");
        require(_token0ChainId != _token1ChainId, "Bridge: Can not bridge tokens on the same chain");
        return true;
    }

    function encodeData(address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId) external pure returns(bytes memory) {
        return abi.encode(_token0, _token1, _token0ChainId, _token1ChainId);
    }

    function _generateId(address _token0, address _token1) internal pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_token0, _token1)));
    }
}