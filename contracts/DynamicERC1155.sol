// contracts/PartyCollection.sol
// SPDX-License-Identifier: MIT
// Written by white8785 @ twitter
// October 2021

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Contract that creates fungible, and non-fungible tokens to
 * the Ethereum blockchain.
 *
 * By default, the owner will be the one that deploys the contract.  This
 * can be changed by with {trasnferOwnership}.
 *
 */
/// @title Project Pool Party Collection
/// @custom:security-contact poolpartycoin@protonmail.com
contract PoolPartyCollection is ERC1155, Ownable, Pausable, ERC1155Burnable {
    // tokenId -> URI
    mapping(uint256 => string) private _uris;
    // tokenId -> max_supply
    mapping(uint256 => uint256) public tokenMaxSupply;
    // tokenId -> total_supply
    mapping(uint256 => uint256) public tokenSupply;

    string private _contractURI =
        "ContractURI not configured.  See {setContractURI}";

    // Duplicated events is how optional params work in Solidity. <facepalm>
    event ContractURILoggingEvent(string log);
    event ContractURILoggingEvent(string log, string data);
    event TokenURILoggingEvent(string log, uint256 newURI, string data);
    event MaxSupplyLoggingEvent(uint256 id, uint256 maxSupply);
    event ContractLoggingEvent(string log);
    event ContractLoggingEvent(
        address to,
        uint256 id,
        uint256 amount,
        string data
    );

    event MintLoggingEvent(address to, uint256 id, uint256 amount, string data);
    event MintLoggingEvent(
        address to,
        uint256[] ids,
        uint256[] amounts,
        string data
    );

    constructor() ERC1155("") {
        tokenMaxSupply[1] = 333; // RSVPs
        tokenMaxSupply[2] = 333;
        // mint(msg.sender, 1, 333, "");
    }

    /// Owner Functions ///

    /**
     * @dev Updates the contractURI
     */
    function setContractURI(string memory _newcontractURI) public onlyOwner {
        _contractURI = _newcontractURI;
        emit ContractURILoggingEvent("ContractURI set.", _newcontractURI);
    }

    /**
     * @dev Updates the tokenURI for a given tokenId
     */
    function setTokenUri(uint256 tokenId, string memory _uri) public onlyOwner {
        _uris[tokenId] = _uri;
        emit TokenURILoggingEvent("TokenURI set.", tokenId, _uri);
    }

    /**
     * @dev Pauses all contract operations
     */
    function pause() public onlyOwner {
        _pause();
        emit ContractLoggingEvent("Contract is paused.");
    }

    /**
     * @dev Unpauses all contract operations
     */
    function unpause() public onlyOwner {
        emit ContractLoggingEvent("Contract is unpaused.");
    }

    /**
     * @dev Sets the tokenId's max supply value.
     */
    function setTokenMaxSupply(uint256 id, uint256 maxSupply) public onlyOwner {
        tokenMaxSupply[id] = maxSupply;
        emit ContractLoggingEvent("Token max supply set.");
        emit MaxSupplyLoggingEvent(id, maxSupply);
    }

    /// Primary Operations ///

    /**
     * @dev Returns the contractURI.
     *
     * NOTE: Required by OpenSea
     */
    function contractURI() public returns (string memory) {
        emit ContractURILoggingEvent("ContractURI requested");
        return _contractURI;
    }

    /**
     * @dev Returns the tokenURI.
     *
     * NOTE: Required by OpenSea
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    /**
     * @dev Creates any amount of tokens for a single tokenId to
     * a single owner as long as the total amount of tokens requested
     * does not exceed the max supply of tokens.
     *
     * @param to Intended token owner's wallet address
     * @param id ID of token to be minted
     * @param amount Number of tokens to mint
     * @param data Data to include in token
     *
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory data
    ) public onlyOwner {
        emit ContractLoggingEvent("Minting started.");
        emit MintLoggingEvent(to, id, amount, data);

        // Fail if token's max supply will be exceeded
        uint256 _requestedtokenSupply = tokenSupply[id] + amount;
        require(
            _requestedtokenSupply <= tokenMaxSupply[id],
            "Requested token amount exceeds token supply"
        );

        _mint(to, id, amount, abi.encode(data));

        // Validate the world is sane and update
        assert(_requestedtokenSupply >= tokenSupply[id]);
        tokenSupply[id] = _requestedtokenSupply;

        emit ContractLoggingEvent("Minting successful.");
    }

    /**
     * @dev Creates any amount of tokens for multiple tokenIds to a
     * single owner as long as the requested amount of tokens
     * doesn't exceed the max supply of said token.
     *
     * @param to Intended token owner's wallet address
     * @param ids List of IDs of tokens to be minted
     * @param amounts List of amounts of tokens to mint
     * @param data Data to include in token
     *
     * NOTE: The 'ids' & 'amounts' lists should match in length.
     *
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string memory data
    ) public onlyOwner {
        emit ContractLoggingEvent("Batch Minting started.");
        emit MintLoggingEvent(to, ids, amounts, data);

        /**
         * For the number of items in the array starting from zero,
         * increment by one, until equal to the total number of items,
         * and ensure tokenSupplies are not exceeded.
         */
        for (uint256 _id = 0; _id <= ids.length - 1; _id++) {
            uint256 _requestedTokenId = ids[_id];
            uint256 _requestedtokenSupply = tokenSupply[_requestedTokenId] +
                amounts[_id];

            require(
                _requestedtokenSupply <= tokenMaxSupply[_requestedTokenId],
                string(
                    abi.encodePacked(
                        "Requested tokenId: ",
                        Strings.toString(_requestedTokenId),
                        " amount: ",
                        Strings.toString(amounts[_id]),
                        " exceeds token supply: ",
                        Strings.toString(tokenMaxSupply[_requestedTokenId])
                    )
                )
            );

            tokenSupply[_requestedTokenId] += amounts[_id];
        }

        // Party Time!
        _mintBatch(to, ids, amounts, abi.encode(data));

        emit ContractLoggingEvent("Batch Minting successful.");
    }

    //    function burn(
    //        address to,
    //        uint256 id,
    //        uint amount
    //        ) override public {
    //            require(to == msg.sender || isApprovedForAll(to, msg.sender),
    //            "ERC1155: The caller is not approved to burn, nor do they own this token."
    //            );
    //
    //            _burn(to, id, amount);
    //        }
}
