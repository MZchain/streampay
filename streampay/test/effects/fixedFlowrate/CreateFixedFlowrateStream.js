const { devConstants,mochaContexts  } = require("../../../node_modules/dev-utils");
const BigNumber = require("../../../node_modules/bignumber.js");
const dayjs = require("../../../node_modules/dayjs")
const truffleAssert = require("../../../node_modules/truffle-assertions");
const should = require('../../../node_modules/chai')
    .use(require('../../../node_modules/chai-bignumber')(BigNumber))
    .should();

const {
    STANDARD_RATE_PER_SECOND,
    STANDARD_SALARY,
    STANDARD_TIME_OFFSET,
    ZERO_ADDRESS,
} = devConstants;

function shouldBehaveLikeFixedFlowrateStream(alice,bob){
    const sender = alice;
    const opts = {from:sender};
    const now = new BigNumber(dayjs().unix());

    describe("when not paused",function() {
        describe("when the recipient is valid",function() {
            const recipient = bob;

            describe ("when the contract has enough allowance",function() {
                beforeEach(async  function() {
                    await this.token.approve(this.streamPayOfFixedFlowrate.address,STANDARD_SALARY.toString(10),opts)
                });

                describe("when the sender has enough tokens",function() {
                    describe("when the maxAmount is valid",function() {
                        const maxAmount = STANDARD_SALARY.toString(10);

                        describe("when the ratepersecond is valid",function() {
                            const ratePersecond = STANDARD_RATE_PER_SECOND.toString(10);

                            describe("when the start time is after block.timestamp",function() {
                                const startTime = now.plus(STANDARD_TIME_OFFSET);
                                const maxStopTime = startTime.plus(STANDARD_SALARY / STANDARD_RATE_PER_SECOND);

                                it("create the stream",async function() {
                                    const result = await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(
                                        recipient,
                                        maxAmount,
                                        this.token.address,
                                        ratePersecond,
                                        startTime,
                                        opts,
                                    );
                                    const fixedFlowrateObject = await this.streamPayOfFixedFlowrate.getFixedFlowrateStream(Number(result.logs[0].args.streamId));
                                    fixedFlowrateObject.sender.should.be.equal(sender);
                                    fixedFlowrateObject.recipient.should.be.equal(recipient);
                                    fixedFlowrateObject.maxAmount.should.be.bignumber.equal(maxAmount);
                                    fixedFlowrateObject.tokenAddress.should.be.equal(this.token.address);
                                    fixedFlowrateObject.startTime.should.be.bignumber.equal(startTime);
                                    fixedFlowrateObject.maxStopTime.should.be.bignumber.equal(maxStopTime);
                                    fixedFlowrateObject.ratePerSecond.should.be.bignumber.equal(ratePersecond);
                                    fixedFlowrateObject.withdrawalAmount.should.be.bignumber.equal(0);
                                });

                                it("transfers the tokens to the contract",async  function() {
                                    const balance = await this.token.balanceOf(sender,opts);
                                    await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts);
                                    const newBalance = await this.token.balanceOf(sender,opts);
                                    newBalance.should.be.bignumber.equal(balance.minus(STANDARD_SALARY));
                                });

                                it("increase the stream id",async function() {
                                    const nextStreamId= await this.streamPayOfFixedFlowrate.nextStreamId();
                                    await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts);
                                    const newNextStreamId = await this.streamPayOfFixedFlowrate.nextStreamId();
                                    newNextStreamId.should.be.bignumber.equal(nextStreamId.plus(1));
                                })

                                it("emit a stream event",async function() {
                                    const result = await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(
                                        recipient,
                                        maxAmount,
                                        this.token.address,
                                        ratePersecond,
                                        startTime,
                                        opts,
                                    );
                                    truffleAssert.eventEmitted(result,"CreateFixedFlowrateStream")
                                })
                            });


                            describe("when the start time is not after block.timestamp", function() {
                                let startTime;

                                beforeEach(async function() {
                                    startTime = now.minus(STANDARD_TIME_OFFSET);
                                });

                                it("reverts",async function() {
                                    await truffleAssert.reverts(
                                        this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                                        "start time before block.timestamp",
                                    );
                                });
                            });
                        });

                        describe("when the ratePersecond is not valid",async function() {
                            const startTime = now.plus(STANDARD_TIME_OFFSET);
                            const ratePersecond = new BigNumber(0).toString(10);

                            it("reverts",async function() {
                                await truffleAssert.reverts(
                                    this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                                    "ratePerSecond is 0",
                                );
                            });
                        });
                    });

                    describe("when the maxAmount is not valid",async function() {
                        const startTime = now.plus(STANDARD_TIME_OFFSET);
                        const ratePersecond = STANDARD_RATE_PER_SECOND.toString(10);

                        describe("when the maxAmount is zero",function() {
                            const maxAmount = new BigNumber(0).toString(10);

                            it("reverts",async function() {
                                await truffleAssert.reverts(
                                    this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                                    "maxAmount is 0",
                                );
                            });
                        });

                        describe("when the maxAmount is smaller than the time delta",function() {
                            const maxAmount = STANDARD_RATE_PER_SECOND.minus(1).toString(10);

                            it("reverts",async function() {
                                await truffleAssert.reverts(
                                    this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                                    "maxAmount is smaller than ratePerSecond",
                                );
                            });
                        });
                    });
                });

                describe("when the sender does not have enough tokens",function() {
                    const startTime = now.plus(STANDARD_TIME_OFFSET);
                    const maxAmount = STANDARD_SALARY.multipliedBy(2).toString(10);
                    const ratePersecond = new BigNumber(0).toString(10);


                    it("reverts",async function() {
                        await truffleAssert.reverts(
                            this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                            truffleAssert.ErrorType.REVERT,
                        );
                    });
                });
            });

            describe("when the stream does not have enough allowance",function () {
                let startTime;
                const ratePersecond = new BigNumber(0).toString(10);

                beforeEach(async function() {
                    startTime = now.plus(STANDARD_TIME_OFFSET);
                    await this.token.approve(this.streamPayOfFixedFlowrate.address, STANDARD_SALARY.minus(5).toString(10), opts);
                })

                describe("when the sender has enough tokens",function() {
                    const maxAmount = STANDARD_SALARY.toString(10);

                    it("reverts",async function() {
                        await truffleAssert.reverts(
                            this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                            truffleAssert.ErrorType.REVERT,
                        );
                    });
                });

                describe("when the sender does not have enough tokens",function() {
                    const maxAmount = STANDARD_SALARY.multipliedBy(2).toString(10);

                    it("reverts",async function() {
                        await truffleAssert.reverts(
                            this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                            truffleAssert.ErrorType.REVERT,
                        );
                    });
                });
            });
        });

        describe("when the recipient is the caller itself",function() {
            const recipient = sender;
            const startTime = now.plus(STANDARD_TIME_OFFSET);
            const maxAmount = STANDARD_SALARY.multipliedBy(2).toString(10);
            const ratePersecond = new BigNumber(0).toString(10);


            it("reverts",async function() {
                await truffleAssert.reverts(
                    this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                    "stream to the caller",
                );
            });
        });

        describe("when the recipient is the contract itself", function() {
            const startTime = now.plus(STANDARD_TIME_OFFSET);
            const maxAmount = STANDARD_SALARY.multipliedBy(2).toString(10);
            const ratePersecond = new BigNumber(0).toString(10);

            it("reverts", async function() {
                const recipient = this.streamPayOfFixedFlowrate.address;

                await truffleAssert.reverts(
                    this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                    "stream to the contract",
                );
            });
        });

        describe("when the recipient is the zero address", function() {
            const recipient = ZERO_ADDRESS;
            const startTime = now.plus(STANDARD_TIME_OFFSET);
            const maxAmount = STANDARD_SALARY.multipliedBy(2).toString(10);
            const ratePersecond = new BigNumber(0).toString(10);

            it("reverts",async function() {
                await truffleAssert.reverts(
                    this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                    "stream to the zero address",
                );
            });
        });
    });

    describe("when paused", function() {
        const recipient = bob;
        const maxAmount = STANDARD_SALARY.toString(10);
        const startTime = now.plus(STANDARD_TIME_OFFSET);
        const ratePersecond = new BigNumber(0).toString(10);

        beforeEach(async function() {
            await this.streamPayOfFixedFlowrate.pause(opts);
        });

        it("reverts",async function() {
            await truffleAssert.reverts(
                this.streamPayOfFixedFlowrate.createFixedFlowrateStream(recipient, maxAmount, this.token.address, ratePersecond, startTime, opts),
                "Pausable: paused",
            );
        });
    });
}

module.exports = shouldBehaveLikeFixedFlowrateStream;

