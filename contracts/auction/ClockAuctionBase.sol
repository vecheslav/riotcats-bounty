pragma solidity ^0.4.23;

import "../extensions/Extension.sol";

contract ClockAuctionBase is Extension {
    event AuctionCreated(uint32 catId, uint128 startingPrice, uint128 endingPrice, uint40 duration);
    event AuctionSuccessful(uint32 catId, uint128 totalPrice, address winner);
    event AuctionCancelled(uint32 catId);

    struct Auction {
        // Current owner of NFT
        address seller;

        // Price (in wei) at beginning of auction
        uint128 startingPrice;

        // Price (in wei) at end of auction
        uint128 endingPrice;

        // Duration (in seconds) of auction
        uint40 duration;

        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint40 startedAt;
    }

    // Cut owner takes on each auction, in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint16 public ownerFee;

    // Map from token ID to their corresponding auction.
    mapping (uint32 => Auction) catIdToAuction;

    /**
     * @dev Returns true if the claimant owns the token.
     * @param _claimant Address claiming to own the token.
     * @param _catId ID of token whose ownership to verify.
     */
    function _owns(address _claimant, uint32 _catId) internal view returns (bool) {
        return (core.ownerOf(_catId) == _claimant);
    }

    /**
     * @dev Escrows the NFT, assigning ownership to this contract.
     * Throws if the escrow fails.
     * @param _owner Current owner address of token to escrow.
     * @param _catId ID of token whose approval to verify.
     */
    function _escrow(address _owner, uint32 _catId) internal {
        core.transferFrom(_owner, address(this), _catId);
    }

    /**
     * @dev Transfers an NFT owned by this contract to another address.
     * Returns true if the transfer succeeds.
     * @param _receiver Address to transfer NFT to.
     * @param _catId ID of token to transfer.
     */
    function _transfer(address _receiver, uint32 _catId) internal {
        // It will throw if transfer fails
        core.transferFrom(address(this), _receiver, _catId);
    }

    /**
     * @dev Adds an auction to the list of open auctions. Also fires the
     * AuctionCreated event.
     * @param _catId The ID of the token to be put on auction.
     * @param _auction Auction to add.
     */
    function _addAuction(uint32 _catId, Auction _auction) internal {
        // Require that all auctions have a duration of at least one minute.
        require(_auction.duration >= 1 minutes);

        catIdToAuction[_catId] = _auction;

        emit AuctionCreated(
            _catId,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration
        );
    }

    /**
     * @dev Cancels an auction unconditionally.
     * @param _catId The cat identifier
     * @param _seller The seller
     */
    function _cancelAuction(uint32 _catId, address _seller) internal {
        _removeAuction(_catId);
        _transfer(_seller, _catId);

        emit AuctionCancelled(_catId);
    }

    /**
     * @dev Computes the price and transfers winnings.
     * Does NOT transfer ownership of token.
     * @param _catId The cat identifier
     * @param _bidAmount The bid amount
     */
    function _bid(uint32 _catId, uint128 _bidAmount)
        internal
        returns (uint128)
    {
        // Get a reference to the auction struct
        Auction storage auction = catIdToAuction[_catId];

        require(_isOnAuction(auction));

        // Check that the incoming bid is higher than the current price
        uint128 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // Grab a reference to the seller before the auction struct gets deleted.
        address seller = auction.seller;

        // Remove the auction before sending the fees to the sender so we can't have a reentrancy attack.
        _removeAuction(_catId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            //  Calculate the fee.
            uint128 fee = _computeFee(price);
            uint128 sellerProceeds = price - fee;

            seller.transfer(sellerProceeds);
        }

        // Calculate any excess funds included with the bid.
        uint128 bidExcess = _bidAmount - price;

        // Return the funds.
        msg.sender.transfer(bidExcess);

        emit AuctionSuccessful(_catId, price, msg.sender);

        return price;
    }

    /**
     * @dev Removes an auction from the list of open auctions.
     * @param _catId The cat identifier
     */
    function _removeAuction(uint32 _catId) internal {
        delete catIdToAuction[_catId];
    }

    /**
     * @dev Returns true if the NFT is on auction.
     * @param _auction The auction to check.
     */
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    /**
     * @dev Returns current price of an NFT on auction. Broken into two
     * functions (this one, that computes the duration from the auction
     * structure, and the other that does the price computation) so we
     * can easily test that the price computation works correctly.
     * @param _auction The auction
     */
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint128)
    {
        uint40 secondsPassed = 0;
        uint40 timeNow = uint40(now);

        if (timeNow > _auction.startedAt) {
            secondsPassed = timeNow - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    /**
     * @dev Computes the current price of an auction.
     * @param _startingPrice The starting price
     * @param _endingPrice The ending price
     * @param _duration The duration
     * @param _secondsPassed The seconds passed
     */
    function _computeCurrentPrice(
        uint128 _startingPrice,
        uint128 _endingPrice,
        uint40 _duration,
        uint40 _secondsPassed
    )
        internal
        pure
        returns (uint128)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int128 totalPriceChange = int128(_endingPrice) - int128(_startingPrice);
            int128 currentPriceChange = totalPriceChange * int128(_secondsPassed) / int128(_duration);

            int128 currentPrice = int128(_startingPrice) + currentPriceChange;

            return uint128(currentPrice);
        }
    }

    /**
     * @dev Computes fee of a sale.
     * @param _price Sale price of NFT.
     */
    function _computeFee(uint128 _price) internal view returns (uint128) {
        return _price * uint128(ownerFee) / 10000;
    }
}
