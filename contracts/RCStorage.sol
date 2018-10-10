pragma solidity ^0.4.23;

import "./utils/Utils.sol";
import "./RCExtensions.sol";

contract RCStorage is RCExtensions, Utils {
    event GenesChanged(uint32 indexed id, uint192 oldValue, uint192 newValue);
    event CharacterChanged(uint32 indexed id, uint104 oldValue, uint104 newValue);
    event BreedCooldownEndChanged(uint32 indexed id, uint40 oldValue, uint40 newValue);
    event FightCooldownEndChanged(uint32 indexed id, uint40 oldValue, uint40 newValue);
    event CooldownIndexChanged(uint32 indexed id, uint16 oldValue, uint16 newValue);
    event GenerationChanged(uint32 indexed id, uint16 oldValue, uint16 newValue);

    /**
     * @dev The main Cat struct. Every cat in game is represented by a copy of this structure.
     * Cat struct is 2x256 bits long.
     */
    struct Cat {
        // The Cat's genetic code is packed into these 192-bits, the format is
        // sooper-sekret! A cat's genes never change.
        uint192 genes;

        // The ID of the parents of this cat, set to 0 for gen0 cats.
        uint32 matronId;
        uint32 sireId;

        // The Cat's character data (eg. level, experience, stats) is packed into these 104-bits.
        // 8 (level) + 16 (experience) + 40 (stats) + 40 (reserve).
        // It can be changed at level-up/fights.
        uint104 character;

        // The block number when this cat came into existence.
        uint40 birthBlock;

        // The minimum block number after which this cat can engage in breeding
        // activities again. This same block number is used for the pregnancy
        // timer (for matrons) as well as the siring cooldown.
        uint40 breedCooldownEnd;

        // The minimum number block after which this cat can engage in fighting
        // activities again.
        uint40 fightCooldownEnd;

        // Set to the index in the cooldown array (see below) that represents
        // the current cooldown duration for this Cat.
        uint16 cooldownIndex;

        // The "generation number" of this cat. Cats minted by the core contract
        // for sale are called "gen0" and have a generation number of 0.
        uint16 generation;
    }

    /**
     * @dev An array containing the Cat struct for all cats in existence. The ID
     * of each cat is actually an index into this array. ID 0 is the parent
     * of all generation 0 cats, and both parents to itself. It is an invalid genetic code.
     */
    Cat[] cats;

    /**
     * @dev A mapping from cat IDs to the address that owns them. All cats have
     * some valid owner address, even gen0 cats are created with a non-zero owner.
     */
    mapping (uint32 => address) public catIndexToOwner;

    /**
     * @dev A mapping from owner address to count of tokens that address owns.
     * Used internally inside balanceOf() to resolve ownership count.
     */
    mapping (address => uint32) ownershipTokenCount;

    /**
     * @dev A mapping from Cat IDs to an address that has been approved to call
     * transferFrom(). Each Cat can only have one approved address for transfer
     * at any time. A zero value means no approval is outstanding.
     */
    mapping (uint32 => address) public catIndexToApproved;

    /**
     * @dev A mapping from cats owner (account) to an address that has been approved to call
     * transferFrom() for all cats, owned by owner.
     */
    mapping (address => address) public addressToApprovedAll;
    
    /**
     * Getters & setters
     */

    function getGenes(uint32 _id) public view returns (uint192 genes) {
        genes = cats[_id].genes;
    }

    function getCharacter(uint32 _id) public view returns (uint104 character) {
        character = cats[_id].character;
    }

    function getBirthBlock(uint32 _id) public view returns (uint40 birthBlock) {
        birthBlock = cats[_id].birthBlock;
    }

    function getBreedCooldownEnd(uint32 _id) public view returns (uint40 breedCooldownEnd) {
        breedCooldownEnd = cats[_id].breedCooldownEnd;
    }

    function getFightCooldownEnd(uint32 _id) public view returns (uint40 fightCooldownEnd) {
        fightCooldownEnd = cats[_id].fightCooldownEnd;
    }

    function getCooldownIndex(uint32 _id) public view returns (uint16 cooldownIndex) {
        cooldownIndex = cats[_id].cooldownIndex;
    }

    function getGeneration(uint32 _id) public view returns (uint16 generation) {
        generation = cats[_id].generation;
    }

    function setGenes(uint32 _id, uint192 _genes) public onlyExtensions {
        Cat storage cat = cats[_id];
        if (cat.genes != _genes) {
            emit GenesChanged(_id, cat.genes, _genes);
            cat.genes = _genes;
        }
    }

    function setCharacter(uint32 _id, uint104 _character) public onlyExtensions {
        Cat storage cat = cats[_id];
        if (cat.character != _character) {
            emit CharacterChanged(_id, cat.character, _character);
            cat.character = _character;
        }
    }

    function setBreedCooldownEnd(uint32 _id, uint40 _breedCooldownEnd) public onlyExtensions {
        Cat storage cat = cats[_id];
        if (cat.breedCooldownEnd != _breedCooldownEnd) {
            emit BreedCooldownEndChanged(_id, cat.breedCooldownEnd, _breedCooldownEnd);
            cat.breedCooldownEnd = _breedCooldownEnd;
        }
    }

    function setFightCooldownEnd(uint32 _id, uint40 _fightCooldownEnd) public onlyExtensions {
        Cat storage cat = cats[_id];
        if (cat.fightCooldownEnd != _fightCooldownEnd) {
            emit FightCooldownEndChanged(_id, cat.fightCooldownEnd, _fightCooldownEnd);
            cat.fightCooldownEnd = _fightCooldownEnd;
        }
    }

    function setCooldownIndex(uint32 _id, uint16 _cooldownIndex) public onlyExtensions {
        Cat storage cat = cats[_id];
        if (cat.cooldownIndex != _cooldownIndex) {
            emit CooldownIndexChanged(_id, cat.cooldownIndex, _cooldownIndex);
            cat.cooldownIndex = _cooldownIndex;
        }
    }

    function setGeneration(uint32 _id, uint16 _generation) public onlyExtensions {
        Cat storage cat = cats[_id];
        if (cat.generation != _generation) {
            emit GenerationChanged(_id, cat.generation, _generation);
            cat.generation = _generation;
        }
    }
}
