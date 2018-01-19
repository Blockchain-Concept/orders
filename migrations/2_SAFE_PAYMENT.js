var SAFE_PAYMENT = artifacts.require("./SAFE_PAYMENT.sol");

module.exports = function(deployer) {
  deployer.deploy(SAFE_PAYMENT);
};
