const Config = artifacts.require("./Config.sol");
const RCCore = artifacts.require("./RCCore.sol");
const RCItemCore = artifacts.require("./RCItemCore.sol");
const RCBreeding = artifacts.require("./RCBreeding.sol");
const RCItems = artifacts.require("./RCItems.sol");
const RCSaleAuction = artifacts.require("./RCSaleAuction.sol");
const RCSiringAuction = artifacts.require("./RCSiringAuction.sol");

const FEE = 500; // It's 0.05% of value

module.exports = (deployer) => {
  let config, core, itemCore, breeding, saleAuction, siringAuction, items;

  deployer
    .deploy(Config)
    .then(() => Config.deployed())
    .then(instance => {
      config = instance;
      return deployer.deploy(RCCore);
    })
    .then(() => RCCore.deployed())
    .then(instance => {
      core = instance;
      return deployer.deploy(RCItemCore);
    })
    .then(() => RCItemCore.deployed())
    .then(instance => {
      itemCore = instance;
      return deployer.deploy(RCBreeding);
    })
    .then(() => RCBreeding.deployed())
    .then(instance => {
      breeding = instance;
      return deployer.deploy(RCItems);
    })
    .then(() => RCItems.deployed())
    .then(instance => {
      items = instance;
      return deployer.deploy(RCSaleAuction, FEE);
    })
    .then(() => RCSaleAuction.deployed())
    .then(instance => {
      saleAuction = instance;
      return deployer.deploy(RCSiringAuction, FEE);
    })
    .then(() => RCSiringAuction.deployed())

    .then(async instance => {
      siringAuction = instance;

      console.info('Setup extensions...');
      // ItemCore
      await itemCore.setup(core.address);
      await core.addExtension(itemCore.address);

      // Breeding
      await breeding.setup(core.address);
      await core.addExtension(breeding.address);

      // Items
      await items.setup(core.address);
      await core.addExtension(items.address);

      // SaleAuction
      await saleAuction.setup(core.address);
      await core.addExtension(saleAuction.address);

      // SiringAuction
      await siringAuction.setup(core.address);
      await core.addExtension(siringAuction.address);

      return true;
    })
    // Set config for all contracts
    .then(async () => {
      console.info('Setting config...');
      return await core.setConfigAddress(config.address);
    });
};
