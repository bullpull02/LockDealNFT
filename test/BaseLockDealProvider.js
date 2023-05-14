const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")

describe("Base Lock Deal Provider", function (accounts) {
    let baseLockProvider, lockDealNFT, itemId
    let owner, notOwner, receiver
    let token, startTime, poolData
    const amount = 10000

    before(async () => {
        ;[owner, notOwner, receiver] = await ethers.getSigners()
        const LockDealNFT = await ethers.getContractFactory("LockDealNFT")
        const BaseLockProvider = await ethers.getContractFactory("BaseLockDealProvider")
        const ERC20Token = await ethers.getContractFactory("ERC20Token")
        lockDealNFT = await LockDealNFT.deploy()
        await lockDealNFT.deployed()
        baseLockProvider = await BaseLockProvider.deploy(lockDealNFT.address)
        token = await ERC20Token.deploy("TEST Token", "TERC20")
        await baseLockProvider.deployed()
        await token.deployed()
        await token.approve(baseLockProvider.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(baseLockProvider.address, true)
    })

    beforeEach(async () => {
        let date = new Date()
        date.setDate(date.getDate() + 1)
        startTime = Math.floor(date.getTime() / 1000)
        await baseLockProvider.createNewPool(token.address, amount, startTime, receiver.address)
        itemId = await lockDealNFT.totalSupply()
    })

    it("should check pool data", async () => {
        poolData = await baseLockProvider.itemIdToDeal(itemId.toString())
        expect(poolData[0].toString()).to.equal(token.address)
        expect(poolData[1].toString()).to.equal(amount.toString())
        expect(poolData[2].toString()).to.equal(startTime.toString())
    })

    it("should check pool creation events", async () => {
        const tx = await baseLockProvider.createNewPool(token.address, amount, startTime, receiver.address)
        await tx.wait()
        const events = await baseLockProvider.queryFilter("NewPoolCreated((uint256,address,address),uint256[])");
        expect(events[1].args.PoolInfo.Token).to.equal(token.address);
        expect(events[1].args.params[0]).to.equal(amount); //assuming amount is at index 0 in the params array
        expect(events[1].args.params[1]).to.equal(startTime); //assuming startTime is at index 1 in the params array
    })

    it("should check contract token balance", async () => {
        const oldBal = await token.balanceOf(baseLockProvider.address)
        await baseLockProvider.createNewPool(token.address, amount, startTime, receiver.address)
        expect(await token.balanceOf(baseLockProvider.address)).to.equal(parseInt(oldBal) + amount)
    })

    it("should revert zero owner address", async () => {
        await expect(
            baseLockProvider.createNewPool(constants.AddressZero, amount, startTime, receiver.address)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert zero token address", async () => {
        await expect(
            baseLockProvider.createNewPool(token.address, amount, startTime, constants.AddressZero)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert zero amount", async () => {
        await expect(
            baseLockProvider.createNewPool(token.address, "0", startTime, receiver.address)
        ).to.be.revertedWith("amount should be greater than 0")
    })

    it("should withdraw tokens from pool", async () => {
        await ethers.provider.send("evm_increaseTime", [startTime])
        await ethers.provider.send("evm_mine")
        await baseLockProvider.withdraw(itemId)
        poolData = await baseLockProvider.itemIdToDeal(itemId.toString())
        expect(poolData[1]).to.equal(0)
    })

    it("should revert twice withdrawing", async () => {
        await ethers.provider.send("evm_increaseTime", [startTime])
        await ethers.provider.send("evm_mine")
        await baseLockProvider.withdraw(itemId)
        await expect(baseLockProvider.withdraw(itemId)).to.be.revertedWith("amount should be greater than 0")
    })

    it("revert invalid owner", async () => {
        const notOwnerSigner = ethers.provider.getSigner(notOwner.address)
        const baseLockProviderWithNotOwner = baseLockProvider.connect(notOwnerSigner)
        await expect(baseLockProviderWithNotOwner.withdraw(itemId)).to.be.revertedWith("Not the owner of the pool")
    })

    it("should split half pool", async () => {
        await baseLockProvider.split(itemId, amount / 2, owner.address)
        poolData = await baseLockProvider.itemIdToDeal(itemId.toString())
        expect(poolData[0].toString()).to.equal(token.address)
        expect(poolData[1].toString()).to.equal((amount / 2).toString())
        expect(poolData[2].toString()).to.equal(startTime.toString())
    })
})
