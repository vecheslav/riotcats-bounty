pragma solidity ^0.4.23;

import "./ClockAuctionBase.sol";

contract ClockAuction is ClockAuctionBase {

    function extensionName() external pure returns (bytes32) {
        return "ClockAuction";
    }

    constructor(uint16 _fee) public {
        require(_fee <= 10000);
        ownerFee = _fee;
    }

    /**
     * @dev Cancels an auction that hasn't been won yet.
     * Returns the NFT to original owner.
     * @notice This is a state-modifying function that can
     * be called while the contract is paused.
     * @param _catId The cat identifier
     */
    function cancelAuction(uint32 _catId)
        external
    {
        Auction storage auction = catIdToAuction[_catId];
        require(_isOnAuction(auction));

        address seller = auction.seller;
        require(msg.sender == seller);

        _cancelAuction(_catId, seller);
    }

    /**
     * @dev Cancels an auction when the contract is paused.
     * Only the owner may do this, and NFTs are returned to
     * the seller. This should only be used in emergencies.
     * @param _catId The cat identifier
     */
    function cancelAuctionWhenPaused(uint32 _catId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = catIdToAuction[_catId];
        require(_isOnAuction(auction));
        _cancelAuction(_catId, auction.seller);
    }

    /**
     * @dev Returns auction info for an NFT on auction.
     * @param _catId The cat identifier
     */
    function getAuction(uint32 _catId)
        external
        view
        returns
    (
        address seller,
        uint128 startingPrice,
        uint128 endingPrice,
        uint40 duration,
        uint40 startedAt
    ) {
        Auction storage auction = catIdToAuction[_catId];
        require(_isOnAuction(auction));

        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /**
     * @dev Returns the current price of an auction.
     * @param _catId The cat identifier
     */
    function getCurrentPrice(uint32 _catId)
        external
        view
        returns (uint128)
    {
        Auction storage auction = catIdToAuction[_catId];
        require(_isOnAuction(auction));

        return _currentPrice(auction);
    }

    /**
     * @dev Creates and begins a new auction.
     * @param _catId The cat identifier
     * @param _startingPrice The starting price
     * @param _endingPrice The ending price
     * @param _duration The duration
     * @param _seller The seller
     */
    function _createAuction(
        uint32 _catId,
        uint128 _startingPrice,
        uint128 _endingPrice,
        uint40 _duration,
        address _seller
    )
        internal
    {
        _escrow(msg.sender, _catId);

        Auction memory auction = Auction(
            _seller,
            _startingPrice,
            _endingPrice,
            _duration,
            uint40(now)
        );
        _addAuction(_catId, auction);
    }
}
