pragma solidity ^0.4.23;

import "../auction/ClockAuction.sol";
import "../interfaces/extensions/RCBreedingInterface.sol";

contract RCSiringAuction is ClockAuction {
    RCBreedingInterface public breeding;

    function extensionName() external pure returns (bytes32) {
        return "SiringAuction";
    }

    constructor(uint16 _fee) public
        ClockAuction(_fee)
    {
    }

    /**
     * @dev Update the addresses of the core & breeding contracts, can only be called by the owner.
     * @param _coreAddress An address of a RCCore contract instance to be used from this point forward.
     */
    function setup(address _coreAddress) public onlyOwner {
        super.setup(_coreAddress);

        address breedingAddress = core.resolve("Breeding");
        _setBreedingAddress(breedingAddress);
    }

    /**
     * @dev Creates and begins a new siring auction from owner of token.
     * @param _catId The cat identifier
     * @param _startingPrice The starting price
     * @param _endingPrice The ending price
     * @param _duration The duration
     */
    function createAuction(
        uint32 _catId,
        uint128 _startingPrice,
        uint128 _endingPrice,
        uint40 _duration
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _catId));
        require(breeding.isReadyToBreed(_catId));

        _createAuction(_catId, _startingPrice, _endingPrice, _duration, msg.sender);
    }

    /**
     * @dev Completes a siring auction by bidding.
     * Immediately breeds the winning matron with the sire on auction.
     * @param _sireId The sire identifier
     * @param _matronId The matron identifier
     */
    function bid(uint32 _sireId, uint32 _matronId)
        external
        payable
        whenNotPaused
    {
        // Check for breeding
        require(_owns(msg.sender, _matronId));
        require(breeding.isReadyToBreed(_matronId));
        require(breeding.isValidMatingPair(_matronId, _sireId));

        address seller = catIdToAuction[_sireId].seller;

        _bid(_sireId, uint128(msg.value));
        _transfer(seller, _sireId);

        // All checks passed, cats can breeding!
        breeding.breedWith(_matronId, _sireId);
    }

    function _setBreedingAddress(address _address) internal {
        breeding = RCBreedingInterface(_address);
    }
}
