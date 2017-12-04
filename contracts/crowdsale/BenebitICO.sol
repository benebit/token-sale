pragma solidity ^0.4.13;

/**
 * @title BenebitICO
 * @author Hamza Yasin || Junaid Mushtaq
 * @dev BenibitCrowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them BNE tokens based
 * on a BNE token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */

import '../node_modules/zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../node_modules/zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';
import '../node_modules/zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol';
import '../contracts/BenebitToken.sol';


contract BenebitICO is Crowdsale, CappedCrowdsale, RefundableCrowdsale {
    uint256 _startTime = 1514206800;
    uint256 _endTime = 1519822800; 
    uint256 _rate = 3000;
    uint256 _goal = 5000 * 1 ether;
    uint256 _cap = 75000 * 1 ether;
    address _wallet  = 0x0000000000000000000000000000000000000000;   
    /** Constructor BenebitICO */
    function BenebitICO() 
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime,_endTime,_rate,_wallet) 
    {
        
    }
    /** BenebitToken Contract is generating from here */
    function createTokenContract() internal returns (MintableToken) {
        return new BenebitToken();
    }


}