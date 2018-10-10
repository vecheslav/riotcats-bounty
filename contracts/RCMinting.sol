pragma solidity ^0.4.23;

import "./RCToken.sol";

contract RCMinting is RCToken {
    // Limits the number of cats the contract owner can ever create.
    uint24 public constant PROMO_CREATION_LIMIT = 5000;

    // Counts the number of cats the contract owner has created.
    uint24 public promoCreatedCount;

    /**
     * @dev We can create promo cats, up to a limit. Only callable by COO.
     * @param _genes The encoded genes of the cat to be created, any value is accepted
     * @param _owner The future owner of the created cats. Default to contract COO
     */
    function createPromoCat(uint192 _genes, address _owner) external onlyCOO {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createCat(0, 0, 0, 0, _genes, 0, uint40(block.number), _owner == address(0) ? cooAddress : _owner);
    }
}
