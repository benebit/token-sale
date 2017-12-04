
var BenebitICO = artifacts.require('../contracts/BenebitICO.sol');

module.exports = function(deployer) {
return deployer.deploy(BenebitICO).then( async () => {
    const instance = await BenebitICO.deployed(); 
    const token = await instance.getTokenAddress.call();
    console.log('Token Address', token);
});};


