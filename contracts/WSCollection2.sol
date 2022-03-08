// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract WhiteStoneCollection is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string constant duURI =
        "ipfs://bafybeiaphdnvoz5vml3fgtxg4kek22i3lf6nbozs52q5mjml24caumtpn4";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("The WhiteStone Collection", "WS");
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function safeMint(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();

        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, duURI);

        return newItemId;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function contractURI() public pure returns (string memory) {
        return
            "ipfs://bafybeidxgpwlek3pmljtyanni3xcxm33xor4p5hldhwinv7e2rtujkzeje";
    }
}
