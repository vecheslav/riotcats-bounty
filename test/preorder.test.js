// Activate verbose mode by setting env var `export DEBUG=rc`
const debug = require("debug")("rc");
const BigNumber = require("bignumber.js");

const utils = require("./utils.js");

const RCPreorder = artifacts.require("./RCPreorder.sol");

const WEEK1_PERCENT_AMOUNT = .3;
const WEEK2_PERCENT_AMOUNT = .6;
const WEEK3_PERCENT_AMOUNT = .8;
const SECONDS_IN_WEEK = 180;//604800;

contract("RCPreorder", function (accounts) {
  before(() => utils.commonMeasureGas(accounts));
  after(() => utils.commonMeasureGas(accounts));

  const eq = assert.equal.bind(assert);

  const owner = accounts[0];
  const user1 = accounts[1];

  let preorder;

  async function deployContract() {
    debug("Deploying contract");
    preorder = await RCPreorder.new();

    // Try run with new start block number
    preorder.run({ from: owner });
  }

  describe("Adding packs", function () {
    const packId0 = 0, packId1 = 1, packId2 = 2;
    const packPrice0 = 1000;
    before(deployContract);

    it("add promo packs", async function () {
      // only owner
      await utils.expectThrow(
        preorder.addPack(packId0, packPrice0, 400, { from: user1 })
      );

      await preorder.addPack(packId0, packPrice0, 400, { from: owner });
      await preorder.addPack(packId1, 2000, 400, { from: owner });
      await preorder.addPack(packId2, 3000, 200, { from: owner });

      let currentPackPrice = await preorder.getPackPrice(packId0);

      // First week price is 30% of base price
      eq(currentPackPrice.toNumber(), packPrice0 * WEEK1_PERCENT_AMOUNT);

      // TODO: for uncomment you need change WEEK_DURATION to 3 minutes
      // // Check price a week later
      // await utils.forwardEVMBlock(SECONDS_IN_WEEK);
      // currentPackPrice = await preorder.getPackPrice(packId0);
      // // Second week price is 60% of base price
      // eq(currentPackPrice.toNumber(), packPrice0 * WEEK2_PERCENT_AMOUNT);
      //
      // // Pre-sale finished
      // await utils.forwardEVMBlock(2 * SECONDS_IN_WEEK);
      //
      // // Invalid value
      // await utils.expectThrow(
      //   preorder.purchase(packId0, { value: 2000, from: user1 })
      // );
    });
  });

  describe("Purchasing", function () {
    const packId0 = 0, packId1 = 1, packId2 = 2;

    before(async function () {
      await deployContract();

      await preorder.addPack(packId0, 1000, 2, { from: owner });
      await preorder.addPack(packId1, 2000, 450, { from: owner });
      await preorder.addPack(packId2, 3000, 100, { from: owner });
    });

    it("try purchase", async function () {
      // Not available pack
      await utils.expectThrow(preorder.purchase(3, { from: user1 }));

      // Invalid value
      await utils.expectThrow(preorder.purchase(packId0, { value: 100, from: user1 }));

      let purchaseCount = await preorder.getPurchaseCount();
      eq(purchaseCount.toNumber(), 0);

      await preorder.purchase(packId0, { value: 400, from: user1 });

      purchaseCount = await preorder.getPurchaseCount();
      eq(purchaseCount.toNumber(), 1);
    });

    it("check pack\'s limit", async function () {
      await preorder.purchase(packId0, { value: 2000, from: user1 });

      await utils.expectThrow(preorder.purchase(packId0, { value: 2000, from: user1 }));

      const purchaseCount = await preorder.getPurchaseCount();
      eq(purchaseCount.toNumber(), 2);
    });
  });
});