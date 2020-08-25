var streamPayOfFixedFlowrate = artifacts.require("./streamPayOfFixedFlowrate.sol");

module.exports = function(deployer) {
  deployer.deploy(streamPayOfFixedFlowrate);
};
