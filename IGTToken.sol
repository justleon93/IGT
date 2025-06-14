// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";

contract IGTToken is ERC20, Ownable, Pausable {
    uint256 public taxRate = 150; // 1.5%
    uint256 public liquidityRate = 50; // 0.5%
    address public taxWallet;
    address public liquidityWallet;

    mapping(address => bool) public isExcludedFromTax;

    constructor() ERC20("Illyrian Gold Token", "IGT") {
        uint256 totalSupply = 100_000_000 * 10 ** decimals();
        _mint(msg.sender, 10_000_000 * 10 ** decimals()); // 10% për ty
        _mint(address(this), totalSupply - (10_000_000 * 10 ** decimals())); // pjesa tjetër

        taxWallet = msg.sender;
        liquidityWallet = msg.sender;

        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[address(this)] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTaxRate(uint256 _tax, uint256 _liquidity) public onlyOwner {
        require(_tax + _liquidity <= 2000, "Max total tax is 20%");
        taxRate = _tax;
        liquidityRate = _liquidity;
    }

    function setTaxWallet(address _taxWallet, address _liquidityWallet) public onlyOwner {
        taxWallet = _taxWallet;
        liquidityWallet = _liquidityWallet;
    }

    function excludeFromTax(address account, bool excluded) public onlyOwner {
        isExcludedFromTax[account] = excluded;
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (isExcludedFromTax[from] || isExcludedFromTax[to]) {
            super._transfer(from, to, amount);
        } else {
            uint256 taxAmount = (amount * taxRate) / 10000;
            uint256 liquidityAmount = (amount * liquidityRate) / 10000;
            uint256 sendAmount = amount - taxAmount - liquidityAmount;

            super._transfer(from, taxWallet, taxAmount);
            super._transfer(from, liquidityWallet, liquidityAmount);
            super._transfer(from, to, sendAmount);
        }
    }
}
