pragma solidity ^0.5.0;

import "../base/ERC20.sol";
import "../base/Address.sol";
import "../base/Ownable.sol";
import "../base/ERC20Burnable.sol";


contract RPGBurn is Ownable {
    using Address for address;
    using SafeMath for uint256;

    ERC20Burnable private _token;

    constructor(ERC20Burnable token) public {
        _token = token;
    }

    function burn(uint256 value) onlyOwner public {
        _token.burn(value);
    }
}
