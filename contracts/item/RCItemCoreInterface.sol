pragma solidity ^0.4.23;

contract RCItemCoreInterface {
    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isRCItemCore() public pure returns (bool);

    /**
     * @dev External method that adds item (based on preset item) to array of items.
     * This method is available only for extensions.
     * @param _baseId The base identifier
     * @param _owner The owner
     */
    function addItem(uint16 _baseId, address _owner)
        external
        returns (uint32);

    // ERC721
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    // ERC721Child
    function totalChildrenOf(uint256 _parentId) external view returns (uint256);
    function parentOf(uint256 _tokenId) external view returns (uint256);
    function childrenOf(uint256 _parentId) external view returns (uint256[]);
    function assignParent(uint256 _toParentId, uint256 _tokenId) external;
    function transferAsChild(address _to, uint256 _tokenId) external;

    /**
     * @dev Get item info with base info
     * @param _id The item identifier
     */
    function getItem(uint256 _id)
        external
        view
        returns (
            uint16 baseId,
            uint128 effects,
            bool frozen,
            uint8 rarity,
            uint8 group,
            uint8 requiredLevel
        );

    function getBaseId(uint32 _id) public view returns (uint16 baseId);
    function getEffects(uint32 _id) public view returns (uint128 effects);
    function getFrozen(uint32 _id) public view returns (bool frozen);
    function getRarity(uint32 _id) public view returns (uint8 rarity);
    function getGroup(uint32 _id) public view returns (uint8 group);
    function getRequiredLevel(uint32 _id) public view returns (uint8 requiredLevel);
}