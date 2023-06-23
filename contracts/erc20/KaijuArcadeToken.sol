// SPDX-License-Identifier: MIT
/// @author: kaiju3d.com

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/OwnableAccess.sol";

contract KaijuArcadeToken is ERC20, OwnableAccess {
    constructor(
        address owner
    ) ERC20("Kaiju Arcade Token", "KARC") OwnableAccess(owner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
