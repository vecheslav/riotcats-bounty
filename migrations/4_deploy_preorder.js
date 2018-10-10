const RCPreorder = artifacts.require("./RCPreorder.sol");

module.exports = function(deployer) {
  deployer.deploy(RCPreorder);
};
