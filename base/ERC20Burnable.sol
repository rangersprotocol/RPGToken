pragma solidity ^0.5.0;
import "./ERC20.sol";
import "./BurnRole.sol";

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20, BurnRole{
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public onlyBurner returns (bool){
        _burn(msg.sender, value);
        return true;
    }
}
