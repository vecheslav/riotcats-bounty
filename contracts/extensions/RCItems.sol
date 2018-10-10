pragma solidity ^0.4.23;

import "./Extension.sol";
import "../item/RCItemCoreInterface.sol";
import "../utils/Bits.sol";

contract RCItems is Extension {
    using Bits for uint;

    uint8 constant ITEM_BITS_SIZE = 32;

    RCItemCoreInterface public itemCore;

    function extensionName() external pure returns (bytes32) {
        return "Items";
    }

    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isRCBreeding() public pure returns (bool) {
        return true;
    }

    /**
     * @dev Update the addresses of the core & item contracts, can only be called by the owner.
     * @param _coreAddress An address of a RCCore contract instance to be used from this point forward.
     */
    function setup(address _coreAddress) public onlyOwner {
        super.setup(_coreAddress);

        address itemCoreAddress = core.resolve("ItemCore");
        _setItemCoreAddress(itemCoreAddress);
    }

    /**
     * @dev Equip specified items on cat.
     * This is external method for users.
     * @param _catId The cat identifier
     * @param _equipment The encoded array of items
     */
    function equip(uint32 _catId, uint256 _equipment) external whenNotPaused {
        _equip(msg.sender, _catId, _equipment);
    }

    /**
     * @dev Unequip all items.
     * This method is available only for extensions (etc. SaleAuction).
     * @param _catId The cat identifier
     */
    function unequipAll(uint32 _catId)
        external
        whenNotPaused
        onlyCoreOrExtensions
    {
        if (itemCore.totalChildrenOf(_catId) > 0) {
            _unequipAll(_catId);
        }
    }

    /**
     * @dev Equip specified items on cat
     * @param _owner The owner of cat
     * @param _catId The cat identifier
     * @param _equipment The encoded array of items
     */
    function _equip(address _owner, uint32 _catId, uint256 _equipment) internal {
        require(_owner == core.ownerOf(_catId));

        uint8 numOfEquipment = config.numOfEquipment();
        uint8 skips = 0;

        uint8 catLevel = config.getCharacterLevel(core.getCharacter(_catId));
        uint256[] memory children = itemCore.childrenOf(_catId);

        for (uint8 i = 0; i < numOfEquipment; i++) {
            uint32 itemId = uint32(_equipment.bits(i * ITEM_BITS_SIZE, ITEM_BITS_SIZE));
            uint32 prevItemId = uint32(children[i]);

            if (itemId == prevItemId) {
                skips++;
                continue;
            }

            if (itemId > 0) {
                // Set new item
                // Check owns
                require(_owner == itemCore.ownerOf(itemId));

                uint8 itemRequiredLevel = itemCore.getRequiredLevel(itemId);
                require(itemRequiredLevel <= catLevel);

                itemCore.assignParent(_catId, itemId);
            } else if (prevItemId > 0) {
                // Release prev item
                itemCore.assignParent(0, prevItemId);
            }
        }

        require(skips < numOfEquipment);
    }

    /**
     * @dev Unequip all items.
     * @param _catId The cat identifier
     */
    function _unequipAll(uint32 _catId) internal {
        uint8 numOfEquipment = config.numOfEquipment();
        uint256[] memory children = itemCore.childrenOf(_catId);

        for (uint8 i = 0; i < numOfEquipment; i++) {
            uint32 prevItemId = uint32(children[i]);

            if (prevItemId > 0) {
                itemCore.assignParent(0, prevItemId);
            }
        }
    }

	/**
	 * @dev Handle event of transfer tokens on core contract
	 * @param _to The target address
	 * @param _tokenId The token identifier
	 */
    function onTransfer(address, address _to, uint256 _tokenId) external onlyCore {
        // Check equipment on cat
        if (itemCore.totalChildrenOf(_tokenId) > 0) {
            _transferChildren(_to, _tokenId);
        }
    }

    /**
     * @dev Transfer all children of specified parent.
     * @param _to The target address, it will be owner of assigned items
     * @param _parentId The parent identifier
     */
    function _transferChildren(address _to, uint256 _parentId) internal {
        uint256[] memory children = itemCore.childrenOf(_parentId);

        for (uint8 i = 0; i < children.length; i++) {
            if (children[i] > 0) {
                itemCore.transferAsChild(_to, children[i]);
            }
        }
    }

    /**
     * @dev Update the address of the item contract.
     * @param _address An address of a RCItemCore contract instance to be used from this point forward.
     */
    function _setItemCoreAddress(address _address) internal {
        RCItemCoreInterface candidateContract = RCItemCoreInterface(_address);
        require(candidateContract.isRCItemCore());
        itemCore = candidateContract;
    }
}
