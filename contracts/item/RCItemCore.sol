pragma solidity ^0.4.23;

import "./RCItemMinting.sol";

contract RCItemCore is RCItemMinting {
    constructor() public {
        owner = msg.sender;

        // start with the mythical item 0
        _addItem(0, address(0));
    }

    function extensionName() external pure returns (bytes32) {
        return "ItemCore";
    }

    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isRCItemCore() public pure returns (bool) {
        return true;
    }

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
        )
    {
        // Only available items
        require(_id > 0);

        baseId = items[_id];
        BaseItem storage baseItem = baseItems[baseId];

        effects = baseItem.effects;
        frozen = baseItem.frozen;
        rarity = baseItem.rarity;
        group = baseItem.group;
        requiredLevel = baseItem.requiredLevel;
    }
}