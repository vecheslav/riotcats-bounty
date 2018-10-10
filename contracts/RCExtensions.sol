pragma solidity ^0.4.23;

import "./RCAccess.sol";
import "./interfaces/extensions/ExtensionInterface.sol";

contract RCExtensions is RCAccess {
    mapping(address => ExtensionInterface) public extensions;
    ExtensionInterface[] public extensionsCollection;

    /**
     * @dev A mapping from name of extension is necessary to call an extension's methods
     */
    mapping(bytes32 => address) extensionAddressByName;

    /**
     * @dev Access modifier for Extensions-only functionality
     */
    modifier onlyExtensions() {
        require(_isValidExtension(msg.sender));
        _;
    }

    /**
     * @dev Resolve name to address of valid extension
     * @param _extensionName The name of extension
     */
    function resolve(bytes32 _extensionName) public view returns (address) {
        return extensionAddressByName[_extensionName];
    }

    /**
     * @dev Add extension address to map of extensions
     * @param _address The address
     */
    function addExtension(address _address) external onlyCEO {
        ExtensionInterface candidateContract = ExtensionInterface(_address);
        require(candidateContract.isExtension());

        bytes32 name = candidateContract.extensionName();
        address existAddress = extensionAddressByName[name];
        require(existAddress == address(0));

        extensions[_address] = candidateContract;
        extensionsCollection.push(candidateContract);
        extensionAddressByName[name] = _address;
    }

    /**
     * @dev Remove extension address from map
     * @param _address The address
     */
    function removeExtension(address _address) external onlyCEO {
        extensions[_address].onRemove();
        bytes32 name = extensions[_address].extensionName();

        // Remove from map
        delete extensions[_address];
        delete extensionAddressByName[name];

        // Remove from collection
        uint16 i = 0;
        while (i < extensionsCollection.length) {
            if (_address == address(extensionsCollection[i])) {
                extensionsCollection[i] = extensionsCollection[extensionsCollection.length - 1];
                extensionsCollection.length--;
                break;
            }
            i++;
        }
    }

    /**
     * @dev Check that an address is valid extension
     * @param _address The address
     */
    function checkValidExtension(address _address) external view returns (bool) {
        return _isValidExtension(_address);
    }

    /**
     * @dev Check that an address is valid extension
     * @param _address The address
     */
    function _isValidExtension(address _address) internal view returns (bool) {
        return address(extensions[_address]) != address(0);
    }
}
