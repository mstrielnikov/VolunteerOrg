// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "hardhat/console.sol";

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Volunteer {
    address private owner;

    uint256 minLimit = 0;
    uint256 maxLimit = type(uint256).max;

    mapping (address => uint256) journal;

    struct fund{
        address donator;
        uint256[] donats;
    }

    fund[] fundings;
    uint256 private counter;

    uint256 private balance;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    event FundingRecieve(address indexed funderAddress, uint256 fundingAmount);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev donate
     */
    function donate() external payable {
        require(msg.value > minLimit && msg.value < maxLimit, "Unable to donate funds. Funding amount should fit into range betweeb minAllowed and maxAllowed fund value");
        require(counter < maxLimit, "Unable to recieve funds. Max number of donators reached");

        if (!contains(msg.sender)) {
            counter++;
            journal[msg.sender] = counter;
            fundings[counter].donator = msg.sender;
        }

        uint256 offset = getOffset(msg.sender);
        fundings[offset].donats.push(msg.value);

        balance += msg.value;

        emit FundingRecieve(msg.sender, msg.value);
    }

    function contains(address donator) public view returns(bool) {
        return journal[donator] != 0;
    }

    function getOffset(address donator) public view returns(uint256) {
        return journal[donator];
    }

    /**
     * @dev getBalance
     */
    function getBalance() public view returns (uint256) {
        return balance;
    }

    /**
     * @dev getDonators
     */
    function getDonators() public view returns (address[] memory) {
        address[] memory donatorsList = new address[](counter);
        for(uint256 i = 0; i < counter; i++ ){
            donatorsList[i] = fundings[i].donator;
        }
        return donatorsList;
    }

    /**
     * @dev getFundings
     */
    function getFundings() public view returns (address[] memory, uint256 [] memory) {
        return fundings;
    }

    function getDonationsPerAddr(address donator) public view returns (uint256[] memory) {
        uint256 offset = getOffset(donator);
        return fundings[offset].donats;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    // function changeOwner(address newOwner) public isOwner {
    //     emit OwnerSet(owner, newOwner);
    //     owner = newOwner;
    // }


    // fallback() external payable{}

    // receive() external payable {}
}


    // function changeOwner(address newOwner) public isOwner {
    //     emit OwnerSet(owner, newOwner);
    //     owner = newOwner;
    // }


    // fallback() external payable{}

    // receive() external payable {}
}
