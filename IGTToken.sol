// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract IllyrianGoldToken is ERC20, Pausable, Ownable, ERC20Burnable {
    address public treasuryWallet;
    address public liquidityWallet;

    uint256 public taxTreasury = 150; // 1.5%
    uint256 public taxLiquidity = 50; // 0.5%
    uint256 public constant TAX_DIVISOR = 10000;

    mapping(address => bool) private _isExcludedFromFee;

    constructor(address _treasuryWallet, address _liquidityWallet) ERC20("ILLYRIAN GOLD TOKEN", "IGT") {
        require(_treasuryWallet != address(0), "Invalid treasury address");
        require(_liquidityWallet != address(0), "Invalid liquidity address");

        treasuryWallet = _treasuryWallet;
        liquidityWallet = _liquidityWallet;

        uint256 totalSupply = 100_000_000 * 10 ** decimals();
        
        // 10% për krijuesin
        _mint(msg.sender, totalSupply * 10 / 100);
        
        // 15% për giveaway
        _mint(msg.sender, totalSupply * 15 / 100);
        
        // 15% për presale
        _mint(msg.sender, totalSupply * 15 / 100);
        
        // 60% për publikun
        _mint(msg.sender, totalSupply * 60 / 100);

        // Exclude owner from tax
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        _isExcludedFromFee[account] = exempt;
    }

    function setTaxRates(uint256 _treasury, uint256 _liquidity) external onlyOwner {
        require(_treasury + _liquidity <= 1000, "Tax too high"); // Max 10%
        taxTreasury = _treasury;
        taxLiquidity = _liquidity;
    }

    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused {
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            super._transfer(from, to, amount);
        } else {
            uint256 treasuryFee = (amount * taxTreasury) / TAX_DIVISOR;
            uint256 liquidityFee = (amount * taxLiquidity) / TAX_DIVISOR;
            uint256 netAmount = amount - treasuryFee - liquidityFee;

            super._transfer(from, treasuryWallet, treasuryFee);
            super._transfer(from, liquidityWallet, liquidityFee);
            super._transfer(from, to, netAmount);
        }
    }
}
