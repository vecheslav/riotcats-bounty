pragma solidity ^0.4.23;
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";
import "./ERC721Basic.sol";

/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
    /**
     * 0x80ac58cd ===
     *   bytes4(keccak256('balanceOf(address)')) ^
     *   bytes4(keccak256('ownerOf(uint256)')) ^
     *   bytes4(keccak256('approve(address,uint256)')) ^
     *   bytes4(keccak256('getApproved(uint256)')) ^
     *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */
    bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;

    /**
     * 0x01ffc9a7 ===
     *   bytes4(keccak256('supportsInterface(bytes4)'))
     */
    bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;

    /**
     * 0x780e9d63 ===
     *   bytes4(keccak256('totalSupply()')) ^
     *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
     *   bytes4(keccak256('tokenByIndex(uint256)'));
     */
    bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;


    /**
     * 0x5b5e139f ===
     *   bytes4(keccak256('name()')) ^
     *   bytes4(keccak256('symbol()')) ^
     *   bytes4(keccak256('tokenURI(uint256)'))
     */
    bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceID == InterfaceId_ERC721 ||
               interfaceID == InterfaceId_ERC165 ||
               interfaceID == InterfaceId_ERC721Enumerable ||
               interfaceID == InterfaceId_ERC721Metadata;
    }
}