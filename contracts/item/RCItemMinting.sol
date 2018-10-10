pragma solidity ^0.4.23;

import "./RCItemToken.sol";

contract RCItemMinting is RCItemToken {
    // Limits the number of items the contract owner can ever create.
    uint24 public constant PROMO_CREATION_LIMIT = 15000;

    // Counts the number of items the contract owner has created.
    uint24 public promoCreatedCount;

    /**
     * @dev Add promo items to owner.
     * @param _baseId The base identifier
     * @param _owner The owner
     */
    function addPromoItem(uint16 _baseId, address _owner) external onlyOwner {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _addItem(_baseId, _owner == address(0) ? owner : _owner);
    }
}