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

    mapping(uint256 /* ID */ => mapping(address /* token0 */ => address/* token1 */)) public tokenPairs;

    event MapRequest(address indexed token0, address indexed token1, uint256 token0ChainId, uint256 token1ChainId);

    function initialize() external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MODERATOR_ROLE, _msgSender());
    }

    receive() external payable {
        revert("BaseBridge: ETHER deposit not allowed");
    }

    function submitTokenMap(address _token0, address _token1, uint256 _token0ChainId, uint256 _token1ChainId) external whenNotPaused {
        require(_isContract(_token0) && _isContract(_token1), "BaseBridge: Invalid token addresses received");
        require(_token0ChainId > 0 && _token1ChainId > 0, "BaseBridge: Invalid chainIds received");
        emit MapRequest(_token0, _token1, _token0ChainId, _token1ChainId);
    }

    function _isContract(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}