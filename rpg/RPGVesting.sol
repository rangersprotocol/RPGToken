pragma solidity ^0.5.0;

import "../base/ERC20.sol";
import "../base/ERC20Detailed.sol";
import "../base/ERC20Burnable.sol";
import "../base/ERC20Capped.sol";
import "../base/Address.sol";
import "../base/Ownable.sol";
import "./RPG.sol";
import "./RPGVestingA.sol";
import "./RPGVestingB.sol";
import "./RPGVestingC.sol";
import "./RPGVestingD.sol";
import "./RPGVestingE.sol";
import "./RPGBurn.sol";


contract RPGVesting is Ownable {
    using Address for address;
    using SafeMath for uint256;

    RPG private _token;
    RPGVestingA private _investors = RPGVestingA(0);
    RPGVestingB private _incubator_adviser;
    RPGVestingC private _development;
    RPGVestingD private _community;
    RPGVestingE private _fund;

    uint256 public INITIAL_SUPPLY;
    
    event event_debug(uint256 amount);

    constructor() public {
        
    }

    function init(
        RPG token,RPGVestingA investors_addr,RPGVestingB incubator_adviser_addr,RPGVestingC development_addr,RPGVestingD community_addr,RPGVestingE fund_addr,
        address[] memory investors,          //10%-----A
        uint256[] memory investors_number,
        address[] memory incubator_advisers, //7%-----B
        uint256[] memory incubator_advisers_number,
        address developments,               //14%----C
        address community,                  //49%----D  mutisigncontract address
        address[3] memory fund              //20%----E
    ) public onlyOwner {
        require(address(_investors) == address(0));     //run once
        
        //para check
        require(address(token) != address(0));
        require(address(investors_addr) != address(0));
        require(address(incubator_adviser_addr) != address(0));
        require(address(development_addr) != address(0));
        require(address(community_addr) != address(0));
        require(address(fund_addr) != address(0));
        require(investors.length == investors_number.length);
        require(incubator_advisers.length == incubator_advisers_number.length);
        require(developments != address(0));
        require(community != address(0));
        require(fund[0] != address(0));
        require(fund[1] != address(0));
        require(fund[2] != address(0));
        //run check
        
        _token = token;
        _investors = investors_addr;
        _incubator_adviser = incubator_adviser_addr;
        _development = development_addr;
        _community = community_addr;
        _fund = fund_addr;
        INITIAL_SUPPLY = _token.INITIAL_SUPPLY();
        require(_token.balanceOf(address(this)) == INITIAL_SUPPLY);
        
        // create all vesting contracts
        // _investors          = new RPGVestingA(_token,INITIAL_SUPPLY.mul(9).div(100));
        // _incubator_adviser  = new RPGVestingB(_token,INITIAL_SUPPLY.mul(7).div(100));
        // _development        = new RPGVestingB(_token,INITIAL_SUPPLY.mul(14).div(100));
        // _community          = new RPGVestingC(_token,community,INITIAL_SUPPLY.mul(49).div(100));
        // _fund               = new RPGVestingD(_token,fund,INITIAL_SUPPLY.mul(21).div(100));

        //init
        require(_investors.init(_token,INITIAL_SUPPLY.mul(10).div(100),investors,investors_number));
        require(_incubator_adviser.init(_token,INITIAL_SUPPLY.mul(7).div(100),incubator_advisers,incubator_advisers_number));
        require(_development.init(_token,developments,INITIAL_SUPPLY.mul(14).div(100)));
        require(_community.init(_token,community,INITIAL_SUPPLY.mul(49).div(100)));
        require(_fund.init(_token,fund,INITIAL_SUPPLY.mul(20).div(100)));

        //transfer tokens to vesting contracts
        _token.transfer(address(_investors)         , _investors.total());
        _token.transfer(address(_incubator_adviser) , _incubator_adviser.total());
        _token.transfer(address(_development)       , _development.total());
        _token.transfer(address(_community)         , _community.total());
        _token.transfer(address(_fund)              , _fund.total());
        
    }

    function StartIDO(uint256 start) public onlyOwner {
        require(start >= block.timestamp);

        _investors.setStart(start);
        _fund.setStart(start);
    }
    
    function StartMainnet(uint256 start) public onlyOwner {
        require(start >= block.timestamp);
        require(start >= _investors.start());

        _incubator_adviser.setStart(start);
        _development.setStart(start);
        _community.setStart(start);
    }
    
    function StartInvestorsClaim() public onlyOwner {
        require(_investors.start() > 0 && _investors.start() < block.timestamp);
        
        _investors.setcanclaim();
    }
    
    function investors() public view returns (address) {
        return address(_investors);
    }
    
    function incubator_adviser() public view returns (address) {
        return address(_incubator_adviser);
    }
    
    function development() public view returns (address) {
        return address(_development);
    }
    
    function community() public view returns (address) {
        return address(_community);
    }
    
    function fund() public view returns (address) {
        return address(_fund);
    }
    
    ////calc vesting number/////////////////////////////
    function unlocked_investors_vesting(address user) public view returns(uint256) {
        return _investors.calcvesting(user);
    }
    
    function unlocked_incubator_adviser_vesting(address user) public view returns(uint256) {
        return _incubator_adviser.calcvesting(user);
    }
    
    function unlocked_development_vesting() public view returns(uint256) {
        return _development.calcvesting();
    }
    
    function unlocked_community_vesting() public view returns(uint256) {
        return _community.calcvesting();
    }
    
    // function calc_fund_vesting() public view returns(uint256) {
    //     return _fund.calcvesting();
    // }
    
    ///////claimed amounts//////////////////////////////
    function claimed_investors(address user) public view returns(uint256){
        return _investors.claimed(user);
    }
    
    function claimed_incubator_adviser(address user) public view returns(uint256){
        return _incubator_adviser.claimed(user);
    }
    
    function claimed_development() public view returns(uint256){
        return _development.claimed();
    }
    
    function claimed_community() public view returns(uint256){
        return _community.claimed();
    }
    
    //////change address/////////////////////////////////
    function investors_changeaddress(address oldaddr,address newaddr) onlyOwner public{
        require(newaddr != address(0));
        
        _investors.changeaddress(oldaddr,newaddr);
    }
    
    function incubator_adviser_changeaddress(address oldaddr,address newaddr) onlyOwner public{
        require(newaddr != address(0));
        
        _incubator_adviser.changeaddress(oldaddr,newaddr);
    }
    
    function community_changeaddress(address newaddr) onlyOwner public{
        require(newaddr != address(0));
        
        _community.changeaddress(newaddr);
    }
    
}
