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
contract Dynamic1155 is ERC1155, Ownable, Pausable, ERC1155Burnable {
    // tokenId -> URI
    mapping(uint256 => string) private _uris;

    // tokenId -> max_supply
    mapping(uint256 => uint256) public tokenMaxSupply;

    // tokenId -> total_supply
    mapping(uint256 => uint256) public tokenSupply;

    // URI for all assets created under this collection
    string private _contractURI =
        "ContractURI not configured.  Execute {setContractURI}";

    // Define if sale is active
    bool public saleIsActive = true;

    // Max amount of tokens per mint
    uint256 public MAX_PURCHASE = 50;

    // Duplicated events is how optional params work in Solidity. <facepalm>
    event BatchBurnLoggingEvent(
        address account,
        uint256[] ids,
        uint256[] amounts
    );
    event ContractLoggingEvent(string log);
    event ContractLoggingEvent(
        address account,
        uint256 id,
        uint256 amount,
        string data
    );

    event ContractURILoggingEvent(string log);
    event ContractURILoggingEvent(string log, string data);
    event MaxSupplyLoggingEvent(uint256 id, uint256 maxSupply);
    event MintLoggingEvent(
        address account,
        uint256 id,
        uint256 amount,
        string data
    );
    event MintLoggingEvent(
        address account,
        uint256[] ids,
        uint256[] amounts,
        string data
    );

    event TokenURILoggingEvent(string log, uint256 newURI, string data);

    constructor() ERC1155("") {
        tokenMaxSupply[1] = 333; // RSVPs
        tokenMaxSupply[2] = 333;
        // mint(msg.sender, 1, 333, "");
        _uris[0] = "Invalid token";
        _uris[1] = "TokenURI not configured.  See {setTokenURI}.";
    }

    /// Owner Functions ///

    /**
     * @dev Updates the contractURI
     */
    function setContractURI(string memory _newcontractURI)
        external
        onlyOwner
        whenNotPaused
    {
        _contractURI = _newcontractURI;
        emit ContractURILoggingEvent("ContractURI set.", _newcontractURI);
    }

    /**
     * @dev Updates the tokenURI for a given tokenId
     */
    function setTokenUri(uint256 tokenId, string memory _uri)
        external
        onlyOwner
        whenNotPaused
    {
        _uris[tokenId] = _uri;
        emit TokenURILoggingEvent("TokenURI set.", tokenId, _uri);
    }

    /**
     * @dev Pauses all contract operations
     */
    function pause() external onlyOwner {
        _pause();
        emit ContractLoggingEvent("Contract is paused.");
    }

    /**
     * @dev Unpauses all contract operations
     */
    function unpause() external onlyOwner {
        emit ContractLoggingEvent("Contract is unpaused.");
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner whenNotPaused {
        saleIsActive = newState;
    }

    /**
     * @dev Sets the tokenId's max supply value.
     */
    function setTokenMaxSupply(uint256 id, uint256 maxSupply)
        external
        onlyOwner
        whenNotPaused
    {
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
    function contractURI() public view returns (string memory) {
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
     * @param account Intended token owner's wallet address
     * @param id ID of token to be minted
     * @param amount Number of tokens to mint
     * @param data Data to include in token
     *
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        string memory data
    ) public onlyOwner whenNotPaused {
        require(saleIsActive, "Minting is closed");

        emit ContractLoggingEvent("Minting started.");
        emit MintLoggingEvent(account, id, amount, data);

        // Fail if token's max supply will be exceeded
        uint256 _requestedtokenSupply = tokenSupply[id] + amount;
        require(
            _requestedtokenSupply <= tokenMaxSupply[id],
            "Requested token amount exceeds token supply"
        );

        // Validate the world is sane and update
        assert(_requestedtokenSupply >= tokenSupply[id]);
        tokenSupply[id] = _requestedtokenSupply;

        // Complete transaction
        _mint(account, id, amount, abi.encode(data));

        // Flex on the haters
        emit ContractLoggingEvent("Minting successful.");
    }

    /**
     * @dev Creates any amount of tokens for multiple tokenIds to a
     * single owner as long as the requested amount of tokens
     * doesn't exceed the max supply of said token.
     *
     * @param account Intended token owner's wallet address
     * @param ids List of IDs of tokens to be minted
     * @param amounts List of amounts of tokens to mint
     * @param data Data to include in token
     *
     * NOTE: The 'ids' & 'amounts' lists should match in length.
     *
     */
    function mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        string memory data
    ) public onlyOwner whenNotPaused {
        require(saleIsActive, "Minting is closed.");

        emit ContractLoggingEvent("Batch Minting started.");
        emit MintLoggingEvent(account, ids, amounts, data);

        /**
         * For the number of items in the array starting from zero,
         * increment by one, until equal to the total number of items,
         * and ensure tokenSupplies are not exceeded.
         */
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 _requestedTokenId = ids[index];
            uint256 _requestedtokenSupply = tokenSupply[_requestedTokenId] +
                amounts[index];

            // Do not exceed max token count
            require(
                _requestedtokenSupply <= tokenMaxSupply[_requestedTokenId],
                string(
                    abi.encodePacked(
                        "Requested tokenId: ",
                        Strings.toString(_requestedTokenId),
                        " amount: ",
                        Strings.toString(amounts[index]),
                        " exceeds token supply: ",
                        Strings.toString(tokenMaxSupply[_requestedTokenId])
                    )
                )
            );

            // update supply data
            tokenSupply[_requestedTokenId] += amounts[index];
        }

        // Party Time!
        _mintBatch(account, ids, amounts, abi.encode(data));

        // flex on everyone
        emit ContractLoggingEvent("Batch Minting successful.");
    }

    /**
     * @dev Burns any amount of tokens for a single tokenId to
     * a single owner as long as the total amount of tokens requested
     * to be burned does not exceed yield a negative value.
     *
     * @param account Intended token owner's wallet address
     * @param id ID of token to be burned
     * @param amount Number of tokens to burn
     *
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public override onlyOwner whenNotPaused {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        emit ContractLoggingEvent("Burning started.");

        uint256 _requestedTokenId = id;
        uint256 _tokenSupply = tokenSupply[_requestedTokenId];

        // If negative, this triggers a revert
        uint256 _adjustedSupply = _tokenSupply - amount;

        // Validate the world is sane and update
        assert(_adjustedSupply >= _tokenSupply);

        // Set new tokenSupply value
        tokenSupply[_requestedTokenId] = _adjustedSupply;

        _burn(account, id, amount);

        // Yell it from the rooftop
        emit ContractLoggingEvent("Burning successful.");
    }

    /**
     * @dev Burns any amount of tokens for multiple tokenIds for a
     * single owner as long as the requested amount of tokens
     * to burn of said token yields a negative value, and the caller
     * is the owner or approved.
     *
     * @param account Intended token owner's wallet address
     * @param ids List of IDs of tokens to be burned
     * @param amounts List of amounts of tokens to burned
     *
     * NOTE: The 'ids' & 'amounts' lists should match in length.
     *
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public override onlyOwner whenNotPaused {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        emit ContractLoggingEvent("Burning started.");

        /**
         * For the number of items in the array starting from zero,
         * increment by one, until equal to the total number of items,
         * and ensure tokenSupplies are not exceeded.
         */
        for (uint256 index = 0; index < ids.length; index++) {
            require(ids[index] != 0, "Burning zero tokens is not possible.");

            uint256 _requestedTokenId = ids[index];
            uint256 _tokenSupply = tokenSupply[_requestedTokenId];

            // If negative, this uint256 triggers a revert
            uint256 _requestedtokenSupply = _tokenSupply - amounts[index];

            require(
                _requestedtokenSupply < _tokenSupply,
                "The new supply count is not less than original, what did you do?"
            );

            // update supply data
            tokenSupply[_requestedTokenId] = _requestedtokenSupply;
        }

        _burnBatch(account, ids, amounts);

        emit BatchBurnLoggingEvent(account, ids, amounts);
        emit ContractLoggingEvent("Batch burn complete.");
    }
}

