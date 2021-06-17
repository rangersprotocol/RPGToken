pragma solidity ^0.5.0;

import "../base/ERC20.sol";
import "../base/ERC20Detailed.sol";
import "../base/ERC20Burnable.sol";
import "../base/ERC20Capped.sol";
import "../base/Address.sol";
import "../base/Ownable.sol";
import "./RPGBurn.sol";


contract RPG is
    ERC20,
    ERC20Detailed,
    ERC20Burnable,
    ERC20Capped,
    Ownable
{
    using Address for address;
    uint256 public constant INITIAL_SUPPLY = 21000000 * (10**18);
    mapping(address => uint8) public limit;
    RPGBurn public burnContract;

    constructor(string memory name, string memory symbol)
        public
        Ownable()
        ERC20Capped(INITIAL_SUPPLY)
        ERC20Burnable()
        ERC20Detailed(name, symbol, 18)
        ERC20()
    {
        // mint all tokens
        _mint(msg.sender, INITIAL_SUPPLY);

        // create burner contract
        burnContract = new RPGBurn(this);
        addBurner(address(burnContract));
    }

    /**
     * Set target address transfer limit
     * @param addr target address
     * @param mode limit mode (0: no limit, 1: can not transfer token, 2: can not receive token)
     */
    function setTransferLimit(address addr, uint8 mode) public onlyOwner {
        require(mode == 0 || mode == 1 || mode == 2);

        if (mode == 0) {
            delete limit[addr];
        } else {
            limit[addr] = mode;
        }
    }

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(limit[msg.sender] != 1, 'from address is limited.');
        require(limit[to] != 2, 'to address is limited.');
        
        _transfer(msg.sender, to, value);

        return true;
    }

    function burnFromContract(uint256 value) onlyBurner public {
        burnContract.burn(value);
    }
}
