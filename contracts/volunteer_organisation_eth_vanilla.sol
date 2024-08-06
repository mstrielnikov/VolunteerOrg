// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "hardhat/console.sol";

/**
 * @title Volunteer
 */
contract Volunteer {
    address private charityDestination;

    uint private deadline;
    uint256 minLimit = 0;
    uint256 maxLimit = type(uint256).max;

    mapping (address => uint256) funding;

    address[] private owners;    
    address[] private donators;
    address[] private charityRepresentatives;

    bool flagDonationEnabled = true;

    uint256 private balance;
    uint256 private feePercentage = 1;
    uint256 private feeCollected;

    bool recieveDonation = true;

    // event for EVM logging
    event OwnerSet(address indexed newOwner);
    event FundingRecieve(address indexed funderAddress, uint256 fundingAmount);
    event FundingWithdraw(address indexed funderAddress, uint256 fundingAmount);
    event MinLimitSet(uint256 limit);
    event DonationEnabled(bool flag);

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owners.push(msg.sender); // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(msg.sender);
    }

    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        bool isOwner = contains(msg.sender, owners);
        require(isOwner, "Caller is not owner");
        _;
    }

    function addOwner(address _address) public onlyOwner {
        require(!contains(_address, owners), "This adress is owner already");
        charityRepresentatives.push(_address);
        emit OwnerSet(_address);
    }

    /**
     * @dev Return owners addresses
     * @return address of owner
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @dev setDeadline
     */
   function setDeadline(uint _deadline) external onlyOwner {
        require(_deadline != 0, "Unable to set deadline to zero time");
        deadline = _deadline;
    }

    /**
     * @dev donate
     */
    function donate() external payable {
        require(msg.value > minLimit && msg.value < maxLimit, "Unable to donate funds. Funding amount should fit into range betweeb minLimit and maxLimit value");
        require(block.timestamp >= deadline, "Unable to donate funds after deadline passed");

        if (funding[msg.sender] == 0) {
            donators.push(msg.sender);
        }

        uint256 fee = (msg.value * feePercentage) / 100;
        uint256 amountToSend = msg.value - fee;

        feeCollected += fee;

        funding[msg.sender] += amountToSend;
        balance += msg.value;
    
        emit FundingRecieve(msg.sender, msg.value);
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
        return donators;
    }

    /**
     * @dev getDonationsPerAddr
     * @return amount of funds per address
     */
    function getDonationsPerAddr(address _address) public view returns (uint256) {
        return funding[_address];
    }

    function donationEnable() public onlyOwner {
        require(flagDonationEnabled != true, "Donation is already enabled");
        flagDonationEnabled = true;
        emit DonationEnabled(flagDonationEnabled);
    }

    function donationDisable() public onlyOwner {
        require(flagDonationEnabled != false, "Donation is already disabled");
        flagDonationEnabled = false;
        emit DonationEnabled(flagDonationEnabled);
    }

    /**
     * @dev set min amount of single donation
     */
    function setDonatMin(uint256 _limit) public onlyOwner {
        minLimit = _limit;
        emit MinLimitSet(minLimit);
    }

    /**
     * @dev set charity representative
     */
    function addCharityRepresentative(address _address) external onlyOwner {
        if (!contains(_address, charityRepresentatives)) {
            charityRepresentatives.push(_address);
        }
    }

    function contains(address _address, address[] memory _adresses) private pure returns (bool) {
        uint256 len = _adresses.length;
        for (uint256 i = 0; i < len; i++) {
            if (_adresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    modifier onlyCharityRepresentative() {
        bool isCharityRepresentative = contains(msg.sender, charityRepresentatives);
        require(isCharityRepresentative, "Only owner charity representative to perform this action");
        _;
    }

    /**
     * @dev set charity destination
     */
    function setCharityDestination(address _charityDestination) external onlyOwner {
        charityDestination = _charityDestination;
    }

    /**
     * @dev withdraw funds
     */
    function withdrawFunds() external payable  onlyCharityRepresentative {
        require(charityDestination != address(0), "Charity address is not set. Unable to send funds");
        require(block.timestamp >= deadline, "Unable to withdraw funds before the deadline");
        require(deadline != 0, "Unable to withdraw funds is deadline is not set");
        
        (bool success, ) = charityDestination.call{value: balance}("");
        require(success, "Transfer failed");
        emit FundingWithdraw(charityDestination, balance);
    }

    function chargeback() external payable {
        require(block.timestamp >= deadline, "Unable to chargeback funds before the deadline");
        require(contains(msg.sender, donators), "Donator wasn't donated");
        
        uint256 chargebackAmount = funding[msg.sender];
        (bool success, ) = msg.sender.call{value: chargebackAmount}("");
        require(success, "Transfer failed");

        balance -= chargebackAmount;

        emit FundingWithdraw(msg.sender, chargebackAmount);
        delete funding[msg.sender];
    }


    function chargebackAll() external payable onlyOwner {
        require(block.timestamp >= deadline, "Unable to chargeback funds before the deadline");
        uint256 len = donators.length;
        uint256 getAmount = 0;
        for(uint256 i = 0; i < len; i++){
            getAmount = funding[donators[i]];
            if (getAmount != 0) {
                (bool success, ) = donators[i].call{value: getAmount}("");
                if (success) {
                    emit FundingWithdraw(donators[i], getAmount);
                    delete funding[donators[i]];
                }
            }
        }
        balance = 0;
    }


    function withdrawFeeToOwners() external payable onlyOwner {
        require(block.timestamp >= deadline, "Unable to withdraw fee before the deadline");
        uint256 len = owners.length;
        uint256 feeShare = feeCollected / len;
        for(uint256 i = 0; i < len; i++){
            (bool success, ) = owners[i].call{value: feeShare}("");
            if (success) {
                feeCollected -= feeShare;
                emit FundingWithdraw(donators[i], feeShare);
            }
        }
    }

    fallback() external payable{}
    
    receive() external payable {}
} 
