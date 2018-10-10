pragma solidity ^0.4.23;

import "../interfaces/ERC721TokenReceiver.sol";
import "../interfaces/ERC721.sol";
import "../utils/Strings.sol";
import "../utils/Uints.sol";
import "./RCItemBase.sol";
import "../interfaces/ERC721Child.sol";

contract RCItemToken is RCItemBase, ERC721, ERC721Child {
    using Strings for string;
    using Uints for uint;

    function name() external pure returns (string) {
        return "RiotCatsItems";
    }

    function symbol() external pure returns (string) {
        return "RCI";
    }

    string public metadataUrlPrefix = "https://api.riotcats.co/items/";
    string public metadataUrlSuffix = "token";

    /**
     * @notice Returns the number of Items owned by a specific address.
     * @dev Required for ERC-721 compliance
     * @param _owner The owner address to check.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return ownershipTokenCount[_owner];
    }

    /**
     * @notice Returns the address currently assigned ownership of a given Item.
     * @dev Required for ERC-721 compliance.
     * @param _tokenId The token identifier
     */
    function ownerOf(uint256 _tokenId)
        external
        view
        less32Bits(_tokenId)
        returns (address owner)
    {
        owner = itemIndexToOwner[uint32(_tokenId)];

        require(owner != address(0));
    }

    /**
     * @notice Returns the total number of parent's children currently is assigned.
     * @param _parentId The parent identifier
     */
    function totalChildrenOf(uint256 _parentId)
        external
        view
        returns (uint256 totalChildren)
    {
        for (uint8 i = 0; i < SLOTS_LIMIT; i++) {
            if (parentIndexToItemIds[_parentId][i] > 0) {
                totalChildren++;
            }
        }
    }

    /**
     * @notice Get parent of a token
     * @param _tokenId The token identifier
     */
    function parentOf(uint256 _tokenId)
        external
        view
        less32Bits(_tokenId)
        returns (uint256 parentTokenId)
    {
        parentTokenId = itemIndexToParent[uint32(_tokenId)];
    }

    /**
     * @notice Returns the all children of specified parent.
     * @param _parentId The parent identifier
     */
    function childrenOf(uint256 _parentId)
        external
        view
        returns (uint256[])
    {
        uint256[] memory children = new uint256[](SLOTS_LIMIT);
        for (uint8 i = 0; i < SLOTS_LIMIT; i++) {
            children[i] = uint256(parentIndexToItemIds[_parentId][i]);
        }

        return children;
    }

    /**
     * @dev Assign item as child of specified token.
     * @param _toParentId The target parent identifier
     * @param _tokenId The item identifier
     */
    function assignParent(uint256 _toParentId, uint256 _tokenId)
        external
        onlyCoreOrExtensions
        less32Bits(_tokenId)
    {
        uint256 fromParentId = itemIndexToParent[uint32(_tokenId)];

        _assign(fromParentId, _toParentId, uint32(_tokenId));
    }

    /**
     * @notice Grant another address the right to transfer a specific Item via
     * transferFrom(). This is the preferred flow for transfering NFTs to contracts.
     * @dev Required for ERC-721 compliance.
     * @param _to The address to be granted transfer approval. Pass address(0) to clear all approvals.
     * @param _tokenId The ID of the Item that can be transferred if this call succeeds.
     */
    function approve(address _to, uint256 _tokenId)
        external
        whenNotPaused
        less32Bits(_tokenId)
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, uint32(_tokenId)));

        // Register the approval (replacing any previous approval).
        _approve(uint32(_tokenId), _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if _tokenId is not a valid NFT
     * @param _tokenId The token identifier
     */
    function getApproved(uint256 _tokenId)
        external
        view
        less32Bits(_tokenId)
        returns (address)
    {
        if (itemIndexToApproved[uint32(_tokenId)] != address(0)) {
            return itemIndexToApproved[uint32(_tokenId)];
        }

        address owner = itemIndexToOwner[uint32(_tokenId)];
        return addressToApprovedAll[owner];
    }

    /**
     * @notice Enable or disable approval for a third party (operator) to manage
     * all your asset.
     * @dev Emits the ApprovalForAll event
     * @param _operator The operator
     * @param _approved The approved
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        if (_approved) {
            addressToApprovedAll[msg.sender] = _operator;
        } else {
            delete addressToApprovedAll[msg.sender];
        }

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The owner
     * @param _operator The operator
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _isApprovedForAll(_owner, _operator);
    }

    /**
     * @notice Transfer a Item owned by another address.
     * @dev Required for ERC-721 compliance.
     * @param _from The address that owns the Item to be transfered.
     * @param _to The address that should take ownership of the Item. Can be any address, including the caller.
     * @param _tokenId The ID of the Item to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        less32Bits(_tokenId)
    {
        require(_to != address(0));

        // Check for approval and valid ownership
        require(_canTransfer(_from, uint32(_tokenId)));
        require(_owns(_from, uint32(_tokenId)));

        // Release item
        _release(uint32(_tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, uint32(_tokenId));
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data)
        external
        whenNotPaused
        less32Bits(_tokenId)
    {
        require(_to != address(0));
        require(_to != address(this));

        // Check for approval and valid ownership
        require(_canTransfer(_from, uint32(_tokenId)));
        require(_owns(_from, uint32(_tokenId)));

        _release(uint32(_tokenId));

        // Reassign ownership, clearing pending approvals and emitting Transfer event.
        _transfer(_from, _to, uint32(_tokenId));
        ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        less32Bits(_tokenId)
    {
        require(_to != address(0));
        require(_to != address(this));

        // Check for approval and valid ownership
        require(_canTransfer(_from, uint32(_tokenId)));
        require(_owns(_from, uint32(_tokenId)));

        _release(uint32(_tokenId));

        // Reassign ownership, clearing pending approvals and emitting Transfer event.
        _transfer(_from, _to, uint32(_tokenId));
    }

    /**
     * @notice Transfer a Item owned by another address by parent contract.
     * This method is available only for parent contract/extensions.
     * The parent token is saved!
     * @dev Required for ERC-721 Child compliance.
     * @param _to The address that should take ownership of the Item. Can be any address, including the caller.
     * @param _tokenId The ID of the Item to be transferred.
     */
    function transferAsChild(address _to, uint256 _tokenId)
        external
        onlyCoreOrExtensions
        whenNotPaused
        less32Bits(_tokenId)
    {
        require(_to != address(0));

        address from = itemIndexToOwner[uint32(_tokenId)];

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(from, _to, uint32(_tokenId));
    }

    /**
     * @notice Returns the total number of Items currently in existence.
     * @dev Required for ERC-721 compliance.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @notice Enumerate valid NFTs
     * @param _index The index
     * @return The token identifier for the `_index`th NFT
     */
    function tokenByIndex(uint256 _index) external pure returns (uint256) {
        return _index;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        uint32 count = 0;
        for (uint32 i = 1; i <= _totalSupply(); ++i) {
            if (itemIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }

    /**
     * @dev A distinct Uniform Resource Identifier (URI) for a given asset.
     * @param _tokenId The token identifier
     */
    function tokenURI(uint256 _tokenId) external view returns (string) {
        return metadataUrlPrefix.concat((_tokenId.toString()).concat(metadataUrlSuffix));
    }

    function setMetadataUrl(string _metadataUrlPrefix, string _metadataUrlSuffix) public onlyOwner {
        metadataUrlPrefix = _metadataUrlPrefix;
        metadataUrlSuffix = _metadataUrlSuffix;
    }

    /**
     * @dev Checks if a given address is the current owner of a particular Item.
     * @param _claimant The address we are validating against.
     * @param _itemId Item id, only valid when > 0
     */
    function _owns(address _claimant, uint32 _itemId) internal view returns (bool) {
        return itemIndexToOwner[_itemId] == _claimant;
    }

    /**
     * @dev Checks if a given tokenId is the current parent of a particular Item.
     * @param _claimant The tokeId we are validating against.
     * @param _itemId Item id, only valid when > 0
     */
    function _isParent(uint256 _claimant, uint32 _itemId) internal view returns (bool) {
        return itemIndexToParent[_itemId] == _claimant;
    }

    /**
     * @dev Marks an address as being approved for transferFrom(), overwriting any previous
     * approval. Setting _approved to address(0) clears all transfer approval.
     * NOTE: _approve() does NOT send the Approval event. This is intentional because
     * _approve() and transferFrom() are used together for putting Items on auction, and
     * there is no value in spamming the log with Approval events in that case.
     * @param _itemId The token identifier
     * @param _approved The approved
     */
    function _approve(uint32 _itemId, address _approved) internal {
        itemIndexToApproved[_itemId] = _approved;
    }

    /**
     * @dev Checks if a given address currently has transferApproval for a particular Item.
     * @param _claimant The address we are confirming item is approved for.
     * @param _itemId Item id, only valid when > 0
     */
    function _approvedFor(address _claimant, uint32 _itemId) internal view returns (bool) {
        return itemIndexToApproved[_itemId] == _claimant;
    }

    /**
     * @dev Checks ownership or approvement for transfer
     * @param _from The from
     * @param _itemId The item identifier
     */
    function _canTransfer(address _from, uint32 _itemId) internal view returns (bool) {
        return _owns(msg.sender, _itemId) ||
               _isValidExtension(msg.sender) ||
               _isValidCore(msg.sender) ||
               _approvedFor(msg.sender, _itemId) ||
               _isApprovedForAll(_from, msg.sender);
    }

    /**
     * @dev Checks ownership for assign
     * @param _itemId The item identifier
     */
    function _canAssign(uint32 _itemId) internal view returns (bool) {
        return _owns(msg.sender, _itemId) ||
               _isValidExtension(msg.sender) ||
               _isValidCore(msg.sender);
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The owner
     * @param _operator The operator
     */
    function _isApprovedForAll(address _owner, address _operator) internal view returns (bool) {
        return addressToApprovedAll[_owner] == _operator;
    }

    /**
     * @notice Returns the total number of Items currently in existence.
     * @dev Required for ERC-721 compliance.
     */
    function _totalSupply() internal view returns (uint256) {
        return items.length - 1;
    }
}
