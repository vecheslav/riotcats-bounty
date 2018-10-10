const GeneScience = artifacts.require("./GeneScience.sol");

module.exports = function(deployer) {
  deployer.deploy(GeneScience);
};
