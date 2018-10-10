pragma solidity ^0.4.23;

import "../item/RCItemCore.sol";

contract RCItemCoreTest is RCItemCore {
    constructor() public {
    }

    /**
     * @dev Contract owner can create items at will (test-only).
     * @param _baseId The base identifier
     * @param _cloneCount How many are being created
     */
    function mintTokens(uint16 _baseId, uint32 _cloneCount) external onlyOwner whenNotPaused {
        require(_cloneCount > 0);

        for (uint32 i = 0; i < _cloneCount; i++) {
            _addItem(_baseId, msg.sender);
        }
    }

    /**
     * @dev Assign item as child of specified token.
     * It's available for users (test-only).
     * @param _toParentId The target parent identifier
     * @param _tokenId The item identifier
     */
    function assignParentByOwner(uint256 _toParentId, uint256 _tokenId)
        external
        less32Bits(_tokenId)
    {
        uint256 fromParentId = itemIndexToParent[uint32(_tokenId)];

        // Check for valid ownership item
        require(_canAssign(uint32(_tokenId)));

        _assign(fromParentId, _toParentId, uint32(_tokenId));
    }
}
