const { devConstants,mochaContexts  } = require("../../../node_modules/dev-utils");
const BigNumber = require("../../../node_modules/bignumber.js");
const dayjs = require("../../../node_modules/dayjs")
const truffleAssert = require("../../../node_modules/truffle-assertions");
const should = require('../../../node_modules/chai')
    .use(require('../../../node_modules/chai-bignumber')(BigNumber))
    .should();

const { contextForStreamDidEnd, contextForStreamDidStartButNotEnd } = mochaContexts;
const {
    STANDARD_RATE_PER_SECOND,
    STANDARD_SALARY,
    STANDARD_TIME_OFFSET,
} = devConstants;

function runTests(){
    describe("when not paused",function() {
        describe ("when the contract has enough allowance",function() {
            describe("when the sender has enough tokens",function() {
                const amount = STANDARD_SALARY.toString(10);

                beforeEach(async function() {
                    await this.token.approve(this.streamPayOfFixedFlowrate.address,amount, this.opts);
                });

                describe("when the amount is valid",function() {
                    describe("when the block.timestamp is before maxStopTime",function() {

                        it("transfers the tokens to the contract",async  function() {
                            const balance = await this.token.balanceOf(this.sender,this.opts);
                            await this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId, amount, this.opts);
                            const newBalance = await this.token.balanceOf(this.sender,this.opts);
                            newBalance.should.be.bignumber.equal(balance.minus(amount));
                        });

                        it("increase the maxAmount",async function() {
                            await this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId, amount, this.opts);
                            const fixedFlowrateObject = await this.streamPayOfFixedFlowrate.getFixedFlowrateStream(this.streamId);
                            fixedFlowrateObject.maxAmount.should.be.bignumber.equal(STANDARD_SALARY.plus(amount));
                        });

                        it("increase the maxStopTime",async function() {
                            await this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId, amount, this.opts);
                            const fixedFlowrateObject = await this.streamPayOfFixedFlowrate.getFixedFlowrateStream(this.streamId);
                            fixedFlowrateObject.maxStopTime.should.be.bignumber.equal(this.startTime.plus(fixedFlowrateObject.maxAmount / STANDARD_RATE_PER_SECOND));
                        });

                        it("emit a stream event",async function() {
                            const result = await this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId,amount,this.opts,);
                            truffleAssert.eventEmitted(result,"TransferWithFixedFlowrate")
                        });
                    });

                    contextForStreamDidEnd(function() {
                        it("when the block.timestamp is after maxStopTime",async function() {
                            await truffleAssert.reverts(
                                this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId,amount,this.opts,),
                                truffleAssert.ErrorType.REVERT,
                            );
                        });
                    })
                });

                describe("when the maxAmount is zero",function() {
                    const amount = new BigNumber(0).toString(10);

                    it("reverts",async function() {
                        await this.token.approve(this.streamPayOfFixedFlowrate.address, amount, this.opts);
                        await truffleAssert.reverts(
                            this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId,amount,this.opts,),
                            "maxAmount is 0",
                        );
                    });
                });
            });

            describe("when the sender does not have enough tokens",function() {
                const amount = STANDARD_SALARY.multipliedBy(10).toString(10);

                it("reverts",async function() {
                    await this.token.approve(this.streamPayOfFixedFlowrate.address, amount, this.opts);
                    await truffleAssert.reverts(
                        this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId,amount,this.opts,),
                        truffleAssert.ErrorType.REVERT,
                    );
                });
            });
        });

        describe("when the stream does not have enough allowance",function () {
            const amount = STANDARD_SALARY.toString(10);

            beforeEach(async function() {
                await this.token.approve(this.streamPayOfFixedFlowrate.address,STANDARD_SALARY.minus(5).toString(10), this.opts);
            })

            describe("when the sender has enough tokens",function() {

                it("reverts",async function() {
                    await truffleAssert.reverts(
                        this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId,amount,this.opts,),
                        truffleAssert.ErrorType.REVERT,
                    );
                });
            });

            describe("when the sender does not have enough tokens",function() {
                const amount = STANDARD_SALARY.multipliedBy(5).toString(10);

                it("reverts",async function() {
                    await truffleAssert.reverts(
                        this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId,amount,this.opts,),
                        truffleAssert.ErrorType.REVERT,
                    );
                });
            });
        });
    });

    describe("when paused", function() {
        const amount = STANDARD_SALARY.toString(10);

        beforeEach(async function() {
            await this.token.approve(this.streamPayOfFixedFlowrate.address,amount, this.opts);
            await this.streamPayOfFixedFlowrate.pause(this.opts);
        });

        it("reverts",async function() {
            await truffleAssert.reverts(
                this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(this.streamId,amount,this.opts,),
                "Pausable: paused",
            );
        });
    });
}


function shouldBehaveLikeFixedFlowrateTransferStream(alice, bob) {
    const now = new BigNumber(dayjs().unix());

    describe("when the stream exists",function() {

        beforeEach(async function() {
            this.sender = alice;
            this.recipient = bob;
            this.maxAmount = STANDARD_SALARY.toString(10);
            this.ratePersecond = STANDARD_RATE_PER_SECOND.toString(10);
            this.startTime = now.plus(STANDARD_TIME_OFFSET);
            const opts = { from: this.sender };
            await this.token.approve(this.streamPayOfFixedFlowrate.address, this.maxAmount, opts);
            const result = await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(
                this.recipient,
                this.maxAmount,
                this.token.address,
                this.ratePersecond,
                this.startTime,
                opts,
            );
            this.streamId = Number(result.logs[0].args.streamId);
        });

        describe("when the streamId is exist", function() {
            beforeEach(function() {
                this.opts = { from: this.sender };
            });

            runTests();
        });

        describe("when the stream does not exist", function() {
            const recipient = bob;
            const opts = { from: recipient };
            const amount = STANDARD_SALARY.toString(10);

            it("reverts", async function() {
                const streamId = new BigNumber(419863);
                await truffleAssert.reverts(
                    this.streamPayOfFixedFlowrate.transferWithFixedFlowrate(streamId,amount,opts,),
                    "stream does not exist");
            });
        });
    });
}


module.exports = shouldBehaveLikeFixedFlowrateTransferStream;

