// SPDX-License-Identifier: GPL-3.0
/// @author: kaiju3d.com
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKaijuArcade2048 is IERC721 {
    function safeMint(address to, string memory uri) external;
}
