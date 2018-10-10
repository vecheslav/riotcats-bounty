pragma solidity ^0.4.23;

contract GeneScienceInterface {
    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isGeneScience() public pure returns (bool);

    /**
     * @dev Given genes of ent 1 & 2, return a genetic combination - may have a random factor
     * @param _genes1 The genes 1
     * @param _genes2 The genes 2
     * @return The genes that are supposed to be passed down the child
     */
    function mixGenes(uint192 _genes1, uint192 _genes2) public returns (uint192);
}
