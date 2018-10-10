pragma solidity ^0.4.23;

library Uints {
    function toString(uint i) internal pure returns (string) {
        if (i == 0) return '0';
        uint j = i;
        uint len;

        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint k = len - 1;

        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}