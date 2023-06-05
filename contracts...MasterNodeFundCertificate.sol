// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MasterNodeFundCertificate is ERC721 {
    constructor() ERC721("MasterNodeFundCertificate", "MNFC") {
    }

    function mint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
    }
}