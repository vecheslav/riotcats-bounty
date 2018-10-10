pragma solidity ^0.4.23;

import "./RCItemStorage.sol";

contract RCItemBase is RCItemStorage {
    /**
     * @dev The BaseItemCreated event is fired whenever owner created new base item
     */
    event BaseItemCreated(uint32 itemId, uint128 effects, uint8 rarity, uint8 group, uint8 requiredLevel);

    /**
     * @dev The ItemAdded event is fired whenever somebody got new item
     */
    event ItemAdded(address indexed owner, uint32 itemId, uint16 baseId);

    /**
     * @dev Transfer event as defined in ERC721. Emitted every time a item
     * ownership is assigned, including births.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /**
     * @dev Assign event as defined in current draft of ERC721Child. Emitted every time a item
     * parent is assigned.
     */
    event Assign(uint256 indexed _fromParentId, uint256 indexed _toParentId, uint256 _tokenId);

    /**
     * @dev Create base item via contract owner
     * @param _effects The effects
     * @param _rarity The rarity
     * @param _group The group
     * @param _requiredLevel The required level
     */
    function createBaseItem(uint128 _effects, uint8 _rarity, uint8 _group, uint8 _requiredLevel)
        external
        onlyOwner
        returns (uint16)
    {
        BaseItem memory baseItem = BaseItem({
            effects: _effects,
            frozen: false,
            rarity: _rarity,
            group: _group,
            requiredLevel: _requiredLevel
        });
        uint256 newBaseItemId256 = baseItems.push(baseItem) - 1;

        require(newBaseItemId256 <= 0xFFFF);

        uint16 newBaseItemId = uint16(newBaseItemId256);

        // Emit the BaseItemCreated event
        emit BaseItemCreated(
            newBaseItemId,
            baseItem.effects,
            baseItem.rarity,
            baseItem.group,
            baseItem.requiredLevel
        );

        return newBaseItemId;
    }

    /**
     * @dev External method that adds item (based on preset item) to array of items.
     * This method is available only for extensions.
     * @param _baseId The base identifier
     * @param _owner The owner
     */
    function addItem(uint16 _baseId, address _owner)
        external
        onlyCoreOrExtensions
        returns (uint32)
    {
        return _addItem(_baseId, _owner);
    }

    /**
     * @dev Set base ID of a specific item in critical moments (e.g. when an baseItem is frozen).
     * @param _id The identifier
     * @param _baseId The base identifier
     */
    function changeBaseId(uint32 _id, uint16 _baseId) external onlyOwner {
        require(_id > 0);

        if (items[_id] != _baseId) {
            emit BaseIdChanged(_id, items[_id], _baseId);
            items[_id] = _baseId;
        }
    }

    /**
     * @dev Set frozen status of a baseItem in critical moments
     * @param _baseId The base identifier
     * @param _frozen The frozen
     */
    function freeze(uint16 _baseId, bool _frozen) external onlyOwner {
        BaseItem storage baseItem = baseItems[_baseId];
        if (baseItem.frozen != _frozen) {
            emit FrozenChanged(_baseId, baseItem.frozen, _frozen);
            baseItem.frozen = _frozen;
        }
    }

    /**
     * @dev Assign item as child of specified token
     * @param _fromParentId The prev parent identifier
     * @param _toParentId The target parent identifier
     * @param _itemId The item identifier
     */
    function _assign(uint256 _fromParentId, uint256 _toParentId, uint32 _itemId) internal {
        if (_fromParentId > 0) {
            _release(_itemId);
        }

        if (_toParentId > 0) {
            uint16 baseId = items[_itemId];
            uint8 group = baseItems[baseId].group;
            bool frozen = baseItems[baseId].frozen;

            // Can't assign frozen item
            require(!frozen);

            // Check that slot is empty
            uint32 _prevItemId = parentIndexToItemIds[_toParentId][group];
            if (_prevItemId > 0) {
                _release(_prevItemId);
            }

            itemIndexToParent[_itemId] = _toParentId;
            parentIndexToItemIds[_toParentId][group] = _itemId;
        }

        // Emit the assign event.
        emit Assign(_fromParentId, _toParentId, _itemId);
    }

    /**
     * @dev Assigns ownership of a specific item to an address.
     * @param _from The address of the current owner
     * @param _to The address of the future owner
     * @param _itemId The item identifier
     */
    function _transfer(address _from, address _to, uint32 _itemId) internal {
        // Since the number of Items is capped to 2^32
        // there is no way to overflow this
        ownershipTokenCount[_to]++;

        // Transfer ownership
        itemIndexToOwner[_itemId] = _to;

        // When creating new items _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // Clear any previously approved ownership exchange
            delete itemIndexToApproved[_itemId];
        }

        // Emit the transfer event.
        emit Transfer(_from, _to, _itemId);
    }

    /**
     * @dev Adding item (based on preset item) to array of items
     * @param _baseId The base identifier
     * @param _owner The owner
     */
    function _addItem(uint16 _baseId, address _owner)
        internal
        returns (uint32)
    {
        uint256 newItemId256 = items.push(_baseId) - 1;

        require(newItemId256 <= 0xFFFFFFFF);

        uint32 newItemId = uint32(newItemId256);

        // Emit the ItemAdded event
        emit ItemAdded(
            _owner,
            newItemId,
            _baseId
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newItemId);

        return newItemId;
    }

    /**
     * @dev Release an item from assigned parent
     * @param _itemId The item identifier
     */
    function _release(uint32 _itemId) internal {
        uint16 baseId = items[_itemId];
        uint8 group = baseItems[baseId].group;
        uint256 parentId = itemIndexToParent[_itemId];


        delete itemIndexToParent[_itemId];
        delete parentIndexToItemIds[parentId][group];
    }
}