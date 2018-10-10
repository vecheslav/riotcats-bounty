pragma solidity ^0.4.23;

import "../RCCore.sol";

interface RCExtensionTestInterface {
    function testNumber() external pure returns (uint8);

    function setNumber(uint8 _number) external;
}

contract RCCoreTest is RCCore {
    constructor() public {
    }

    /**
     * @dev Contract owner can create cats at will (test-only)
     * @param _genes The actual genetic load of cats
     * @param _cloneCount How many are being created
     */
    function mintTokens(uint192 _genes, uint32 _cloneCount) external onlyCOO whenNotPaused {
        require(_cloneCount > 0);

        for (uint32 i = 0; i < _cloneCount; i++) {
            _createCat(0, 0, 0, 0, _genes, 0, uint40(block.number), msg.sender);
        }
    }

    /**
     * @dev Call method on extension via core's resolver
     */
    function increaseNumberOnExtension() external onlyCOO {
        address extensionAddress = resolve("ExtensionTest");
        require(extensionAddress != address(0));
        RCExtensionTestInterface extension = RCExtensionTestInterface(extensionAddress);

        uint8 number = extension.testNumber();

        extension.setNumber(number + 1);
    }

    function fundMe() public payable returns (bool) {
        return true;
    }

    function timeNow() public view returns (uint40) {
        return uint40(block.number);
    }
}
