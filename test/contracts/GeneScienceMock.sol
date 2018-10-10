pragma solidity ^0.4.23;

contract GeneScienceMock {
    bool public isGeneScience = true;

    /**
     * @dev Given genes of ent 1 & 2, return a genetic combination - may have a random factor
     * @param _genes1 The genes 1
     * @param _genes2 The genes 2
     * @return The genes that are supposed to be passed down the child
     */
    function mixGenes(uint192 _genes1, uint192 _genes2) public pure returns (uint192) {
        return (_genes1 + _genes2) / 2;
    }
}
