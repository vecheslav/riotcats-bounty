pragma solidity ^0.4.23;

library Bits {
    uint constant internal ONE = uint(1);
    uint constant internal ONES = uint(~0);

    function bit(uint self, uint8 _index)
        internal
        pure
        returns (uint8)
    {
        return uint8(self >> _index & 1);
    }

    function setBit(uint self, uint8 _index)
        internal
        pure
        returns (uint)
    {
        return self | ONE << _index;
    }

    function bits(uint self, uint8 _start, uint8 _numBits)
        internal
        pure
        returns (uint)
    {
        return (self >> _start) & ~(ONES << _numBits);
    }

    function setBits(uint self, uint8 _start, uint _newBits, uint8 _numBits)
        internal
        pure
        returns (uint)
    {
        uint mask = (ONES << (_start + _numBits)) | ((ONE << _start) - 1);
        return (self & mask) | (_newBits << _start);
    }

    function setBitsInClean(uint self, uint8 _start, uint _newBits)
        internal
        pure
        returns (uint)
    {
        return self | (_newBits << _start);
    }
}