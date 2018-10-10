// Activate verbose mode by setting env var `export DEBUG=rc`
const debug = require("debug")("rc");
const BigNumber = require("bignumber.js");

const utils = require("./utils.js");

const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";
const FEE = 500; // It's 0.05% of value

// Core
const Config = artifacts.require("./ConfigTest.sol");
const RCCore = artifacts.require("./RCCoreTest.sol");
const ItemCore = artifacts.require("./RCItemCoreTest.sol");
const GeneScienceMock = artifacts.require("./test/contracts/GeneScienceMock.sol")

// Extensions
const RCExtensionTest = artifacts.require("./RCExtensionTest.sol");
const RCBreeding = artifacts.require("./RCBreeding.sol");
const RCItems = artifacts.require("./RCItems.sol");
const RCSaleAuction = artifacts.require("./RCSaleAuction.sol");
const RCSiringAuction = artifacts.require("./RCSiringAuction.sol");

contract("RCCore", function (accounts) {
  // This only runs once across all test suites
  before(() => utils.commonMeasureGas(accounts));
  after(() => utils.commonMeasureGas(accounts));

  const eq = assert.equal.bind(assert);
  const coo = accounts[0];
  const user1 = accounts[1];
  const user2 = accounts[2];
  const user3 = accounts[3];
  const ceo = accounts[4];
  const cfo = accounts[5];

  let config, core, itemCore, extensionTest, breeding, geneScience, items, saleAuction, siringAuction;

  let cooldowns;

  const logEvents = [];
  const pastEvents = [];

  async function deployContract() {
    debug("deploying contract");

    core = await RCCore.new();
    await core.setCEO(ceo);

    // Item Core
    itemCore = await ItemCore.new();

    // Extensions
    if (extensionTest === undefined) {
      extensionTest = await RCExtensionTest.new();
    }

    // Breeding
    if (breeding === undefined) {
      breeding = await RCBreeding.new();
    }

    // Items
    if (items === undefined) {
      items = await RCItems.new();
    }

    // RCSaleAuction
    if (saleAuction === undefined) {
      saleAuction = await RCSaleAuction.new(FEE);
    }

    // RCSiringAuction
    if (siringAuction === undefined) {
      siringAuction = await RCSiringAuction.new(FEE);
    }

    // Add extensions
    // ItemCore
    await itemCore.setup(core.address);
    await core.addExtension(itemCore.address, { from: ceo });

    // ExtensionTest
    await extensionTest.setup(core.address);
    await core.addExtension(extensionTest.address, { from: ceo });

    // Breeding
    await breeding.setup(core.address);
    await core.addExtension(breeding.address, { from: ceo });

    // Items
    await items.setup(core.address);
    await core.addExtension(items.address, { from: ceo });

    // RCSaleAuction
    await saleAuction.setup(core.address);
    await core.addExtension(saleAuction.address, { from: ceo });

    // RCSiringAuction
    await siringAuction.setup(core.address);
    await core.addExtension(siringAuction.address, { from: ceo });

    // Gene Science
    if (geneScience === undefined) {
      geneScience = await GeneScienceMock.new();
    }
    await breeding.setGeneScienceAddress(geneScience.address);

    // Config
    if (config === undefined) {
      config = await Config.new();
    }
    await core.setConfigAddress(config.address, { from: ceo });

    if (!cooldowns) {
      cooldowns = [];
      for (let i = 0; i < 6; i++) {
        cooldowns[i] = (await config.cooldowns.call(i)).toNumber();
      }
      debug("cooldowns", cooldowns);
    }

    // Unpause
    await core.unpause({ from: ceo });

    // Events
    const eventsWatch = core.allEvents();
    eventsWatch.watch((err, res) => {
      if (err) return;
      pastEvents.push(res);
      debug(">>", res.event, res.args);
    });
    logEvents.push(eventsWatch);
  }

  after(() => {
    logEvents.forEach(ev => ev.stopWatching());
  });

  describe("Initial state", () => {
    before(deployContract);

    it("should own contract", async () => {
      const cooAddress = await core.cooAddress();
      eq(cooAddress, coo);

      const totalCats = await core.totalSupply();
      eq(totalCats.toNumber(), 0);
    });
  });

  describe("Extensions", () => {
    let cat1 = 1, cat2 = 2;
    before(async function () {
      await deployContract();

      await core.mintTokens(1000, 2);
    });

    it("call method from extension to change genes", async () => {
      eq(await core.getGenes(cat1), 1000);

      await extensionTest.setGenes(cat1, 2000);

      eq(await core.getGenes(cat1), 2000);
    });

    it("call transfer method from extension", async () => {
      // Non-existent cat
      await utils.expectThrow(extensionTest.escrow(3, user1));

      // Only owner
      await utils.expectThrow(extensionTest.escrow(cat1, user1, { from: user1 }));

      await extensionTest.escrow(cat1, user1);

      eq(await core.ownerOf(cat1), user1);
    });

    it("call extension method from core by name", async () => {
      // From non extensions
      await utils.expectThrow(extensionTest.setNumber(2));

      await core.increaseNumberOnExtension({ from: coo });

      const number = await extensionTest.testNumber();
      eq(number.toNumber(), 2);
    });

    it("configure exist extension", async () => {
      // Non core
      await utils.expectThrow(extensionTest.setup(extensionTest.address));

      extensionTest.setup(core.address)
    });

    it("remove extension and try call core method", async () => {
      await extensionTest.setGenes(cat1, 1000);

      await core.removeExtension(extensionTest.address, { from: ceo });

      await utils.expectThrow(extensionTest.setGenes(cat1, 2000));
    });
  });

  describe("Cat creation", () => {
    before(deployContract);

    it("create a promotional cats", async () => {
      await core.createPromoCat(1000, NULL_ADDRESS, { from: coo });
      await core.createPromoCat(2000, "", { from: coo });
      await core.createPromoCat(3000, "0x0", { from: coo });
      await core.createPromoCat(4000, user2, { from: coo });

      // Only coo
      await utils.expectThrow(core.createPromoCat(5000, user1, { from: user1 }));

      const totalCats = await core.totalSupply();
      // 4 created
      eq(totalCats.toNumber(), 4);

      eq(coo, await core.ownerOf(1), "Cat 1");
      eq(coo, await core.ownerOf(2), "Cat 2");
      eq(coo, await core.ownerOf(3), "Cat 3");
      eq(user2, await core.ownerOf(4), "Cat 4");
    });
  });

  describe("EIP-721", () => {
    let cat1, cat2, cat3, cat4;
    before(deployContract);

    it("create a few cats", async () => {
      // Add 4 cats
      await core.mintTokens(1000, 5);
      cat1 = 1;
      cat2 = 2;
      cat3 = 3;
      cat4 = 4;

      const totalCats = await core.totalSupply();
      eq(totalCats.toNumber(), 5);
    });

    it("transferFrom", async () => {
      eq(await core.ownerOf(cat3), coo);
      await core.transferFrom(coo, user1, cat3, { from: coo });
      eq(await core.ownerOf(cat3), user1);
    });

    it("approve + transferFrom", async () => {
      await core.approve(coo, cat3, { from: user1 });
      eq(await core.ownerOf(cat3), user1);
      await core.transferFrom(user1, coo, cat3, { from: coo });
      eq(await core.ownerOf(cat3), coo);
    });

    it("safeTransferFrom", async () => {
      // Transfer to contract
      await utils.expectThrow(core.safeTransferFrom(coo, core.address, cat1, { from: coo }));

      eq(await core.ownerOf(cat1), coo);
      await core.safeTransferFrom(coo, user1, cat1, { from: coo });
      eq(await core.ownerOf(cat1), user1);
    });

    it("balanceOf", async () => {
      eq(await core.balanceOf(coo), 4);
      eq(await core.balanceOf(user1), 1);
    });
  });

  describe("Roles: CEO + CFO", () => {
    it("COO try to appoint another COO, but cant", async () => {
      // That is the case because we override OZ ownable function
      await utils.expectThrow(core.setCOO(user2));
    });
    it("CEO can appoint a CFO", async () => {
      await utils.expectThrow(core.setCFO(cfo));
      await core.setCFO(cfo, { from: ceo });
    });
    it("CEO can appoint another coo", async () => {
      await core.setCOO(user1, { from: ceo });
    });
    it("new coo can do things, old coo cant anymore", async () => {
      await utils.expectThrow(core.mintTokens(10, 1, { from: coo }));
      await core.mintTokens(10, 1, { from: user1 });
    });
    it("CEO can appoint another CEO", async () => {
      await utils.expectThrow(core.setCEO(user2, { from: coo }));
      await core.setCEO(user2, { from: ceo });
    });
    it("old CEO cant do anything since they were replaced", async () => {
      await utils.expectThrow(core.setCEO(user3, { from: ceo }));
      await core.setCEO(ceo, { from: user2 });
    });
    it("CFO can drain funds", async () => {
      await core.fundMe({value: web3.toWei(0.05, 'ether')});
      const ctoBalance1 = web3.eth.getBalance(cfo);
      debug("cfo balance was", ctoBalance1);
      await core.withdraw({ from: cfo });
      const ctoBalance2 = web3.eth.getBalance(cfo);
      debug("cfo balance is ", ctoBalance2);
      assert(ctoBalance2.gt(ctoBalance1));
    });
  });

  describe("Breeding", () => {
    let cat1, cat2, cat3, cat4;
    before(async function () {
      await deployContract();

      await core.mintTokens(10, 4, { from: coo });
      cat1 = 1;
      cat2 = 2;
      cat3 = 3;
      cat4 = 4;

      // give cat4 to user1
      await core.transferFrom(coo, user1, cat4);
    });

    it("cat can\'t sire itself", async () => {
      await utils.expectThrow(breeding.breedWithOwn(cat1, cat1));
    });

    it("breed own cats", async () => {
      await breeding.breedWithOwn(cat1, cat2);
    });

    it("sire has cooldown after breeding", async () => {
      await utils.expectThrow(breeding.breedWithOwn(cat3, cat1));
      await utils.expectThrow(breeding.breedWithOwn(cat1, cat3));
    });
  });

  describe("Items", () => {
    let cat1 = 1, cat2 = 2, cat3 = 3;
    let item1 = 1, item2 = 2, item3 = 3, item4 = 4;
    let equipment12 = 8589934593; // 1 + 2 item

    before(async function () {
      await deployContract();

      await core.mintTokens(10, 3, { from: coo });

      // give cat3 to user1
      await core.transferFrom(coo, user1, cat3);

      await itemCore.createBaseItem(0, 0, 0, 0, { from: coo });
      await itemCore.createBaseItem(0, 0, 1, 0, { from: coo });

      // Add 3 item
      await itemCore.addPromoItem(0, NULL_ADDRESS, { from: coo });

      await itemCore.mintTokens(1, 2);
      await itemCore.transferFrom(coo, user1, item3);

      await itemCore.createBaseItem(0, 0, 0, 1, { from: coo });
    });

    it("equip item", async () => {
      // Checks owner of cat & items
      await utils.expectThrow(items.equip(cat1, item1, { from: user1 }));
      await utils.expectThrow(items.equip(cat1, item3, { from: user1 }));
      await utils.expectThrow(items.equip(cat1, item3, { from: coo }));

      // Try assign the same equipment
      await utils.expectThrow(items.equip(cat1, 0, { from: coo }));

      await items.equip(cat1, item1, { from: coo });

      const totalChildren = await itemCore.totalChildrenOf(cat1);
      eq(totalChildren.toNumber(), 1);
    });

    it("equip few items", async () => {
      await items.equip(cat1, equipment12, { from: coo });

      const totalChildren = await itemCore.totalChildrenOf(cat1);
      eq(totalChildren.toNumber(), 2);
    });

    it("unequip items", async () => {
      await items.equip(cat1, 0, { from: coo });

      const totalChildren = await itemCore.totalChildrenOf(cat1);
      eq(totalChildren.toNumber(), 0);
    });

    it("try equip frozen item", async () => {
      await items.equip(cat1, item1);

      await itemCore.freeze(0, true);
      await utils.expectThrow(items.equip(cat2, item1));

      // Release frozen item
      await items.equip(cat1, 0);
      await itemCore.freeze(0, false);

      await items.equip(cat2, item1);

      eq(await itemCore.parentOf(item1), cat2);
    });

    it("transfer cat with equipment", async () => {
      eq(await itemCore.ownerOf(item1), coo);

      await core.transferFrom(coo, user1, cat2, { from: coo });

      eq(await itemCore.ownerOf(item1), user1);
    });

    it("cat can't equip item with more required level", async () => {
      await utils.expectThrow(items.equip(cat1, item4));

      await items.equip(cat1, item2);

      eq(await itemCore.parentOf(item2), cat1);
    });
  });

  describe("Auctions", () => {
    const cat1 = 1, cat2 = 2, cat3 = 3, cat5 = 5;

    before(async function () {
      await deployContract();

      await core.mintTokens(1000, 3, { from: coo });
      await core.transferFrom(coo, user1, cat2, { from: coo });
      await core.transferFrom(coo, user1, cat3, { from: coo });
    });

    it("should fail to create sale auction if not cat owner", async () => {
      await utils.expectThrow(saleAuction.createAuction(cat1, 100, 200, 60, false, { from: user1 }));
    });

    it("should be able to create sale auction with clean-up equipment", async () => {
      await saleAuction.createAuction(cat1, 100, 200, 60, false, { from: coo });
      const cat1Owner = await core.ownerOf(cat1);
      eq(cat1Owner, saleAuction.address);
    });

    it("should fail to breed if sire is on sale auction", async () => {
      await utils.expectThrow(breeding.breedWithOwn(cat2, cat1, { from: user1 }));
    });

    it("should be able to bid on sale auction", async () => {
      const cooBalance1 = await web3.eth.getBalance(coo);
      await saleAuction.bid(cat1, { from: user1, value: 200 });
      const cooBalance2 = await web3.eth.getBalance(coo);

      const cat1Owner = await core.ownerOf(cat1);

      eq(cat1Owner, user1);
      assert(cooBalance2.gt(cooBalance1));

      // Transfer the cat back to coo for the rest of the tests
      await core.transferFrom(user1, coo, cat1, { from: user1 });
    });

    it("should fail to create siring auction if not cat owner", async () => {
      await utils.expectThrow(siringAuction.createAuction(cat1, 100, 200, 60, { from: user1 }));
    });

    it("should be able to create siring auction", async () => {
      await siringAuction.createAuction(cat1, 100, 200, 60, { from: coo });
      const cat1Owner = await core.ownerOf(cat1);
      eq(cat1Owner, siringAuction.address);
    });

    it("should fail to breed if sire is on siring auction", async () => {
      await utils.expectThrow(breeding.breedWithOwn(cat2, cat1, { from: user1 }));
    });

    it("should fail to bid on siring auction if matron is in cooldown", async () => {
      // Breed, putting cat 2 into cooldown
      await breeding.breedWithOwn(cat3, cat2, { from: user1 });

      await utils.expectThrow(siringAuction.bid(cat1, cat2, { from: user1, value: 200 }));

      // Forward time so cooldowns end before next test
      await utils.forwardEVMBlock(cooldowns[0]);
    });

    it("should be able to bid on siring auction", async () => {
      const cooBalance1 = await web3.eth.getBalance(coo);
      await siringAuction.bid(cat1, cat2, { from: user1, value: 200 });
      const cooBalance2 = await web3.eth.getBalance(coo);

      const cat1Owner = await core.ownerOf(cat1);
      const cat2Owner = await core.ownerOf(cat2);
      // Child
      const cat5Owner = await core.ownerOf(cat5);
      eq(cat1Owner, coo);
      eq(cat2Owner, user1);
      eq(cat5Owner, user1);

      assert(cooBalance2.gt(cooBalance1));

      await utils.forwardEVMBlock(cooldowns[1]);
    });

    it("should be able to cancel a sale auction", async () => {
      await saleAuction.createAuction(cat1, 100, 200, 60, false, { from: coo });
      await saleAuction.cancelAuction(cat1, { from: coo });

      const cat1Owner = await core.ownerOf(cat1);
      eq(cat1Owner, coo);
    });

    it("should be able to cancel a siring auction", async () => {
      await siringAuction.createAuction(cat1, 100, 200, 60, { from: coo });
      await siringAuction.cancelAuction(cat1, { from: coo });

      const cat1Owner = await core.ownerOf(cat1);
      eq(cat1Owner, coo);
    });
  });

  describe("Items + Auction", () => {
    let cat1 = 1, cat2 = 2;
    let item1 = 1, item2 = 2;
    let equipment12 = 8589934593; // 1 + 2 item

    before(async function () {
      await deployContract();

      await core.mintTokens(10, 2, { from: coo });

      await itemCore.createBaseItem(0, 0, 0, 0, { from: coo });
      await itemCore.createBaseItem(0, 0, 1, 0, { from: coo });

      await itemCore.addPromoItem(0, NULL_ADDRESS, { from: coo });
      await itemCore.addPromoItem(1, NULL_ADDRESS, { from: coo });
    });

    it("create auction with equipment", async () => {
      await items.equip(cat1, equipment12);
      await saleAuction.createAuction(cat1, 100, 200, 60, false);

      eq(await itemCore.ownerOf(item1), saleAuction.address);
      eq(await itemCore.ownerOf(item2), saleAuction.address);
    });

    it("bid on sale auction with equipment", async () => {
      await saleAuction.bid(cat1, { from: user1, value: 200 });

      eq(await itemCore.ownerOf(item1), user1);
      eq(await itemCore.ownerOf(item2), user1);
    });

    it("create auction without equipment", async () => {
      await saleAuction.createAuction(cat1, 100, 200, 60, true, { from: user1 });

      eq(await itemCore.ownerOf(item1), user1);
      eq(await itemCore.ownerOf(item2), user1);
    });
  });
});