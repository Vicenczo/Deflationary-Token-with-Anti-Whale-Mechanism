// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DeflationaryToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_TOTAL_SUPPLY = 1000000000 * 10**18; // 1 billion tokens
    uint256 public constant BURN_FEE = 200; // 2% (200 basis points)
    uint256 public constant MAX_TRANSACTION_AMOUNT = 5000000 * 10**18; // 0.5% of total supply (5 million tokens)
    uint256 public constant FEE_DENOMINATOR = 10000; // 100.00%

    mapping(address => bool) private _excludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor() ERC20("DeflationaryToken", "DFT") {
        _mint(msg.sender, MAX_TOTAL_SUPPLY);
        _excludedFromFees[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= MAX_TRANSACTION_AMOUNT, "Transfer amount exceeds the max transaction amount");
        
        if (_excludedFromFees[_msgSender()] || _excludedFromFees[recipient]) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            uint256 burnAmount = amount.mul(BURN_FEE).div(FEE_DENOMINATOR);
            uint256 transferAmount = amount.sub(burnAmount);
            
            _burn(_msgSender(), burnAmount);
            _transfer(_msgSender(), recipient, transferAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= MAX_TRANSACTION_AMOUNT, "Transfer amount exceeds the max transaction amount");
        
        if (_excludedFromFees[sender] || _excludedFromFees[recipient]) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 burnAmount = amount.mul(BURN_FEE).div(FEE_DENOMINATOR);
            uint256 transferAmount = amount.sub(burnAmount);
            
            _burn(sender, burnAmount);
            _transfer(sender, recipient, transferAmount);
        }
        
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_excludedFromFees[account] != excluded, "Account is already set to that state");
        _excludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _excludedFromFees[account];
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
}