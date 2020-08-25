const { devConstants,mochaContexts  } = require("../../../node_modules/dev-utils");
const BigNumber = require("../../../node_modules/bignumber.js");
const dayjs = require("../../../node_modules/dayjs")
const truffleAssert = require("../../../node_modules/truffle-assertions");
const should = require('../../../node_modules/chai')
    .use(require('../../../node_modules/chai-bignumber')(BigNumber))
    .should();
const traveler = require("../../../node_modules/ganache-time-traveler");



const { contextForStreamDidEnd, contextForStreamDidStartButNotEnd } = mochaContexts;
const { STANDARD_RATE_PER_SECOND, FIVE_UNITS, STANDARD_SALARY, STANDARD_SCALE, STANDARD_TIME_OFFSET, STANDARD_TIME_DELTA } = devConstants;


function runTests() {
    describe("when the stream did not start", function() {
        it("cancels the stream", async function() {
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfFixedFlowrate.getFixedFlowrateStream(this.streamId), "stream does not exist");
        });

        it("transfers all tokens to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            newBalance.should.be.bignumber.equal(balance.plus(this.maxAmount));
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelFixedFlowrateStream");
        });
    });

    contextForStreamDidStartButNotEnd(function() {
        const streamedAmount = FIVE_UNITS.toString(10);

        it("cancels the stream", async function() {
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfFixedFlowrate.getFixedFlowrateStream(this.streamId), "stream does not exist");
        });

        it("transfers the tokens to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            const tolerateByAddition = false;
                newBalance.should.tolerateTheBlockTimeVariation(
                balance.minus(streamedAmount).plus(this.maxAmount),
                STANDARD_SCALE,
                tolerateByAddition,
            );
        });

        it("transfers the tokens to the recipient of the stream", async function() {
            const balance = await this.token.balanceOf(this.recipient, this.opts);
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.recipient, this.opts);
            newBalance.should.tolerateTheBlockTimeVariation(balance.plus(streamedAmount), STANDARD_SCALE);
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelFixedFlowrateStream");
        });
    });

    contextForStreamDidEnd(function() {
        const streamedAmount = STANDARD_SALARY.toString(10);

        it("cancels the stream", async function() {
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            await truffleAssert.reverts(this.streamPayOfFixedFlowrate.getFixedFlowrateStream(this.streamId), "stream does not exist");
        });

        it("transfers nothing to the sender of the stream", async function() {
            const balance = await this.token.balanceOf(this.sender, this.opts);
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.sender, this.opts);
            balance.should.be.bignumber.equal(newBalance)
        });

        it("transfers all tokens to the recipient of the stream", async function() {
            const balance = await this.token.balanceOf(this.recipient, this.opts);
            await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            const newBalance = await this.token.balanceOf(this.recipient, this.opts);
            newBalance.should.be.bignumber.equal(balance.plus(streamedAmount));
        });

        it("emits a cancel event", async function() {
            const result = await this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, this.opts);
            truffleAssert.eventEmitted(result, "CancelFixedFlowrateStream");
        });
    });
}

function shouldBehaveLikeFixedFlowrateCancelStream(alice, bob, eve) {
    const now = new BigNumber(dayjs().unix());

    describe("when the stream exists", function() {
        const startTime = now.plus(STANDARD_TIME_OFFSET);

        beforeEach(async function() {
            this.sender = alice;
            this.recipient = bob;
            this.maxAmount = STANDARD_SALARY.toString(10);
            this.ratePersecond = STANDARD_RATE_PER_SECOND.toString(10);
            const opts = { from: this.sender };
            await this.token.approve(this.streamPayOfFixedFlowrate.address, this.maxAmount, opts);
            const result = await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(
                this.recipient,
                this.maxAmount,
                this.token.address,
                this.ratePersecond,
                startTime,
                opts,
            );
            this.streamId = Number(result.logs[0].args.streamId);
        });

        describe("when the caller is the sender of the stream", function() {
            beforeEach(function() {
                this.opts = { from: this.sender };
            });

            runTests();
        });

        describe("when the caller is the recipient of the stream", function() {
            beforeEach(function() {
                this.opts = { from: this.recipient };
            });

            runTests();
        });

        describe("when the caller is not the sender or the recipient of the stream", function() {
            const opts = { from: eve };

            it("reverts", async function() {
                await truffleAssert.reverts(
                    this.streamPayOfFixedFlowrate.cancelFlowrateStream(this.streamId, opts),
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
            await truffleAssert.reverts(this.streamPayOfFixedFlowrate.cancelFlowrateStream(streamId, opts), "stream does not exist");
        });
    });
}

module.exports = shouldBehaveLikeFixedFlowrateCancelStream;