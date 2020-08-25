const { devConstants,installment_mocha  } = require("../../../node_modules/dev-utils");
const BigNumber = require("../../../node_modules/bignumber.js");
const dayjs = require("../../../node_modules/dayjs")
const truffleAssert = require("../../../node_modules/truffle-assertions");
const should = require('../../../node_modules/chai')
    .use(require('../../../node_modules/chai-bignumber')(BigNumber))
    .should();
const traveler = require("../../../node_modules/ganache-time-traveler");


const {
    STANDARD_SCALE,
    STANDARD_SALARY,
    STANDARD_TIME_OFFSET,
    STANDARD_TIME_DELTA,
    NUMBEROFINSTALLMENTS,
    FEESOFRECIPIENTPER,
    FIVE_UNITS,
} = devConstants;

const { streamStartOfOne} = installment_mocha;

function runTests(feesOfProtocolPer) {
    describe("when the stream did not start", function() {
        it("cancels the stream", async function() {
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfInstallment.getInstallmentStream(this.streamId), "stream does not exist");
        });

        it("transfers all tokens to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            newBalance.should.be.bignumber.equal(balance.plus(this.deposit / NUMBEROFINSTALLMENTS));
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelInstallmentStream");
        });
    });

    streamStartOfOne(function() {
        const streamedAmount = FIVE_UNITS.toString(10);
        const feesOfRrotocol = STANDARD_TIME_DELTA * NUMBEROFINSTALLMENTS * feesOfProtocolPer * 5;

        it("cancels the stream", async function() {
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfInstallment.getInstallmentStream(this.streamId), "stream does not exist");
        });

        it("transfers the tokens to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            const tolerateByAddition = false;
            newBalance.should.tolerateTheBlockTimeVariation(
                balance.minus(streamedAmount).plus(this.deposit / NUMBEROFINSTALLMENTS),
                STANDARD_SCALE,
                tolerateByAddition,
            );
        });

        it("transfers the tokens to the recipient of the stream", async function() {
            const balance = await this.token.balanceOf(this.recipient, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.recipient, this.opts);
            newBalance.should.tolerateTheBlockTimeVariation(balance.plus(streamedAmount - feesOfRrotocol), STANDARD_SCALE);
        });

        it("increase the getEarnings",async function() {
            const balance = await this.streamPayOfInstallment.getEarnings.call(this.token.address);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.streamPayOfInstallment.getEarnings.call(this.token.address);
            newBalance.should.be.bignumber.equal(balance.plus(feesOfRrotocol));
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelInstallmentStream");
        });
    });

    describe("number og two",function() {
        const now = new BigNumber(dayjs().unix());
        const streamedAmount = FIVE_UNITS.multipliedBy(241).toString(10);
        const feesOfRrotocol = STANDARD_TIME_DELTA * NUMBEROFINSTALLMENTS * feesOfProtocolPer * 1205;

        beforeEach(async function() {
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).toNumber(),);
            await this.streamPayOfInstallment.transferWithInstallment(this.streamId, {from:this.sender});
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).plus(1201).toNumber(),);
        })

        it("cancels the stream", async function() {
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfInstallment.getInstallmentStream(this.streamId), "stream does not exist");
        });

        it("transfers the tokens to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            const tolerateByAddition = false;
            newBalance.should.tolerateTheBlockTimeVariation(
                balance.minus(streamedAmount).plus(this.deposit / NUMBEROFINSTALLMENTS * 2),
                STANDARD_SCALE,
                tolerateByAddition,
            );
        });

        it("transfers the tokens to the recipient of the stream", async function() {
            const balance = await this.token.balanceOf(this.recipient, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.recipient, this.opts);
            newBalance.should.tolerateTheBlockTimeVariation(balance.plus(streamedAmount - feesOfRrotocol), STANDARD_SCALE);
        });

        it("increase the getEarnings",async function() {
            const balance = await this.streamPayOfInstallment.getEarnings(this.token.address);
            await this.streamPayOfInstallment.cancelInstallmentStream.call(this.streamId, this.opts);
            const newBalance = await this.streamPayOfInstallment.getEarnings(this.token.address);
            newBalance.should.be.bignumber.equal(balance.plus(feesOfRrotocol));
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelInstallmentStream");
        });

        afterEach(async function() {
            await traveler.advanceBlockAndSetTime(now.toNumber());
        })
    });

    describe("number og three",function() {
        const now = new BigNumber(dayjs().unix());
        const streamedAmount = FIVE_UNITS.multipliedBy(481).toString(10);
        const feesOfRrotocol = STANDARD_TIME_DELTA * NUMBEROFINSTALLMENTS * feesOfProtocolPer * 2405;

        beforeEach(async function() {
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).toNumber(),);
            await this.streamPayOfInstallment.transferWithInstallment(this.streamId, {from:this.sender});
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).plus(1201).toNumber(),);
            await this.streamPayOfInstallment.transferWithInstallment(this.streamId, {from:this.sender});
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).plus(2401).toNumber(),);
        })

        it("cancels the stream", async function() {
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfInstallment.getInstallmentStream(this.streamId), "stream does not exist");
        });

        it("transfers the tokens to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            const tolerateByAddition = false;
            newBalance.should.tolerateTheBlockTimeVariation(
                balance.minus(streamedAmount).plus(this.deposit),
                STANDARD_SCALE,
                tolerateByAddition,
            );
        });

        it("transfers the tokens to the recipient of the stream", async function() {
            const balance = await this.token.balanceOf(this.recipient, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.recipient, this.opts);
            newBalance.should.tolerateTheBlockTimeVariation(balance.plus(streamedAmount - feesOfRrotocol), STANDARD_SCALE);
        });

        it("increase the getEarnings",async function() {
            const balance = await this.streamPayOfInstallment.getEarnings.call(this.token.address);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.streamPayOfInstallment.getEarnings.call(this.token.address);
            newBalance.should.be.bignumber.equal(balance.plus(feesOfRrotocol));
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelInstallmentStream");
        });

        afterEach(async function() {
            await traveler.advanceBlockAndSetTime(now.toNumber());
        })
    });

    describe("end",function() {
        const now = new BigNumber(dayjs().unix());
        const streamedAmount = STANDARD_SALARY.toString(10);
        const feesOfRrotocol = STANDARD_TIME_DELTA * NUMBEROFINSTALLMENTS * feesOfProtocolPer * 2405;

        beforeEach(async function() {
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).toNumber(),);
            await this.streamPayOfInstallment.transferWithInstallment(this.streamId, {from:this.sender});
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).plus(1201).toNumber(),);
            await this.streamPayOfInstallment.transferWithInstallment(this.streamId, {from:this.sender});
            await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(5).plus(3600).toNumber(),);
        })

        it("cancels the stream", async function() {
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfInstallment.getInstallmentStream(this.streamId), "stream does not exist");
        });

        it("transfers the tokens to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            const tolerateByAddition = false;
            newBalance.should.tolerateTheBlockTimeVariation(
                balance.minus(streamedAmount).plus(this.deposit),
                STANDARD_SCALE,
                tolerateByAddition,
            );
        });

        it("transfers the tokens to the recipient of the stream", async function() {
            const balance = await this.token.balanceOf(this.recipient, this.opts);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.recipient, this.opts);
            newBalance.should.tolerateTheBlockTimeVariation(balance.plus(streamedAmount - feesOfRrotocol), STANDARD_SCALE);
        });

        it("increase the getEarnings",async function() {
            const balance = await this.streamPayOfInstallment.getEarnings.call(this.token.address);
            await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            const newBalance = await this.streamPayOfInstallment.getEarnings.call(this.token.address);
            newBalance.should.be.bignumber.equal(balance.plus(feesOfRrotocol));
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelInstallmentStream");
        });

        afterEach(async function() {
            await traveler.advanceBlockAndSetTime(now.toNumber());
        })
    });
}

