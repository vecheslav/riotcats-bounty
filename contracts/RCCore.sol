pragma solidity ^0.4.23;

import "./RCMinting.sol";

contract RCCore is RCMinting {
    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /**
     * @notice Creates the main RiotCats smart contract instance.
     */
    constructor() public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // start with the mythical cat 0 - so we don't have generation-0 parent issues
        _createCat(0, 0, 0, 0, uint192(-1), 0, 0, address(0));
    }

    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isRCCore() public pure returns (bool) {
        return true;
    }

    /**
     * @notice No tipping!
     * @dev Reject all Ether from being sent here, unless it's from one of the
     * two auction contracts. (Hopefully, we can prevent user accidents.)
     */
     function() external payable {
         require(
             address(extensions[msg.sender]) != address(0)
         );
     }

    /**
     * @notice Returns all the relevant original information about a specific cat.
     * @param _id The identifier
     */
    function getCat(uint32 _id)
        external
        view
        returns (
            uint192 genes,
            uint104 character,
            uint40 birthBlock,
            uint40 breedCooldownEnd,
            uint40 fightCooldownEnd,
            uint32 matronId,
            uint32 sireId,
            uint16 cooldownIndex,
            uint16 generation
        )
    {
        Cat storage cat = cats[_id];

        genes = cat.genes;
        character = cat.character;
        birthBlock = cat.birthBlock;
        breedCooldownEnd = cat.breedCooldownEnd;
        fightCooldownEnd = cat.fightCooldownEnd;
        matronId = cat.matronId;
        sireId = cat.sireId;
        cooldownIndex = cat.cooldownIndex;
        generation = cat.generation;
    }

    /**
     * @dev Update the address of the config contract.
     * @param _address An address of a Config contract instance to be used from this point forward.
     */
    function setConfigAddress(address _address) external onlyCEO {
        _setConfigAddress(_address);

        // In extensions
        for (uint16 i = 0; i < extensionsCollection.length; i++) {
            extensionsCollection[i].setConfigAddress(_address);
        }
    }

    /**
     * @dev Collect balances from external contracts
     */
    function collect() external onlyCLevel {
        // From extensions
        for (uint16 i = 0; i < extensionsCollection.length; i++) {
            extensionsCollection[i].withdraw();
        }
    }

    /**
     * @dev Allows the CFO to capture the balance available to the contract.
     */
    function withdraw() external onlyCFO {
        cfoAddress.transfer(address(this).balance);
    }

    /**
     * @dev Override unpause so it requires all external contract addresses
     * to be set before contract can be unpaused. Also, we can't have
     * newContractAddress set either, because then the contract was upgraded.
     */
    function unpause() public onlyCEO whenPaused {
        require(config != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    /**
     * @dev Used to mark the smart contract as upgraded, in case there is a serious
     * breaking bug. This method does nothing but keep track of the new contract and
     * emit a message indicating that the new address is set. It's up to clients of this
     * contract to update to the new contract address in that case. (This contract will
     * be paused indefinitely if such an upgrade takes place.)
     * @param _v2Address The new address
     */
    function setNewAddress(address _v2Address) public onlyCEO whenPaused {
        require(_v2Address != address(0));
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }
}
