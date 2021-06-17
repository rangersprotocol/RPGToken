pragma solidity ^0.5.0;

import "../base/SafeERC20.sol";
import "../base/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme
 */
contract RPGVestingE {
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

    // beneficiary of tokens after they are released
    address[3] private _beneficiarys;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    //uint256 private _phase;
    uint256 private _start = 0;
    //uint256 private _duration;

    //bool private _revocable;

    constructor (address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;
    }
    
    function init(IERC20 token,address[3] memory beneficiarys, uint256 total) public returns(bool){
        require(_vestingaddr == msg.sender);
        
        require(address(token) != address(0));
        require(beneficiarys[0] != address(0));
        require(beneficiarys[1] != address(0));
        require(beneficiarys[2] != address(0));
        require(total > 0);
        
        _token = token;
        _beneficiarys = beneficiarys;
        _total = total;
        return true;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address[3] memory) {
        return _beneficiarys;
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
     * @notice Transfers tokens to beneficiary.
     */
    function claim() public returns(uint256){
        require(_start > 0);

        _token.safeTransfer(_beneficiarys[0], _total.mul(8).div(20));
        emit event_claimed(_beneficiarys[0],_total.mul(8).div(20));
        
        _token.safeTransfer(_beneficiarys[1], _total.mul(7).div(20));
        emit event_claimed(_beneficiarys[1],_total.mul(7).div(20));
        
        _token.safeTransfer(_beneficiarys[2], _total.mul(5).div(20));
        emit event_claimed(_beneficiarys[2],_total.mul(5).div(20));
        return _total;
    }
    
    /**
     * @return all number has claimed
     */
    function claimed() public view returns(uint256) {
        require(_start > 0);
        
        uint256 amount0 = _token.balanceOf(_beneficiarys[0]);
        uint256 amount1 = _token.balanceOf(_beneficiarys[1]);
        uint256 amount2 = _token.balanceOf(_beneficiarys[2]);
        return amount0.add(amount1).add(amount2);
    }

}
