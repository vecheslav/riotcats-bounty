pragma solidity ^0.4.23;

contract Random {

    /**
      * @dev Getting super-random value, based on timestamp and block number
      */
    function _random(uint _seed, uint _max) internal view returns (uint) {
        uint seed1 = block.timestamp;
        bytes32 seed2 = blockhash(block.number - 1);
        bytes32 randHash = keccak256(abi.encodePacked(_seed, seed1, seed2));
        return uint(randHash) % _max;
    }
}