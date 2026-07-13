const SRC4907Demo = artifacts.require("SRC4907Demo");

module.exports = function (deployer) {
  deployer.deploy(SRC4907Demo, "SRC4907Demo", "SRC4907Demo");
};