function shouldBehaveLikeInstallmentCancelStream(alice, bob, eve) {
    const now = new BigNumber(dayjs().unix());

    describe("when the stream exists", function() {
        const startTime = now.plus(STANDARD_TIME_OFFSET);
        const stopTime = startTime.plus(STANDARD_TIME_DELTA);

        beforeEach(async function() {
            this.sender = alice;
            this.recipient = bob;
            this.deposit = STANDARD_SALARY.toString(10);
            const opts = { from: this.sender };
            await this.token.approve(this.streamPayOfInstallment.address, this.deposit, opts);
            const result = await this.streamPayOfInstallment.createInstallmentStream(
                this.recipient,
                this.deposit,
                this.token.address,
                startTime,
                stopTime,
                NUMBEROFINSTALLMENTS,
                FEESOFRECIPIENTPER,
                opts,
            );
            this.streamId = Number(result.logs[0].args.streamId);
        });

        describe("when the caller is the sender of the stream", function() {
            beforeEach(function() {
                this.opts = { from: this.sender };
            });

            describe("when feesOfProtocolPer is 0",function() {
                const feesOfProtocolPer = new BigNumber(0).toString();
                beforeEach(async function() {
                    await this.streamPayOfInstallment.updateFeesOfProtocolPer(feesOfProtocolPer,{from:alice});
                })
                runTests(feesOfProtocolPer);
            });

            // describe("when feesOfProtocolPer is not 0",function() {
            //     const feesOfProtocolPer = new BigNumber(1000000).toString();
            //     beforeEach(async function() {
            //         await this.streamPayOfInstallment.updateFeesOfProtocolPer(feesOfProtocolPer,{from:alice});
            //     })
            //     runTests(feesOfProtocolPer);
            // });
        });

        // describe("when the caller is the recipient of the stream", function() {
        //     beforeEach(function() {
        //         this.opts = { from: this.recipient };
        //     });
        //
        //     describe("when feesOfProtocolPer is 0",function() {
        //         const feesOfProtocolPer = new BigNumber(0).toString();
        //         beforeEach(async function() {
        //             await this.streamPayOfInstallment.updateFeesOfProtocolPer(feesOfProtocolPer,{from:alice});
        //         })
        //         runTests(feesOfProtocolPer);
        //     });
        //
        //     describe("when feesOfProtocolPer is not 0",function() {
        //         const feesOfProtocolPer = new BigNumber(1000000).toString();
        //         beforeEach(async function() {
        //             await this.streamPayOfInstallment.updateFeesOfProtocolPer(feesOfProtocolPer,{from:alice});
        //         })
        //         runTests(feesOfProtocolPer);
        //     });
        // });

        describe("when the caller is not the sender or the recipient of the stream", function() {
            const opts = { from: eve };

            it("reverts", async function() {
                await truffleAssert.reverts(
                    this.streamPayOfInstallment.cancelInstallmentStream(this.streamId, opts),
                    "caller is not the sender or the recipient of the stream",
                );
            });
        });
    });

    describe("when the stream does not exist", function() {
        const recipient = bob;
        const opts = { from: recipient };

        it("reverts", async function() {
            const streamId = new BigNumber(419863);
            await truffleAssert.reverts(this.streamPayOfInstallment.cancelInstallmentStream(streamId, opts), "stream does not exist");
        });
    });
}

module.exports = shouldBehaveLikeInstallmentCancelStream;