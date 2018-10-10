pragma solidity ^0.4.23;

contract ConfigInterface {
    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isConfig() public pure returns (bool);

    function numOfEquipment() public view returns (uint8);

    function getBreedCooldownEnd(uint16 _cooldownIndex) external view returns (uint40);
    function getFightCooldownEnd() external view returns (uint40);
    function getCooldownIndex(uint16 _generation) external view returns (uint16);
    function getChildGeneration(uint16 _generation1, uint16 _generation2) external pure returns (uint16);
    function getCharacterLevel(uint104 _character) external pure returns (uint8);
}
