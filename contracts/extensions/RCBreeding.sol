pragma solidity ^0.4.23;

import "./Extension.sol";
import "../external/GeneScienceInterface.sol";

contract RCBreeding is Extension {

    function extensionName() external pure returns (bytes32) {
        return "Breeding";
    }

    /**
     * @dev The address of the sibling contract that is used to implement the sooper-sekret
     * genetic combination algorithm.
     */
    GeneScienceInterface public geneScience;

    /**
     * @dev Update the address of the genetic contract, can only be called by the CEO.
     * @param _address An address of a GeneScience contract instance to be used from this point forward.
     */
    function setGeneScienceAddress(address _address) external onlyOwner {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);
        require(candidateContract.isGeneScience());
        geneScience = candidateContract;
    }

    /**
     * @dev Breed cats that you own. Will either make your cat give birth, or will fail.
     * @param _matronId The matron identifier
     * @param _sireId The sire identifier
     */
    function breedWithOwn(uint32 _matronId, uint32 _sireId)
        external
        whenNotPaused
        returns (uint32)
    {
        // Caller must own the matron.
        require(msg.sender == core.ownerOf(_matronId));

        require(_isBreedingPermitted(_matronId, _sireId));

        // Make sure matron isn't in the middle of a siring cooldown
        require(_isReadyToBreed(_matronId));

        // Make sure sire isn't in the middle of a siring cooldown
        require(_isReadyToBreed(_sireId));

        // Test that these cats are a valid mating pair.
        require(_isValidMatingPair(_matronId, _sireId));

        // All checks passed, cats can breeding!
        return _breedWith(_matronId, _sireId);
    }

    /**
     * @dev Breed cats by auction/extensions.
     * Any extensions must check that breeding is available.
     * @param _matronId The matron identifier
     * @param _sireId The sire identifier
     */
    function breedWith(uint32 _matronId, uint32 _sireId)
        external
        whenNotPaused
        onlyCoreOrExtensions
        returns (uint32)
    {
        return _breedWith(_matronId, _sireId);
    }

    /**
     * @dev The check to see if a given sire and matron are a valid mating pair. DOES NOT
     * check ownership permissions (that is up to the caller).
     * @param _matronId The matron identifier
     * @param _sireId The sire identifier
     */
    function isValidMatingPair(uint32 _matronId, uint32 _sireId) external view returns (bool) {
        return _isValidMatingPair(_matronId, _sireId);
    }

    /**
     * @dev Checks that a given cat is able to breed. Requires that the
     * current cooldown is finished (for sires).
     * @param _catId The cat identifier
     */
    function isReadyToBreed(uint32 _catId) external view returns (bool) {
        return _isReadyToBreed(_catId);
    }

    /**
     * @dev Internal utility function to initiate breeding, assumes that all breeding
     * requirements have been checked.
     * @param _matronId The matron identifier
     * @param _sireId The sire identifier
     */
    function _breedWith(uint32 _matronId, uint32 _sireId) internal returns (uint32) {
        // Trigger the cooldown for both parents.
        _triggerCooldown(_matronId);
        _triggerCooldown(_sireId);

        // Check that the mom is a valid cat.
        require(core.getBirthBlock(_matronId) != 0);

        uint192 childGenes;
        uint16 childGeneration;
        uint16 childCooldownIndex;
        uint40 childBirthBlock;
        (childGenes,childGeneration,childCooldownIndex,childBirthBlock) = _collectChildData(_matronId, _sireId);

        // Create new cat
        address owner = core.ownerOf(_matronId);
        uint32 catId = core.createCat(
            _matronId,
            _sireId,
            childGeneration,
            childCooldownIndex,
            childGenes,
            0,
            childBirthBlock,
            owner
        );

        return catId;
    }

    function _collectChildData(uint32 _matronId, uint32 _sireId)
        internal
        returns (
            uint192 genes,
            uint16 generation,
            uint16 cooldownIndex,
            uint40 birthBlock
        )
    {
        // Call the sooper-sekret, sooper-expensive, gene mixing operation.
        genes = geneScience.mixGenes(core.getGenes(_matronId), core.getGenes(_sireId));

        // Get child generation & cooldown index based on parents generation
        generation = config.getChildGeneration(core.getGeneration(_matronId), core.getGeneration(_sireId));

        cooldownIndex = config.getCooldownIndex(generation);
        birthBlock = core.getBreedCooldownEnd(_matronId);
    }

    /**
     * @dev Internal check to see if a given sire and matron are a valid mating pair. DOES NOT
     * check ownership permissions (that is up to the caller).
     * @param _matronId The matron identifier
     * @param _sireId The sire identifier
     */
    function _isValidMatingPair(uint32 _matronId, uint32 _sireId)
        private
        view
        returns(bool)
    {
        // A Cat can't breed with itself!
        if (_matronId == _sireId) {
            return false;
        }

        uint32 matronsMatronId;
        uint32 matronsSireId;
        uint32 siresMatronId;
        uint32 siresSireId;
        (,,,,,matronsMatronId,matronsSireId,,) = core.getCat(_matronId);
        (,,,,,siresMatronId,siresSireId,,) = core.getCat(_sireId);

        // Cats can't breed with their parents.
        if (matronsMatronId == _sireId || matronsSireId == _sireId) {
            return false;
        }
        if (siresMatronId == _matronId || siresSireId == _matronId) {
            return false;
        }

        // We can short circuit the sibling check (below) if either cat is
        // gen zero (has a matron ID of zero).
        if (siresMatronId == 0 || matronsMatronId == 0) {
            return true;
        }

        // Cats can't breed with full or half siblings.
        if (siresMatronId == matronsMatronId || siresMatronId == matronsSireId) {
            return false;
        }
        if (siresSireId == matronsMatronId || siresSireId == matronsSireId) {
            return false;
        }

        return true;
    }

    /**
     * @dev Checks that a given cat is able to breed. Requires that the
     * current cooldown is finished (for sires).
     * @param _catId The cat identifier
     */
    function _isReadyToBreed(uint32 _catId) internal view returns (bool) {
        return core.getBreedCooldownEnd(_catId) <= uint40(block.number);
    }

    /**
     * @dev Check if a sire has authorized breeding with this matron. True if both sire
     * and matron have the same owner.
     * @param _matronId The sire identifier
     * @param _sireId The matron identifier
     */
    function _isBreedingPermitted(uint32 _matronId, uint32 _sireId) internal view returns (bool) {
        return core.ownerOf(_matronId) == core.ownerOf(_sireId);
    }

    /**
     * @dev Set the breedCooldownEnd for the given Cat ID, based on its current cooldownIndex.
     * Also increments the cooldownIndex (unless it has hit the cap).
     * @param _catId The cat identifier.
     */
    function _triggerCooldown(uint32 _catId) internal {
        uint16 cooldownIndex = core.getCooldownIndex(_catId);
        core.setBreedCooldownEnd(_catId, config.getBreedCooldownEnd(cooldownIndex));

        if (cooldownIndex < 5) {
            core.setCooldownIndex(_catId, cooldownIndex + 1);
        }
    }
}
