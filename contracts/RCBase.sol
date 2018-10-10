pragma solidity ^0.4.23;

import "./RCStorage.sol";
import "./config/ConfigInterface.sol";

contract RCBase is RCStorage {
    /**
     * @dev The Birth event is fired whenever a new cat comes into existence. This obviously
     * includes any time a cat is created through the giveBirth method, but it is also called
     * when a new gen0 cat is created.
     */
    event Birth(address indexed owner, uint32 catId, uint32 matronId, uint32 sireId, uint192 genes, uint104 character);

    /**
     * @dev Transfer event as defined in ERC721. Emitted every time a cat
     * ownership is assigned, including births.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    ConfigInterface public config;

    /**
     * @dev An safe external method that creates a new cat and stores it.
     * This method is available only for extensions.
     * @param _matronId The matron identifier
     * @param _sireId The sire identifier
     * @param _generation The generation number of this cat, must be computed by caller.
     * @param _cooldownIndex The cooldown index of this cat
     * @param _genes The cat's genetic code
     * @param _character The cat's character data
     * @param _birthBlock The cat's birth block
     * @param _owner The initial owner of this cat, must be non-zero.
     */
    function createCat(
        uint32 _matronId,
        uint32 _sireId,
        uint16 _generation,
        uint16 _cooldownIndex,
        uint192 _genes,
        uint104 _character,
        uint40 _birthBlock,
        address _owner
    )
        external
        onlyExtensions
        returns (uint32)
    {
        return _createCat(_matronId, _sireId, _generation, _cooldownIndex, _genes, _character, _birthBlock, _owner);
    }

    /**
     * @dev Assigns ownership of a specific Cat to an address.
     * @param _from The address of the current owner
     * @param _to The address of the future owner
     * @param _catId The cat identifier
     */
    function _transfer(address _from, address _to, uint32 _catId) internal {
        // Since the number of Cats is capped to 2^32
        // there is no way to overflow this
        ownershipTokenCount[_to]++;

        // Transfer ownership
        catIndexToOwner[_catId] = _to;

        // When creating new cats _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // Clear any previously approved ownership exchange
            delete catIndexToApproved[_catId];
        }

        // Broadcast event to extensions
        for (uint16 i = 0; i < extensionsCollection.length; i++) {
            extensionsCollection[i].onTransfer(_from, _to, _catId);
        }

        // Emit the transfer event.
        emit Transfer(_from, _to, _catId);
    }

    /**
     * @dev An internal method that creates a new cat and stores it. This
     * method doesn't do any checking and should only be called when the
     * input data is known to be valid. Will generate both a Birth event
     * and a Transfer event.
     * @param _matronId The matron identifier
     * @param _sireId The sire identifier
     * @param _generation The generation number of this cat, must be computed by caller.
     * @param _genes The cat's genetic code
     * @param _character The cat's character data
     * @param _birthBlock The cat's birth block
     * @param _owner The initial owner of this cat, must be non-zero.
     */
    function _createCat(
        uint32 _matronId,
        uint32 _sireId,
        uint16 _generation,
        uint16 _cooldownIndex,
        uint192 _genes,
        uint104 _character,
        uint40 _birthBlock,
        address _owner
    )
        internal
        returns (uint32)
    {
        Cat memory cat = Cat({
            genes: _genes,
            character: _character,
            birthBlock: _birthBlock,
            breedCooldownEnd: 0,
            fightCooldownEnd: 0,
            matronId: _matronId,
            sireId: _sireId,
            cooldownIndex: _cooldownIndex,
            generation: _generation
        });
        uint256 newCatId256 = cats.push(cat) - 1;

        // It's probably never going to happen, 4 billion cats is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newCatId256 <= 0xFFFFFFFF);

        uint32 newCatId = uint32(newCatId256);

        // Emit the birth event
        emit Birth(
            _owner,
            newCatId,
            cat.matronId,
            cat.sireId,
            cat.genes,
            cat.character
        );

        // This will assign ownership, and also emit the Transfer event as per ERC721
        _transfer(0, _owner, newCatId);

        return newCatId;
    }

    /**
     * @dev Update the address of the config contract.
     * @param _address An address of a Config contract instance to be used from this point forward.
     */
    function _setConfigAddress(address _address) internal {
        ConfigInterface candidateContract = ConfigInterface(_address);
        require(candidateContract.isConfig());
        config = candidateContract;
    }
}
