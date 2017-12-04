pragma solidity ^0.4.11;

import '../token/MintableToken.sol';
import '../math/SafeMath.sol';
import '../contracts/Ownable.sol';
/**
 * @title Benebit Crowdsale
 * @author Hamza Yasin || Junaid Mushtaq
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  MintableToken private token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public preStartTime;
  uint256 public preEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  
  // Bonuses will be calculated here of ICO and Pre-ICO (both inclusive)
  uint256 private preICOBonus;
  uint256 private firstWeekBonus;
  uint256 private secondWeekBonus;
  uint256 private thirdWeekBonus;
  uint256 private forthWeekBonus;
  
  // wallet address where funds will be saved
  address internal wallet;
  
  // base-rate of a particular Benebit token
  uint256 public rate;

  // amount of raised money in wei
  uint256 internal weiRaised;

  // bonus distribution on behalf of weeks
  uint256 weekOne;
  uint256 weekTwo;
  uint256 weekThree;
  uint256 weekForth;
  
  // total supply of token 
  uint256 private totalSupply = 300000000 * (10**18);
  // public supply of token 
  uint256 private publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),75);
  // rewards supply of token 
  uint256 private rewardsSupply = SafeMath.mul(SafeMath.div(totalSupply,100),15);
  // team supply of token 
  uint256 private teamSupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
  // advisor supply of token 
  uint256 private advisorSupply = SafeMath.mul(SafeMath.div(totalSupply,100),3);
  // bounty supply of token 
  uint256 private bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),2);
  // preICO supply of token 
  uint256 private preicoSupply = SafeMath.mul(SafeMath.div(publicSupply,100),15);
  // ICO supply of token 
  uint256 private icoSupply = SafeMath.mul(SafeMath.div(publicSupply,100),85);
  // Remaining Public Supply of token 
  uint256 private remainingPublicSupply = publicSupply;
  // Remaining Reward Supply of token 
  uint256 private remainingRewardsSupply = rewardsSupply;
  // Remaining Bounty Supply of token 
  uint256 private remainingBountySupply = bountySupply;
  // Remaining Advisor Supply of token 
  uint256 private remainingAdvisorSupply = advisorSupply;
  // Remaining Team Supply of token 
  uint256 private remainingTeamSupply = teamSupply;
  // Time lock or vested period of token for team allocated token
  uint256 private teamTimeLock;
  // Time lock or vested period of token for Advisor allocated token
  uint256 private advisorTimeLock;
  /**
   *  @bool checkBurnTokens
   *  @bool upgradeICOSupply
   *  @bool grantTeamSupply
   *  @bool grantAdvisorSupply     
  */
  bool private checkBurnTokens;
  bool private upgradeICOSupply;
  bool private grantTeamSupply;
  bool private grantAdvisorSupply;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  // Benebit Crowdsale constructor
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    // Benebit token creation 
    token = createTokenContract();
    // Pre-ICO start Time
    preStartTime = _startTime;
    // Pre-ICO end time
    preEndTime = 1516280400;
    // ICO start Time
    ICOstartTime = 1516626000;
    // ICO end Time
    ICOEndTime = _endTime;
    // Base Rate of BNE Token
    rate = _rate;
    // Multi-sig wallet where funds will be saved
    wallet = _wallet;

    /** Calculations of Bonuses in ICO or Pre-ICO */
    preICOBonus = SafeMath.div(SafeMath.mul(rate,30),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    forthWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);

    /** ICO bonuses week calculations */
    weekOne = SafeMath.add(ICOstartTime, 604800);
    weekTwo = SafeMath.add(weekOne, 604800);
    weekThree = SafeMath.add(weekTwo, 604800);
    weekForth = SafeMath.add(weekThree, 604800);

    /** Vested Period calculations for team and advisors*/
    teamTimeLock = SafeMath.add(ICOEndTime, 31536000);
    advisorTimeLock = SafeMath.add(ICOEndTime, 5356800);
    
    checkBurnTokens = false;
    upgradeICOSupply = false;
    grantAdvisorSupply = false;
    grantTeamSupply = false;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // High level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    // minimum investment should be 0.05 ETH
    require(weiAmount >= (0.05 * 1 ether));
    
    uint256 accessTime = now;
    uint256 tokens = 0;

  // calculating the ICO and Pre-ICO bonuses on the basis of timing
    if ((accessTime >= preStartTime) && (accessTime < preEndTime)) {
        require(preicoSupply > 0);

        tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        
        require(preicoSupply >= tokens);
        
        preicoSupply = preicoSupply.sub(tokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);

    } else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime)) {
        if (!upgradeICOSupply) {
          icoSupply = SafeMath.add(icoSupply,preicoSupply);
          upgradeICOSupply = true;
        }
        if ( accessTime <= weekOne ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        } else if (accessTime <= weekTwo) {
          tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
        } else if ( accessTime < weekThree ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
        } else if ( accessTime < weekForth ) {
          tokens = SafeMath.add(tokens, weiAmount.mul(forthWeekBonus));
        }
        
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);        
        remainingPublicSupply = remainingPublicSupply.sub(tokens);
    } else if ((accessTime > preEndTime) && (accessTime < ICOstartTime)){
      revert();
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);
    // tokens are minting here
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    // funds are forwarding
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
      return now > ICOEndTime;
  }

  // @return true if burnToken function has ended
  function burnToken() onlyOwner public returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    token.burnTokens(remainingPublicSupply);
    totalSupply = SafeMath.sub(totalSupply, remainingPublicSupply);
    remainingPublicSupply = 0;
    checkBurnTokens = true;
    return true;
  }

  /** 
     * @return true if bountyFunds function has ended
     * @param beneficiary address where owner wants to transfer tokens
     * @param valueToken value of token
  */
  function bountyFunds(address beneficiary, uint256 valueToken) onlyOwner public payable { 
    valueToken = SafeMath.mul(valueToken, 1 ether);
    require(remainingBountySupply >= valueToken);
    remainingBountySupply = SafeMath.sub(remainingBountySupply,valueToken);
    token.mint(beneficiary, valueToken);
  }

  /** 
     * @return true if rewardsFunds function has ended
     * @param beneficiary address where owner wants to transfer tokens
     * @param valueToken value of token
  */
  function rewardsFunds(address beneficiary, uint256 valueToken) onlyOwner public payable { 
    valueToken = SafeMath.mul(valueToken, 1 ether);
    require(remainingRewardsSupply >= valueToken);
    remainingRewardsSupply = SafeMath.sub(remainingRewardsSupply,valueToken);
    token.mint(beneficiary, valueToken);
  } 

  /**
      @return true if grantAdvisorToken function has ended  
  */
  function grantAdvisorToken() onlyOwner public {
    require(!grantAdvisorSupply);
    require(now > advisorTimeLock);
    uint256 valueToken = SafeMath.div(remainingAdvisorSupply,3);
    require(remainingAdvisorSupply >= valueToken);
    grantAdvisorSupply = true;
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    remainingAdvisorSupply = 0;
  }

  /**
      @return true if grantTeamToken function has ended  
  */
    function grantTeamToken() onlyOwner public {
    require(!grantTeamSupply);
    require(now > teamTimeLock);
    uint256 valueToken = SafeMath.div(remainingTeamSupply, 5);
    require(remainingTeamSupply >= valueToken);
    grantTeamSupply = true;
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    token.mint(0x0000000000000000000000000000000000000000, valueToken);
    remainingTeamSupply = 0;
  }

/** 
   * Function transferToken works to transfer tokens to the specified address on the
     call of owner within the crowdsale timestamp.
   * @param beneficiary address where owner wants to transfer tokens
   * @param tokens value of token
 */
  function transferToken(address beneficiary, uint256 tokens) onlyOwner public {
    require(ICOEndTime > now);
    tokens = SafeMath.mul(tokens,1 ether);
    require(remainingPublicSupply >= tokens);
    remainingPublicSupply = SafeMath.sub(remainingPublicSupply,tokens);
    token.mint(beneficiary, tokens);
  }

  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }

  function getPublicSupply() onlyOwner public returns (uint256) {
    return remainingPublicSupply;
  }
}



