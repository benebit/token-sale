pragma solidity ^0.4.11;
/**
 * @title BenebitToken
 * @author Hamza Yasin || Junaid Mushtaq
 */
import '../node_modules/zeppelin-solidity/contracts/token/MintableToken.sol';


contract BenebitToken is MintableToken {

  string public constant name = "BenebitToken";
  string public constant symbol = "BNE";
  uint256 public constant decimals = 18;
  uint256 public constant _totalSupply = 300000000 * 1 ether;
  
/** Constructor BenebitToken */
  function BenebitToken() {
    totalSupply = _totalSupply;
  }

}


