pragma solidity ^0.4.23;

contract Utils {

    modifier less32Bits(uint256 _value) {
        require(_value <= 0xFFFFFFFF);
        _;
    }
}