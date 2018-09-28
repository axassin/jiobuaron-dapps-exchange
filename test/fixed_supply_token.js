const FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");

contract("MyToken", accounts => {
    it("first account should own all tokens", async () => {
       const myTokenInstance = await FixedSupplyToken.deployed()
       const totalSupply = await myTokenInstance.totalSupply.call()
       const balanceAccount = await myTokenInstance.balanceOf(accounts[0])
       assert.equal(balanceAccount.toNumber(), totalSupply.toNumber())
    }) 
});