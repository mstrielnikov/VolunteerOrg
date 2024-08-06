// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, Ownable, ERC20Permit {
    mapping(address => bool) private blacklist;

    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") Ownable(msg.sender) ERC20Permit("MyToken"){
        mint(msg.sender, initialSupply * 18 ** decimals());
    }

    function mint(address to, uint256 amount) private onlyOwner {
        _mint(to, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _beforeTokenTransfer(_msgSender(), to, amount);
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        return super.transferFrom(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {
        require(!isBlacklisted(from), "MyToken: sender is blacklisted");
        require(!isBlacklisted(to), "MyToken: recipient is blacklisted");
        require(approve(from, amount), "Unable to allow spending");
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        blacklist[account] = value;
        emit BlacklistUpdated(account, value);
    }

    function burnBlacklistedAddress(address account) external onlyOwner {
        require(isBlacklisted(account), "MyToken: account is not blacklisted");
        _burn(account, account.balance);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
}
