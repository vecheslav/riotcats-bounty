pragma solidity ^0.4.23;

library Strings {
    function concat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);

        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;

        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];

        return string(bab);
    }
}