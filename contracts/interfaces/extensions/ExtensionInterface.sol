pragma solidity ^0.4.23;

contract ExtensionInterface {
    /**
     * @dev This name must be unique for each extension
     */
    function extensionName() external pure returns (bytes32);

    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isExtension() public pure returns (bool);

    function onRemove() external;
    function onTransfer(address _from, address _to, uint256 _tokenId) external;

    function setConfigAddress(address _address) external;
    function withdraw() public;
}
