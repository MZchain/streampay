var streamPayOfInstallment = artifacts.require("./streamPayOfInstallment.sol");

module.exports = function(deployer) {
  deployer.deploy(streamPayOfInstallment);
};
