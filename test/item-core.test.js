// Activate verbose mode by setting env var `export DEBUG=rc`
const debug = require("debug")("rc");
const BigNumber = require("bignumber.js");

const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

const utils = require("./utils.js");

// Core
const Config = artifacts.require("./Config.sol");
const RCItemCore = artifacts.require("./RCItemCoreTest.sol");

contract("RCItemCore", function (accounts) {
  // This only runs once across all test suites
  before(() => utils.commonMeasureGas(accounts));
  after(() => utils.commonMeasureGas(accounts));

  const eq = assert.equal.bind(assert);
  const coo = accounts[0];
  const user1 = accounts[1];
  const user2 = accounts[2];
  const user3 = accounts[3];

  let item, config;

  const logEvents = [];
  const pastEvents = [];

  async function deployContract() {
    debug("deploying contract");

    item = await RCItemCore.new();

    // Config
    if (config === undefined) {
      config = await Config.new();
    }
    await item.setConfigAddress(config.address, { from: coo });

    // Events
    const eventsWatch = item.allEvents();
    eventsWatch.watch((err, res) => {
      if (err) return;
      pastEvents.push(res);
      debug(">>", res.event, res.args);
    });
    logEvents.push(eventsWatch);

    // Helpers
    item._getItemHelper = async function (id) {
      let attrs = await this.getItem(id);
      return {
        effects: attrs[0],
        frozen: attrs[1],
        rarity: attrs[2].toNumber(),
        group: attrs[3].toNumber(),
        requiredLevel: attrs[4].toNumber()
      };
    };
  }

  after(() => {
    logEvents.forEach(ev => ev.stopWatching());
  });

  describe("Initial state", () => {
    before(deployContract);

    it("should own contract", async () => {
      const owner = await item.owner();
      eq(coo, owner);

      const totalItems = await item.totalSupply();
      eq(totalItems.toNumber(), 0);
    });
  });

  describe("Item creation", () => {
    const baseId0 = 0, baseId1 = 1;
    const itemIds1 = 1, itemIds2 = 2, itemIds3 = 3;

    before(deployContract);

    it("create a base items", async () => {
      await item.createBaseItem(0, 0, 0, 0, { from: coo });
      await item.createBaseItem(0, 0, 0, 1, { from: coo });
    });

    it("add promo items", async function () {
      await item.addPromoItem(baseId0, NULL_ADDRESS, { from: coo });
      await item.addPromoItem(baseId1, "", { from: coo });
      await item.addPromoItem(baseId0, "0x0", { from: coo });
      await item.transferFrom(coo, user1, itemIds3, { from: coo });

      // Only owner
      await utils.expectThrow(
        item.addPromoItem(baseId0, NULL_ADDRESS, { from: user1 })
      );

      const totalItems = await item.totalSupply();
      // 3 created
      eq(totalItems.toNumber(), 3);

      eq(coo, await item.ownerOf(itemIds1), "item 1");
      eq(coo, await item.ownerOf(itemIds2), "item 2");
      eq(user1, await item.ownerOf(itemIds3), "item 3");
    });
  });

  describe("EIP-721", () => {
    let item1, item2, item3, item4;
    before(deployContract);

    it("add a few items", async () => {
      await item.createBaseItem(0, 0, 0, 0, { from: coo });

      // Add 4 item
      await item.mintTokens(0, 5);
      item1 = 1;
      item2 = 2;
      item3 = 3;
      item4 = 4;

      const totalItems = await item.totalSupply();
      eq(totalItems.toNumber(), 5);
    });

    it("transferFrom", async () => {
      eq(await item.ownerOf(item3), coo);
      await item.transferFrom(coo, user1, item3, { from: coo });
      eq(await item.ownerOf(item3), user1);
    });

    it("approve + transferFrom", async () => {
      await item.approve(coo, item3, { from: user1 });
      eq(await item.ownerOf(item3), user1);
      await item.transferFrom(user1, coo, item3, { from: coo });
      eq(await item.ownerOf(item3), coo);
    });

    it("safeTransferFrom", async () => {
      // Transfer to contract
      await utils.expectThrow(item.safeTransferFrom(coo, item.address, item1, { from: coo }));

      eq(await item.ownerOf(item1), coo);
      await item.safeTransferFrom(coo, user1, item1, { from: coo });
      eq(await item.ownerOf(item1), user1);
    });

    it("balanceOf", async () => {
      eq(await item.balanceOf(coo), 4);
      eq(await item.balanceOf(user1), 1);
    });
  });

  describe("EIP-721 Child", () => {
    let item1, item2, item3;
    let parent1 = 1, parent2 = 2;
    before(deployContract);

    it("add a few items", async () => {
      await item.createBaseItem(0, 0, 0, 0, { from: coo });

      // Add 4 item
      await item.mintTokens(0, 3);
      item1 = 1;
      item2 = 2;
      item3 = 3;

      await item.transferFrom(coo, user1, item3);

      const totalItems = await item.totalSupply();
      eq(totalItems.toNumber(), 3);
    });

    it("try assign to parent", async () => {
      // Only owner
      await utils.expectThrow(item.assignParentByOwner(parent1, item1, { from: user1 }));

      // Release item
      await item.assignParentByOwner(0, item1, { from: coo });

      // Assign to parent
      await item.assignParentByOwner(parent1, item1, { from: coo });

      eq(await item.parentOf(item1), parent1);
    });

    it("check total children of parents", async () => {
      let totalChildren = await item.totalChildrenOf(parent1);
      eq(totalChildren.toNumber(), 1);

      totalChildren = await item.totalChildrenOf(parent2);
      eq(totalChildren.toNumber(), 0);
    });

    it("change parent", async () => {
      await item.assignParentByOwner(parent2, item1, { from: coo });

      eq(await item.parentOf(item1), parent2);
    });

    it("assign item to parent with another item the same group (slot)", async () => {
      await item.assignParentByOwner(parent2, item2, { from: coo });

      eq(await item.parentOf(item1), 0);
      eq(await item.parentOf(item2), parent2);
    });

    it("try assign frozen item", async () => {
      await item.freeze(0, true, { from: coo });
      await utils.expectThrow(item.assignParentByOwner(parent1, item2, { from: coo }));

      // Release frozen item
      await item.assignParentByOwner(0, item2, { from: coo });
      await item.freeze(0, false, { from: coo });

      await item.assignParentByOwner(parent1, item2, { from: coo });

      eq(await item.parentOf(item2), parent1);
    });
  });
});