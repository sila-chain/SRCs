pragma solidity ^0.8.0;

interface IManager {
    function factory() external view returns (address);
    function influencer() external view returns (address);
    function getExampleConfig(address somsiling) external view returns (uint);
    event ConfigInitialized(address somsiling, uint example);
    event FinanceCreated(uint id, address wsil, address sender, address finance, uint input);
}
