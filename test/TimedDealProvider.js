const { expect } = require("chai")
const { constants } = require("ethers")
const { ethers } = require("hardhat")
const helpers = require("@nomicfoundation/hardhat-network-helpers")
const { deployed } = require("./helper")

describe("Timed Deal Provider", function (accounts) {
    let timedDealProvider, lockProvider, dealProvider, lockDealNFT
    let mockProvider, poolData, halfTime
    let poolId, params
    let receiver
    let token, startTime, finishTime
    const amount = 100000

    before(async () => {
        ;[receiver, newOwner] = await ethers.getSigners()
        const mockVaultManager = await deployed("MockVaultManager")
        lockDealNFT = await deployed("LockDealNFT", mockVaultManager.address)
        token = await deployed("ERC20Token", "TEST Token", "TERC20")
        dealProvider = await deployed("DealProvider", lockDealNFT.address)
        lockProvider = await deployed("LockDealProvider", lockDealNFT.address, dealProvider.address)
        timedDealProvider = await deployed("TimedDealProvider", lockDealNFT.address, lockProvider.address)
        mockProvider = await deployed("MockProvider", timedDealProvider.address)
        await token.approve(timedDealProvider.address, constants.MaxUint256)
        await token.approve(mockVaultManager.address, constants.MaxUint256)
        await lockDealNFT.setApprovedProvider(dealProvider.address, true)
        await lockDealNFT.setApprovedProvider(lockProvider.address, true)
        await lockDealNFT.setApprovedProvider(timedDealProvider.address, true)
        await lockDealNFT.setApprovedProvider(mockProvider.address, true)
    })

    beforeEach(async () => {
        const ONE_DAY = 86400
        startTime = await helpers.time.latest() + ONE_DAY   // plus 1 day
        finishTime = startTime + 7 * ONE_DAY   // plus 7 days from `startTime`
        params = [amount, startTime, finishTime, amount]
        poolId = await lockDealNFT.totalSupply()
        await timedDealProvider.createNewPool(receiver.address, token.address, params)
        halfTime = (finishTime - startTime) / 2
    })

    it("should check deal provider address", async () => {
        const provider = await timedDealProvider.dealProvider()
        expect(provider.toString()).to.equal(lockProvider.address)
    })

    it("should get timed provider data after creation", async () => {
        poolData = await timedDealProvider.getData(poolId);
        expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
        expect(poolData.params[0]).to.equal(amount);
        expect(poolData.params[1]).to.equal(startTime);
        expect(poolData.params[2]).to.equal(finishTime);
        expect(poolData.params[3]).to.equal(amount);
    })

    it("should check cascade NewPoolCreated event", async () => {
        const tx = await timedDealProvider.createNewPool(receiver.address, token.address, params)
        await tx.wait()
        const event = await dealProvider.queryFilter("NewPoolCreated((uint256,address,address),uint256[])")
        const data = event[event.length - 1].args
        expect(data.poolInfo.poolId).to.equal(parseInt(poolId) + 1)
        expect(data.poolInfo.token).to.equal(token.address)
        expect(data.poolInfo.owner).to.equal(receiver.address)
        expect(data.params[0]).to.equal(amount)
    })

    it("should revert zero owner address", async () => {
        await expect(
            timedDealProvider.createNewPool(receiver.address, constants.AddressZero, params)
        ).to.be.revertedWith("Zero Address is not allowed")
    })

    it("should revert zero token address", async () => {
        await expect(timedDealProvider.createNewPool(constants.AddressZero, token.address, params)).to.be.revertedWith(
            "Zero Address is not allowed"
        )
    })

    it("should revert zero amount", async () => {
        const params = ["0", startTime, finishTime, "0"]
        await expect(timedDealProvider.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
            "amount should be greater than 0"
        )
    })

    describe("Timed Split Amount", () => {
        it("should check data in old pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            
            poolData = await timedDealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
            expect(poolData.params[1]).to.equal(startTime);
            expect(poolData.params[2]).to.equal(finishTime);
            expect(poolData.params[3]).to.equal(amount / 2);
        })

        it("should check data in new pool after split", async () => {
            await lockDealNFT.split(poolId, amount / 2, newOwner.address)

            poolData = await timedDealProvider.getData(parseInt(poolId) + 1);
            expect(poolData.poolInfo).to.deep.equal([parseInt(poolId) + 1, newOwner.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2);
            expect(poolData.params[1]).to.equal(startTime);
            expect(poolData.params[2]).to.equal(finishTime);
            expect(poolData.params[3]).to.equal(amount / 2);
        })

        it("should check event data after split", async () => {
            const tx = await lockDealNFT.split(poolId, amount / 2, newOwner.address)
            await tx.wait()
            const events = await dealProvider.queryFilter("PoolSplit")
            expect(events[events.length - 1].args.poolId).to.equal(poolId)
            expect(events[events.length - 1].args.newPoolId).to.equal(parseInt(poolId) + 1)
            expect(events[events.length - 1].args.owner).to.equal(receiver.address)
            expect(events[events.length - 1].args.newOwner).to.equal(newOwner.address)
            expect(events[events.length - 1].args.splitLeftAmount).to.equal(amount / 2)
            expect(events[events.length - 1].args.newSplitLeftAmount).to.equal(amount / 2)
        })

        it("should split after withdraw", async () => {
            await helpers.time.setNextBlockTimestamp(startTime + halfTime / 5) // 10% of time

            await lockDealNFT.withdraw(poolId)
            await lockDealNFT.split(poolId, parseInt(amount / 2), newOwner.address)

            poolData = await timedDealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(amount / 2 - amount / 10);
            expect(poolData.params[1]).to.equal(startTime);
            expect(poolData.params[2]).to.equal(finishTime);
            expect(poolData.params[3]).to.equal(amount / 2);

            newPoolData = await timedDealProvider.getData(parseInt(poolId) + 1);
            expect(newPoolData.poolInfo).to.deep.equal([parseInt(poolId) + 1, newOwner.address, token.address]);
            expect(newPoolData.params[0]).to.equal(amount / 2);
            expect(newPoolData.params[1]).to.equal(startTime);
            expect(newPoolData.params[2]).to.equal(finishTime);
            expect(newPoolData.params[3]).to.equal(amount / 2);
        })
    })

    describe("Timed Withdraw", () => {
        it("getWithdrawableAmount should return zero before startTime", async () => {
            expect(await timedDealProvider.getWithdrawableAmount(poolId)).to.equal(0)
        })

        it("should withdraw 25% tokens", async () => {
            await helpers.time.setNextBlockTimestamp(startTime + halfTime / 2)

            await lockDealNFT.withdraw(poolId)

            poolData = await timedDealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(amount - amount / 4);
            expect(poolData.params[1]).to.equal(startTime);
            expect(poolData.params[2]).to.equal(finishTime);
            expect(poolData.params[3]).to.equal(amount);
        })

        it("should withdraw half tokens", async () => {
            await helpers.time.setNextBlockTimestamp(startTime + halfTime)

            await lockDealNFT.withdraw(poolId)

            poolData = await timedDealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address]);
            expect(poolData.params[0]).to.equal(amount - amount / 2);
            expect(poolData.params[1]).to.equal(startTime);
            expect(poolData.params[2]).to.equal(finishTime);
            expect(poolData.params[3]).to.equal(amount);
        })

        it("should withdraw all tokens", async () => {
            await helpers.time.setNextBlockTimestamp(finishTime + 1)

            await lockDealNFT.withdraw(poolId)

            poolData = await timedDealProvider.getData(poolId);
            expect(poolData.poolInfo).to.deep.equal([poolId, constants.AddressZero, token.address]);
            expect(poolData.params[0]).to.equal(0);
            expect(poolData.params[1]).to.equal(startTime);
            expect(poolData.params[2]).to.equal(finishTime);
            expect(poolData.params[3]).to.equal(amount);
        })
    })

    describe("test higher cascading providers", () => {
        beforeEach(async () => {
            poolId = await lockDealNFT.totalSupply()
            await mockProvider.createNewPool(receiver.address, token.address, params)
            await helpers.time.setNextBlockTimestamp(startTime)
        })

        it("should register data", async () => {
            poolData = await mockProvider.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address])
            expect(poolData.params[0]).to.equal(amount)
            expect(poolData.params[1]).to.equal(startTime)
            expect(poolData.params[2]).to.equal(finishTime)
            expect(poolData.params[3]).to.equal(amount)
        })

        it("should withdraw half tokens with higher mock provider", async () => {
            await mockProvider.withdraw(poolId, amount / 2)
            poolData = await mockProvider.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address])
            expect(poolData.params[0]).to.equal(amount / 2)
            expect(poolData.params[1]).to.equal(startTime)
            expect(poolData.params[2]).to.equal(finishTime)
            expect(poolData.params[3]).to.equal(amount)
        })

        it("should withdraw all tokens with higher mock provider", async () => {
            await mockProvider.withdraw(poolId, amount)
            poolData = await mockProvider.getData(poolId)
            expect(poolData.poolInfo).to.deep.equal([poolId, receiver.address, token.address])
            expect(poolData.params[0]).to.equal(0)
            expect(poolData.params[1]).to.equal(startTime)
            expect(poolData.params[2]).to.equal(finishTime)
            expect(poolData.params[3]).to.equal(amount)
        })

        it("invalid provider can't change data", async () => {
            const invalidContract = await deployed("MockProvider", timedDealProvider.address)
            await expect(invalidContract.createNewPool(receiver.address, token.address, params)).to.be.revertedWith(
                "invalid provider address"
            )
        })

        it("invalid provider can't withdraw", async () => {
            const invalidContract = await deployed("MockProvider", timedDealProvider.address)
            await expect(invalidContract.withdraw(poolId, amount / 2)).to.be.revertedWith(
                "invalid provider address"
            )
        })
    })
})
