// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // enables metadata
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; // allows contract to be burned
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WhiteStoneCollection is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string constant duURI =
        "ipfs://bafybeiaphdnvoz5vml3fgtxg4kek22i3lf6nbozs52q5mjml24caumtpn4";

    constructor() ERC721("The WhiteStone Collection", "WS") {}

    // The following two functions are required by Solidity to be overridden for multiple inheritance.
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function safeMint(address to) public onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, duURI);

        return newItemId;
    }

    function contractURI() public pure returns (string memory) {
        return
            "ipfs://bafybeidxgpwlek3pmljtyanni3xcxm33xor4p5hldhwinv7e2rtujkzeje";
    }
}
