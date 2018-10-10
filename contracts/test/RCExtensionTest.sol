pragma solidity ^0.4.23;

import "../extensions/Extension.sol";

contract RCExtensionTest is Extension {
    uint8 public testNumber = 1;

    function extensionName() external pure returns (bytes32) {
        return "ExtensionTest";
    }

    function setGenes(uint32 _catId, uint192 _genes) external onlyOwner {
        core.setGenes(_catId, _genes);
    }

    function escrow(uint32 _catId, address _to) external onlyOwner {
        address catOwner = core.ownerOf(_catId);
        core.transferFrom(catOwner, _to, _catId);
    }

    function setNumber(uint8 _number) external onlyCoreOrExtensions {
        testNumber = _number;
    }
}
