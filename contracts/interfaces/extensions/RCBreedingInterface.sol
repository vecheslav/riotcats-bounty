pragma solidity ^0.4.23;

contract RCBreedingInterface {
    function isValidMatingPair(uint32 _matronId, uint32 _sireId) external view returns(bool);
    function isReadyToBreed(uint32 _catId) external view returns (bool);

    function breedWith(uint32 _matronId, uint32 _sireId) external returns (uint32);
}
