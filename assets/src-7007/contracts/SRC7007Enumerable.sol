// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SRC7007Zkml.sol";
import "./ISRC7007Enumerable.sol";

/**
 * @dev Implementation of the {ISRC7007Enumerable} interface.
 */
abstract contract SRC7007Enumerable is SRC7007Zkml, ISRC7007Enumerable {
    /**
     * @dev See {ISRC7007Enumerable-tokenId}.
     */
    mapping(uint256 => string) public prompt;


    /**
     * @dev See {ISRC7007Enumerable-prompt}.
     */
    mapping(bytes => uint256) public tokenId;

    /**
     * @dev See {ISRC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ISRC165, SRC7007Zkml) returns (bool) {
        return
            interfaceId == type(ISRC7007Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function mint(
        address to,
        bytes calldata prompt_,
        bytes calldata aigcData,
        string calldata uri,
        bytes calldata proof
    ) public virtual override returns (uint256 tokenId_) {
        tokenId_ = SRC7007Zkml.mint(to, prompt_, aigcData, uri, proof);
        prompt[tokenId_] = string(prompt_);
        tokenId[prompt_] = tokenId_;
    }
}

contract MockSRC7007Enumerable is SRC7007Enumerable {
    constructor(
        string memory name_,
        string memory symbol_,
        address verifier_
    ) SRC7007Zkml(name_, symbol_, verifier_) {}
} 