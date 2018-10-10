pragma solidity ^0.4.23;

import "../auction/ClockAuction.sol";
import "../interfaces/extensions/RCItemsInterface.sol";

contract RCSaleAuction is ClockAuction {
    RCItemsInterface public items;

    function extensionName() external pure returns (bytes32) {
        return "SaleAuction";
    }

    constructor(uint16 _fee) public
        ClockAuction(_fee)
    {
    }

    /**
     * @dev Update the addresses of the core & items contracts, can only be called by the owner.
     * @param _coreAddress An address of a RCCore contract instance to be used from this point forward.
     */
    function setup(address _coreAddress) public onlyOwner {
        super.setup(_coreAddress);

        address itemsAddress = core.resolve("Items");
        _setItemsAddress(itemsAddress);
    }

    /**
     * @dev Creates and begins a new auction from owner of token.
     * @param _catId The cat identifier
     * @param _startingPrice The starting price
     * @param _endingPrice The ending price
     * @param _duration The duration
     * @param _unequipped The flag that items of cat must be released
     */
    function createAuction(
        uint32 _catId,
        uint128 _startingPrice,
        uint128 _endingPrice,
        uint40 _duration,
        bool _unequipped
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _catId));

        // Release items if need
        if (_unequipped) {
            items.unequipAll(_catId);
        }

        _createAuction(_catId, _startingPrice, _endingPrice, _duration, msg.sender);
    }

    /**
     * @dev Bids on an open auction, completing the auction and transferring
     * ownership of the NFT if enough Ether is supplied.
     * @param _catId The cat identifier
     */
    function bid(uint32 _catId)
        external
        payable
        whenNotPaused
    {
        _bid(_catId, uint128(msg.value));
        _transfer(msg.sender, _catId);
    }

    function _setItemsAddress(address _address) internal {
        items = RCItemsInterface(_address);
    }
}
