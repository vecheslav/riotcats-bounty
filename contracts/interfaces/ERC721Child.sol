pragma solidity ^0.4.23;

interface ERC721Child {
    function totalChildrenOf(uint256 _parentId) external view returns (uint256);
    function parentOf(uint256 _tokenId) external view returns (uint256);
    function childrenOf(uint256 _parentId) external view returns (uint256[]);

    function assignParent(uint256 _toParentId, uint256 _tokenId) external;
    function transferAsChild(address _to, uint256 _tokenId) external;
}