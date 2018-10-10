pragma solidity ^0.4.23;

import "../extensions/Extension.sol";
import "../utils/Utils.sol";

contract RCItemStorage is Extension, Utils {
    uint8 constant SLOTS_LIMIT = 5;

    event BaseIdChanged(uint32 indexed id, uint16 oldValue, uint16 newValue);
    event FrozenChanged(uint16 indexed baseId, bool oldValue, bool newValue);

    struct BaseItem {
        // Effects for improve some stats
        uint128 effects;

        // We can freeze the item to fix the balance
        bool frozen;

        // Type of rarity item, important for chance of drop
        uint8 rarity;

        // Type of group for items
        uint8 group;

        // Required cat's level for used this item
        uint8 requiredLevel;
    }

    // An array containing the BaseItem struct for all BaseItems in existence.
    BaseItem[] baseItems;

    // An array containing all items id in existence.
    uint16[] items;

    /**
     * @dev A mapping from item IDs to the address that owns them.
     */
    mapping (uint32 => address) public itemIndexToOwner;

    /**
     * @dev A mapping from item IDs to the address that owns them.
     */
    mapping (uint32 => uint256) public itemIndexToParent;

    /**
     * @dev A mapping from parent IDs to the equipment that owns them.
     */
    mapping (uint256 => uint32[SLOTS_LIMIT]) parentIndexToItemIds;

    /**
     * @dev A mapping from owner address to count of tokens that address owns.
     * Used internally inside balanceOf() to resolve ownership count.
     */
    mapping (address => uint32) ownershipTokenCount;

    /**
     * @dev A mapping from ItemIDs to an address that has been approved to call
     * transferFrom(). Each Item can only have one approved address for transfer
     * at any time. A zero value means no approval is outstanding.
     */
    mapping (uint32 => address) public itemIndexToApproved;

    /**
     * @dev A mapping from items owner (account) to an address that has been approved to call
     * transferFrom() for all items, owned by owner.
     */
    mapping (address => address) public addressToApprovedAll;

    /**
     * Getters & setters
     */

    /**
     * @dev Get info about base items by id
     * @param _baseId The base identifier
     */
    function getBaseItem(uint16 _baseId)
        external
        view
        returns (
            uint128 effects,
            bool frozen,
            uint8 rarity,
            uint8 group,
            uint8 requiredLevel
        )
    {
        BaseItem storage baseItem = baseItems[_baseId];

        effects = baseItem.effects;
        frozen = baseItem.frozen;
        rarity = baseItem.rarity;
        group = baseItem.group;
        requiredLevel = baseItem.requiredLevel;
    }

    function getBaseId(uint32 _id) public view returns (uint16 baseId) {
        baseId = items[_id];
    }

    function getEffects(uint32 _id) public view returns (uint128 effects) {
        effects = baseItems[items[_id]].effects;
    }

    function getFrozen(uint32 _id) public view returns (bool frozen) {
        frozen = baseItems[items[_id]].frozen;
    }

    function getRarity(uint32 _id) public view returns (uint8 rarity) {
        rarity = baseItems[items[_id]].rarity;
    }

    function getGroup(uint32 _id) public view returns (uint8 group) {
        group = baseItems[items[_id]].group;
    }

    function getRequiredLevel(uint32 _id) public view returns (uint8 requiredLevel) {
        requiredLevel = baseItems[items[_id]].requiredLevel;
    }
}