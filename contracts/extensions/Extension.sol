pragma solidity ^0.4.23;

import "../interfaces/extensions/ExtensionInterface.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../RCCoreInterface.sol";
import "../config/ConfigInterface.sol";

contract Extension is Pausable, ExtensionInterface {
    RCCoreInterface public core;
    ConfigInterface public config;

    modifier onlyCore() {
        require(_isValidCore(msg.sender));
        _;
    }

    modifier onlyOwnerOrCore() {
        require(msg.sender == owner || _isValidCore(msg.sender));
        _;
    }

    /**
     * @dev Access modifier for Core/Extensions-only functionality
     */
    modifier onlyCoreOrExtensions() {
        require(_isValidCore(msg.sender) || _isValidExtension(msg.sender));
        _;
    }

    /**
     * @dev This name must be unique for each extension
     */
    function extensionName() external pure returns (bytes32) {
        return "Extension";
    }

    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isExtension() public pure returns (bool) {
        return true;
    }

    /**
     * @dev Update the address of the core contract, can only be called by the owner.
     * @param _coreAddress An address of a RCCore contract instance to be used from this point forward.
     */
    function setup(address _coreAddress) public onlyOwner {
        _setCoreAddress(_coreAddress);
    }

    /**
     * @dev Update the address of the config contract, can only be called by the owner or core contract.
     * @param _address An address of a Config contract instance to be used from this point forward.
     */
    function setConfigAddress(address _address) external onlyOwnerOrCore {
        _setConfigAddress(_address);
    }

    /**
     * @dev Handle event of remove extension on core contract
     */
    function onRemove() external onlyCore {
        paused = true;

        withdraw();
    }

    /**
     * @dev Handle event of transfer tokens on core contract
     */
    function onTransfer(address, address, uint256) external onlyCore {
        return;
    }

    /**
     * @dev Remove all Ether from the contract, which is the owner's cuts
     * as well as any Ether sent directly to the contract address.
     * Always transfers to the NFT contract, but can be called either by
     * the owner or the NFT contract.
     */
    function withdraw() public onlyOwnerOrCore {
        if (address(this).balance > 0) {
            address(core).transfer(address(this).balance);
        }
    }

    /**
     * @dev Update the address of the core contract.
     * @param _address An address of a RCCore contract instance to be used from this point forward.
     */
    function _setCoreAddress(address _address) internal {
        RCCoreInterface candidateContract = RCCoreInterface(_address);
        require(candidateContract.isRCCore());
        core = candidateContract;
    }

    /**
     * @dev Update the address of the config contract.
     * @param _address An address of a Config contract instance to be used from this point forward.
     */
    function _setConfigAddress(address _address) internal {
        ConfigInterface candidateContract = ConfigInterface(_address);
        require(candidateContract.isConfig());
        config = candidateContract;
    }

    /**
     * @dev Check that an address is valid extension
     * @param _address The address
     */
    function _isValidExtension(address _address) internal view returns (bool) {
        if (address(core) == address(0)) {
            return false;
        }

        return core.checkValidExtension(_address);
    }

    /**
     * @dev Check that an address is valid core
     * @param _address The address
     */
    function _isValidCore(address _address) internal view returns (bool) {
        if (address(core) == address(0)) {
            return false;
        }

        return _address == address(core);
    }
}
