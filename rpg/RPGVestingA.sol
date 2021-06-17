pragma solidity ^0.5.0;

import "../base/SafeERC20.sol";
import "../base/SafeMath.sol";

contract RPGVestingA {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    address _vestingaddr;
    IERC20 private _token;
    uint256 private _total;
    uint256 private _start = 0;
    bool    private _canclaim = false;
    address[] private _beneficiarys;
    uint256 constant _duration = 86400;
    uint256 constant _releasealldays = 400;
    mapping(address => uint256) private _beneficiary_total;
    mapping(address => uint256) private _released;
    
    //event 
    event event_claimed(address user,uint256 amount);
    event event_change_address(address oldaddr,address newaddr);
    
    constructor(address addr) public {
        require(addr != address(0));

        _vestingaddr = addr;
    }
    
    function init(IERC20 token, uint256 total,address[] memory beneficiarys,uint256[] memory amounts) public returns(bool) {
        require(_vestingaddr == msg.sender);
        require(_beneficiarys.length == 0);     //run once
        
        require(address(token) != address(0));
        require(total > 0);
        require(beneficiarys.length == amounts.length);
        
        _token = token;
        _total = total;
        
        uint256 all = 0;
        for(uint256 i = 0 ; i < amounts.length; i++)
        {
            all = all.add(amounts[i]);
        }
        require(all == _total);
        
        _beneficiarys = beneficiarys;
        for(uint256 i = 0 ; i < _beneficiarys.length; i++)
        {
            _beneficiary_total[_beneficiarys[i]] = amounts[i];
            _released[_beneficiarys[i]] = 0;
        }
        return true;
    }
    
    function setStart(uint256 newStart) public {
        require(_vestingaddr == msg.sender);
        require(newStart > 0 && _start == 0);
        
        _start = newStart;
    }

    /**
    * @return the start time of the token vesting.
    */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address[] memory) {
        return _beneficiarys;
    }

    /**
     * @return total of the tokens.
     */
    function total() public view returns (uint256) {
        return _total;
    }
    
    /**
     * @return canclaim.
     */
    function canclaim() public view returns (bool) {
        return _canclaim;
    }
    
    function setcanclaim() public {
        require(_vestingaddr == msg.sender);
        require(_canclaim == false);
        
        _canclaim = true;
    }

    /**
     * @return total number can release to now.
     */
    function calcvesting(address user) public view returns(uint256) {
        require(_start > 0);
        require(block.timestamp >= _start);
        require(_beneficiary_total[user] > 0);
        
        uint256 daynum = block.timestamp.sub(_start).div(_duration);
        
        if(daynum <= _releasealldays)
        {
            return _beneficiary_total[user].mul(daynum).div(_releasealldays);
        }
        else
        {
            return _beneficiary_total[user];
        }
    }
    
    /**
     * claim all the tokens to now
     * @return claim number this time .
     */
    function claim() public returns(uint256) {
        require(_start > 0);
        require(_beneficiary_total[msg.sender] > 0);
        require(_canclaim == true);
        
        uint256 amount = calcvesting(msg.sender).sub(_released[msg.sender]);
        if(amount > 0)
        {
            _released[msg.sender] = _released[msg.sender].add(amount);
            _token.safeTransfer(msg.sender,amount);
            emit event_claimed(msg.sender,amount);
        }
        return amount;
    }
    
    /**
     * @return all number has claimed
     */
    function claimed(address user) public view returns(uint256) {
        require(_start > 0);
        
        return _released[user];
    }
    
    function changeaddress(address oldaddr,address newaddr) public {
        require(_beneficiarys.length > 0);
        require(_beneficiary_total[newaddr] == 0);
        
        if(msg.sender == _vestingaddr)
        {
            for(uint256 i = 0 ; i < _beneficiarys.length; i++)
            {
                if(_beneficiarys[i] == oldaddr)
                {
                    _beneficiarys[i] = newaddr;
                    _beneficiary_total[newaddr] = _beneficiary_total[oldaddr];
                    _beneficiary_total[oldaddr] = 0;
                    _released[newaddr] = _released[oldaddr];
                    _released[oldaddr] = 0;
                    
                    emit event_change_address(oldaddr,newaddr);
                    return;
                }
            }
        }
        else
        {
            require(msg.sender == oldaddr);
            
            for(uint256 i = 0 ; i < _beneficiarys.length; i++)
            {
                if(_beneficiarys[i] == msg.sender)
                {
                    _beneficiarys[i] = newaddr;
                    _beneficiary_total[newaddr] = _beneficiary_total[msg.sender];
                    _beneficiary_total[msg.sender] = 0;
                    _released[newaddr] = _released[msg.sender];
                    _released[msg.sender] = 0;
                    
                    emit event_change_address(msg.sender,newaddr);
                    return;
                }
            }
        }
    } 
}
