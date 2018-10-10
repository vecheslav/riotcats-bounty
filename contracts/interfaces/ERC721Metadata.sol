pragma solidity ^0.4.23;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Metadata {
    function name() external pure returns (string);
    function symbol() external pure returns (string);

    function tokenURI(uint256 _tokenId) external view returns (string);
}