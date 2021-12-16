// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract BaseBridge is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _mappedTokensCount;
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    mapping(uint256 /* ID */ => MapDetail) public tokenPairs;

    event MapRequest(address indexed token0, address indexed token1, uint256 token0ChainId, uint256 token1ChainId);
    event TokenMapped(uint indexed id, address indexed token0, address indexed token1, uint256 token0ChainId, uint256 token1ChainId);

    struct MapDetail {
        uint256 id;
        address token0;
        address token1;
        uint256 token0ChainId;
        uint256 token1ChainId;
    }

    function initialize() external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MODERATOR_ROLE, _msgSender());
    }

    receive() external payable {
        revert("BaseBridge: ETHER deposit not allowed");
    }

    function submitMapRequest(address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId) external whenNotPaused {
        require(_validateTokens(_token0, _token1, _token0ChainId, _token1ChainId));
        emit MapRequest(_token0, _token1, _token0ChainId, _token1ChainId);
    }

    function executeMapRequest(bytes calldata _data) external onlyRole(MODERATOR_ROLE) whenNotPaused {
        (address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId) = abi.decode(_data, (address, address, uint256, uint256));
        require(_validateTokens(_token0, _token1, _token0ChainId, _token1ChainId));
        uint256 _id = _mappedTokensCount.current();
        _mappedTokensCount.increment();
        emit TokenMapped(_id, _token0, _token1, _token0ChainId, _token1ChainId);
        tokenPairs[_id] = MapDetail(_id, _token0, _token1, _token0ChainId, _token1ChainId);
    }



    // Helpers functions
    function _isContract(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _validateTokens(address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId) private view returns(bool) {
        require(_isContract(_token0) && _isContract(_token1), "BaseBridge: Invalid token addresses received");
        require(_token0ChainId > 0 && _token1ChainId > 0, "BaseBridge: Invalid chainIds received");
        return true;
    }

    function encodeData(address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId) external pure returns(bytes memory _data) {
        _data = abi.encode(_token0, _token1, _token0ChainId, _token1ChainId);
        return _data;
    }
}