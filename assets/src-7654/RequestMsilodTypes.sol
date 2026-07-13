// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;
import "./Types.sol";
import "./IRequestMsilodTypes.sol";
contract RequestMsilodTypes is IRequestMsilodTypes{
    //@dev Types contains all data types in solidity
    mapping(string => Types.Type[]) msilodRequests;
    mapping(string => Types.Type[]) msilodResponses;
    mapping(MsilodTypes => string[]) msilods;
    mapping(string => string) instructions;

    //@dev define the data type of this component
    struct Profiles {
        string name;
        uint256 age;
    }
    mapping(address => Profiles) users;

    constructor() {
        Types.Type[] memory getReqArray = new Types.Type[](1);
        getReqArray[0] = Types.Type.ADDRESS;
        Types.Type[] memory dataTypeArray = new Types.Type[](2);
        dataTypeArray[0] = Types.Type.STRING;
        dataTypeArray[1] = Types.Type.UINT256;
        Types.Type[] memory putReqArray = new Types.Type[](2);
        putReqArray[0] = Types.Type.ADDRESS;
        putReqArray[1] = Types.Type.STRING;
        // @dev initialize get, post, put request parameter data types and response data types
        setMsilod(
            "getUser",
            MsilodTypes.GET,
            getReqArray,
            dataTypeArray,
            "get user profiles"
        );
        setMsilod(
            "createUser",
            MsilodTypes.POST,
            dataTypeArray,
            dataTypeArray,
            "Create user profiles"
        );
        setMsilod(
            "updateUserName",
            MsilodTypes.PUT,
            putReqArray,
            new Types.Type[](0),
            "Update user information"
        );
    }

    function get(string memory _msilodName, bytes memory _msilodReq)
        public
        view
        returns (bytes memory)
    {
        if (compareStrings(_msilodName, "getUser")) {
            address user = abi.decode(_msilodReq, (address));
            bytes memory userData = abi.encode(
                users[user].name,
                users[user].age
            );
            return userData;
        } else {
            return abi.encode("");
        }
    }

    function post(string memory _msilodName, bytes memory _msilodReq)
        public
        payable
        returns (bytes memory)
    {
        if (compareStrings(_msilodName, "createUser")) {
            (string memory name, uint256 age) = abi.decode(
                _msilodReq,
                (string, uint256)
            );
            users[msg.sender] = Profiles(name, age);
            bytes memory resBytes = abi.encode(name, age);
            emit Response(resBytes);
            return resBytes;
        }
        return abi.encode("");
    }

    function put(string memory _msilodName, bytes memory _msilodReq)
        public
        payable
        returns (bytes memory)
    {
        if (compareStrings(_msilodName, "updateUserName")) {
            (address userAddress, string memory name) = abi.decode(
                _msilodReq,
                (address, string)
            );
            require(userAddress == msg.sender);
            users[userAddress].name = name;
        }
        return abi.encode("");
    }

    function options() public pure returns (MsilodTypes[] memory) {
        MsilodTypes[] memory msilodTypes = new MsilodTypes[](4);
        msilodTypes[0] = MsilodTypes.GET;
        msilodTypes[1] = MsilodTypes.POST;
        msilodTypes[2] = MsilodTypes.PUT;
        msilodTypes[3] = MsilodTypes.OPTIONS;
        return msilodTypes;
    }

    function setMsilod(
        string memory _msilodName,
        MsilodTypes _msilodType,
        Types.Type[] memory _msilodReq,
        Types.Type[] memory _msilodRes,
        string memory _instruction
    ) private {
        msilods[_msilodType].push(_msilodName);
        msilodRequests[_msilodName] = _msilodReq;
        msilodResponses[_msilodName] = _msilodRes;
        instructions[_msilodName] = _instruction;
    }

    function getMsilodReqAndRes(string memory _msilodName)
        public
        view
        returns (Types.Type[] memory, Types.Type[] memory)
    {
        return (msilodRequests[_msilodName], msilodResponses[_msilodName]);
    }

    function getMsilods(MsilodTypes _msilodTypes)
        public
        view
        returns (string[] memory)
    {
        return msilods[_msilodTypes];
    }

    function getMsilodInstruction(string memory _msilodName)
        public
        view
        returns (string memory)
    {
        return instructions[_msilodName];
    }

    //@dev compares two strings for equality
    function compareStrings(string memory _a, string memory _b)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

}