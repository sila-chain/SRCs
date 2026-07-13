const SRC5007Demo = artifacts.require("SRC5007Demo");
const SRC5007ComposableTest = artifacts.require("SRC5007ComposableTest");

module.exports = function (deployer) {
  deployer.deploy(SRC5007Demo,'SRC5007Demo','SRC5007Demo');  
  deployer.deploy(SRC5007ComposableTest,'SRC5007ComposableTest','SRC5007ComposableTest');
};
