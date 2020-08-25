var TestnetDAI = artifacts.require("TestnetDAI");

module.exports = function(deployer) {
  deployer.deploy(TestnetDAI);
};
