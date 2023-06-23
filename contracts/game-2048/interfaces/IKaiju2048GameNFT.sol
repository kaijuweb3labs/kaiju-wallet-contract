// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKaiju2048GameNFT is IERC721 {
    function safeMint(address to, string memory uri) external;
}
