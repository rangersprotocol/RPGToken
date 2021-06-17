pragma solidity ^0.5.0;

import "../base/SafeERC20.sol";
import "../base/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme
 */
contract RPGVestingD {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). 
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address _vestingaddr;

    event event_claimed(address user,uint256 amount);

    IERC20 private _token;
    uint256 private _total;
    uint256 constant _duration = 86400;
    uint256 constant _releaseperiod = 180;
    uint256 private _released = 0;

    // beneficiary of tokens after they are released
    address private _beneficiary = address(0);
    uint256 private _start = 0;

    constructor (address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;

    }
    
    function init(IERC20 token,address beneficiary, uint256 total) public returns(bool){
        require(_vestingaddr == msg.sender);
        require(_beneficiary == address(0));    //run once
        
        require(address(token) != address(0));
        require(beneficiary != address(0));
        require(total > 0);
        
        _token = token;
        _beneficiary = beneficiary;
        _total = total;
        return true;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }
    
    /**
     * @return total of the tokens.
     */
    function total() public view returns (uint256) {
        return _total;
    }

    function setStart(uint256 newStart) public {
        require(_vestingaddr == msg.sender);
        require(newStart > 0 && _start == 0);
        
        _start = newStart;
    }

    /**
     * @return number to now.
     */
    function calcvesting() public view returns(uint256) {
        require(_start > 0);
        require(block.timestamp >= _start);
        
        uint256 daynum = block.timestamp.sub(_start).div(_duration);
        
        uint256 counts180 = daynum.div(_releaseperiod);
        uint256 dayleft = daynum.mod(_releaseperiod);
        uint256 amount180 = 0;
        uint256 thistotal = _total.mul(8).div(100);
        for(uint256 i = 0; i< counts180; i++)
        {
            amount180 = amount180.add(thistotal);
            thistotal = thistotal.mul(92).div(100);                //thistotal.mul(100).div(8).mul(92).div(100).mul(8).div(100);     //next is thistotal/(0.08)*0.92*0.08
        }
        
        return amount180.add(thistotal.mul(dayleft).div(_releaseperiod));
    }

    /**
     * @return number of this claim
     */
    function claim() public returns(uint256) {
        require(_start > 0);
        
        uint256 amount = calcvesting().sub(_released);
        if(amount > 0)
        {
            _released = _released.add(amount);
            _token.safeTransfer(_beneficiary,amount);
            emit event_claimed(_beneficiary,amount);
        }
        return amount;
    }
    
    /**
     * @return all number has claimed
     */
    function claimed() public view returns(uint256) {
        require(_start > 0);
        
        return _released;
    }
    
    //it must approve , before call this function
    function changeaddress(address newaddr) public {
        require(_beneficiary != address(0));
        require(msg.sender == _vestingaddr);
        
        _token.safeTransferFrom(_beneficiary,newaddr,_token.balanceOf(_beneficiary));
        _beneficiary = newaddr;
    } 
}
