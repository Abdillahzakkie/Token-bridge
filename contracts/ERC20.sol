// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MyToken is Initializable, ERC20Upgradeable {
    function initialize() external initializer {
        super.__ERC20_init("MyToken", "MYT");
        super._mint(_msgSender(), 100_000_000 ether);
    }
}