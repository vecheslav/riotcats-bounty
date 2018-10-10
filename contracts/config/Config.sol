pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../utils/Bits.sol";

contract Config is Ownable {
    using Bits for uint;

    // An approximation of currently how many seconds are in between blocks.
    uint32 public secondsPerBlock = 15;
    
    /**
     * @dev A lookup table indicating the cooldown duration after any successful
     * breeding action, called "pregnancy time" for matrons and "siring cooldown"
     * for sires.
     */
    uint32[6] public cooldowns = [
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(1 weeks),
        uint32(2 weeks),
        uint32(4 weeks)
    ];

    uint32 public fightCooldown = 1 hours;

    // Number of available equipment for current version (max 5)
    uint8 public numOfEquipment = 3;

    /**
     * @dev Simply a boolean to indicate this is the contract we expect to be
     */
    function isConfig() public pure returns (bool) {
        return true;
    }

    function getBreedCooldownEnd(uint16 _cooldownIndex) external view returns (uint40) {
        return uint40((cooldowns[_cooldownIndex] / secondsPerBlock) + block.number);
    }

    function getFightCooldownEnd() external view returns (uint40) {
        return uint40((fightCooldown / secondsPerBlock) + block.number);
    }

    function getCooldownIndex(uint16 _generation) external view returns (uint16) {
        uint16 cooldownIndex = _generation / 2;
        uint16 maxCooldownIndex = uint16(cooldowns.length - 1);

        if (cooldownIndex > maxCooldownIndex) {
            cooldownIndex = maxCooldownIndex;
        }

        return cooldownIndex;
    }

    function getChildGeneration(uint16 _generation1, uint16 _generation2) external pure returns (uint16) {
        return (_generation1 > _generation2 ? _generation2 : _generation1) + 1;
    }

    function getCharacterLevel(uint104 _character) external pure returns (uint8) {
        return uint8(uint(_character).bits(0, 8));
    }

    // Owner can fix how many seconds per blocks are currently observed.
    function setSecondsPerBlock(uint32 _secs) external onlyOwner {
        secondsPerBlock = _secs;
    }
}
