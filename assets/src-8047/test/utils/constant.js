/** constant of contract name */
export const CONTRACT_NAME = {
  SRC20: "MockSRC20",
  SRC8047: "MockSRC8047",
  UTXO: "MockUTXO",
};

/** constant of token metadata */
export const TOKEN_METADATA = {
  NAME: "mock",
  SYMBOL: "mock",
  URI: "mock://uri/",
};

/** constant of token amount */
export const amount = 1000n;

/** constant of partial token amount */
export const partialAmount = 500n;

/** constant of frozen token amount */
export const frozenAmount = 100n;

/** constant of transfer function */
export const transfer = {
  utxo: "transfer(address,bytes32,uint256,bytes)",
  forest: "transfer(address,bytes32,uint256)",
};

/** constant of transferFrom function */
export const transferFrom = {
  utxo: "transferFrom(address,address,bytes32,uint256,bytes)",
  forest: "transferFrom(address,address,bytes32,uint256)",
};

/** constant of SRC-165 interface identifier */
export const SRC165InterfaceId = "0x01ffc9a7";

/** constant of SRC-1155 interface identifier */
export const SRC1155InterfaceId = "0xd9b67a26";

/** constant of SRC-5615 interface identifier */
export const SRC5615InterfaceId = "0xf2d03e40";

/** constant of SRC-8047 interface identifier */
export const SRC8047InterfaceId = "0xa4afd005";
