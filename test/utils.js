// this web3 is injected:
web3.BigNumber.config({ EXPONENTIAL_AT: 100 });

const secondsPerBlock = 15;

const promisify = inner =>
  new Promise((resolve, reject) =>
    inner((err, res) => {
      if (err) {
        reject(err);
      }
      resolve(res);
    })
  );

// Took this from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/test/helpers/expectThrow.js
// Doesn't seem to work any more :(
// Changing to use the invalid opcode error instead works
const expectThrow = async promise => {
  try {
    await promise;
  } catch (error) {
    // TODO: Check jump destination to destinguish between a throw
    //       and an actual invalid jump.
    const invalidOpcode = error.message.search('invalid opcode') >= 0;
    // TODO: When we contract A calls contract B, and B throws, instead
    //       of an 'invalid jump', we get an 'out of gas' error. How do
    //       we distinguish this from an actual out of gas event? (The
    //       testrpc log actually show an 'invalid jump' event.)
    const outOfGas = error.message.search('out of gas') >= 0;
    const revert = error.message.search('revert') >= 0;
    assert(
      invalidOpcode || outOfGas || revert,
      'Expected throw, got \'' + error + '\' instead',
    );
    return;
  }
  assert.fail('Expected throw not received');
};

// Works for testrpc v4.1.3
const mineOneBlock = async () => {
  await web3.currentProvider.send({
    jsonrpc: "2.0",
    method: "evm_mine",
    params: [],
    id: 0
  });
};

const mineNBlocks = async n => {
  for (let i = 0; i < n; i++) {
    await mineOneBlock();
  }
};

// modified from: https://ethereum.stackexchange.com/questions/4027/how-do-you-get-the-balance-of-an-account-using-truffle-ether-pudding
const getBalance = async addr => {
  const res = await promisify(cb => web3.eth.getBalance(addr, cb));
  return new web3.BigNumber(res);
};

const getGasPrice = () => {
  return promisify(web3.eth.getGasPrice);
};

const forwardEVMBlock = async seconds => {
  const blocksCount = Math.ceil(seconds / secondsPerBlock);
  await mineNBlocks(blocksCount);
};

const forwardEVMTime = async seconds => {
  await web3.currentProvider.send({
    jsonrpc: "2.0",
    method: "evm_increaseTime",
    params: [seconds],
    id: 0
  });
  await mineOneBlock();
};

let commonLastBalance;
// First call stores the balance sum, second call prints the difference
const commonMeasureGas = async accounts => {
  let balanceSum = new web3.BigNumber(0);
  // only checks the first 8 accounts
  for (let i = 0; i <= 7; i++) {
    balanceSum = balanceSum.add(await getBalance(accounts[i]));
  }
  // first run of this function
  if (!commonLastBalance) {
    commonLastBalance = balanceSum;
  } else {
    // diff and inform the difference
    console.log(
      "Gas spent on test suite:",
      commonLastBalance.sub(balanceSum).toString()
    );
    commonLastBalance = null;
  }
};

let lastBalance;
// First call stores the balance sum, second call prints the difference
const measureGas = async accounts => {
  let balanceSum = new web3.BigNumber(0);
  // only checks the first 8 accounts
  for (let i = 0; i <= 7; i++) {
    balanceSum = balanceSum.add(await getBalance(accounts[i]));
  }
  // first run of this function
  if (!lastBalance) {
    lastBalance = balanceSum;
  } else {
    // diff and inform the difference
    console.log(
      "Gas spent:",
      lastBalance.sub(balanceSum).toString()
    );
    lastBalance = null;
  }
};

module.exports = {
  forwardEVMTime,
  forwardEVMBlock,
  expectThrow,
  getBalance,
  getGasPrice,
  commonMeasureGas,
  measureGas,
};