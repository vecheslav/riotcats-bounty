pragma solidity ^0.4.23;

contract RCCoreInterface {
    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isRCCore() public pure returns (bool);

    /**
     * @dev Resolve name to address of valid extension
     * @param _name The name
     */
    function resolve(bytes32 _name) public view returns (address);

    /**
     * @dev Check that an address is valid extension
     * @param _address The address
     */
    function checkValidExtension(address _address) external view returns (bool);

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
    ) external returns (uint32);

    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /**
     * @notice Returns all the relevant original information about a specific cat.
     * @param _id The identifier
     */
    function getCat(uint32 _id)
        external
        view
        returns (
            uint192 genes,
            uint104 character,
            uint40 birthBlock,
            uint40 breedCooldownEnd,
            uint40 fightCooldownEnd,
            uint32 matronId,
            uint32 sireId,
            uint16 cooldownIndex,
            uint16 generation
        );

    function getGenes(uint32 _id) public view returns (uint192 genes);
    function getCharacter(uint32 _id) public view returns (uint104 character);
    function getBirthBlock(uint32 _id) public view returns (uint40 birthBlock);
    function getBreedCooldownEnd(uint32 _id) public view returns (uint40 breedCooldownEnd);
    function getFightCooldownEnd(uint32 _id) public view returns (uint40 fightCooldownEnd);
    function getCooldownIndex(uint32 _id) public view returns (uint16 cooldownIndex);
    function getGeneration(uint32 _id) public view returns (uint16 generation);

    function setGenes(uint32 _id, uint192 _genes) public;
    function setCharacter(uint32 _id, uint104 _character) public;
    function setBreedCooldownEnd(uint32 _id, uint40 _breedCooldownEnd) public;
    function setFightCooldownEnd(uint32 _id, uint40 _fightCooldownEnd) public;
    function setCooldownIndex(uint32 _id, uint16 _cooldownIndex) public;
    function setGeneration(uint32 _id, uint16 _generation) public;
}
