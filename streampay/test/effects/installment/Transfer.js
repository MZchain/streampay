const { devConstants,installment_mocha  } = require("../../../node_modules/dev-utils");
const BigNumber = require("../../../node_modules/bignumber.js");
const dayjs = require("../../../node_modules/dayjs")
const truffleAssert = require("../../../node_modules/truffle-assertions");
const should = require('../../../node_modules/chai')
    .use(require('../../../node_modules/chai-bignumber')(BigNumber))
    .should();
const traveler = require("../../../node_modules/ganache-time-traveler");


const { streamStartOfOne, streamStartOfTwo,streamStartOfThree,contextForStreamDidEnd } = installment_mocha;
const {
    STANDARD_SALARY,
    STANDARD_TIME_OFFSET,
    STANDARD_TIME_DELTA,
    NUMBEROFINSTALLMENTS,
    FEESOFRECIPIENTPER
} = devConstants;

function shouldBehaveLikeInstallmentTransferStream(alice, bob) {
    const now = new BigNumber(dayjs().unix());
    const startTime = now.plus(STANDARD_TIME_OFFSET);
    const stopTime = startTime.plus(STANDARD_TIME_DELTA);

    describe("when the stream exists",function() {
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

        describe("when the streamId is exist", function() {
            beforeEach(function() {
                this.opts = { from: this.sender };
            });

            runTests();
        });

        describe("when the stream does not exist", function() {
            streamStartOfOne(function() {
                const recipient = bob;
                const opts = { from: recipient };

                it("reverts", async function() {
                    const streamId = new BigNumber(419863);
                    await truffleAssert.reverts(
                        this.streamPayOfInstallment.transferWithInstallment(streamId,opts,),
                        "stream does not exist");
                });
            })

        });
    });
}

function runTests(){
    describe("when not paused",function() {
        describe("when the stream did not start", function () {
            it("reverts", async function() {
                await truffleAssert.reverts(
                    this.streamPayOfInstallment.transferWithInstallment(this.streamId,this.opts),
                    truffleAssert.ErrorType.REVERT,
                );
            });
        });

        streamStartOfOne(function() {
            it("transfers the tokens to the contract", async function() {
                const balance = await this.token.balanceOf(this.sender, this.opts);
                await this.streamPayOfInstallment.transferWithInstallment(this.streamId, this.opts);
                const newBalance = await this.token.balanceOf(this.sender, this.opts);
                balance.should.be.bignumber.equal(newBalance.plus(STANDARD_SALARY / NUMBEROFINSTALLMENTS))
            });

            it("emit a stream event", async function () {
                const result = await this.streamPayOfInstallment.transferWithInstallment(this.streamId, this.opts,);
                truffleAssert.eventEmitted(result, "TransferWithInstallment")
            });

            it("get startTime",async function() {
                const streamObject = await this.streamPayOfInstallment.getInstallmentStream(this.streamId);
                console.log(streamObject.startTime);
                console.log(streamObject.stopTime);
                const time = await this.streamPayOfInstallment.getTime();
                console.log(time);
            });
        });


        streamStartOfTwo(function() {
            it("transfers the tokens to the contract", async function() {
                const balance = await this.token.balanceOf(this.sender, this.opts);
                await this.streamPayOfInstallment.transferWithInstallment(this.streamId, this.opts);
                const newBalance = await this.token.balanceOf(this.sender, this.opts);
                balance.should.be.bignumber.equal(newBalance.plus(STANDARD_SALARY / NUMBEROFINSTALLMENTS))
            });

            it("emit a stream event", async function () {
                const result = await this.streamPayOfInstallment.transferWithInstallment(this.streamId, this.opts,);
                truffleAssert.eventEmitted(result, "TransferWithInstallment")
            });

            it("get startTime",async function() {
                const streamObject = await this.streamPayOfInstallment.getInstallmentStream(this.streamId);
                console.log(streamObject.startTime);
                console.log(streamObject.stopTime);
                const time = await this.streamPayOfInstallment.getTime();
                console.log(time);
            });
        });

        streamStartOfThree(function() {
            it("reverts",async function() {
                await truffleAssert.reverts(
                    this.streamPayOfInstallment.transferWithInstallment(this.streamId,this.opts,),
                    "installment is finish",
                );
            });
        });

        contextForStreamDidEnd(function() {
            it("reverts",async function() {
                await truffleAssert.reverts(
                    this.streamPayOfInstallment.transferWithInstallment(this.streamId,this.opts,),
                    "installment is finish",
                );
            });
        });

    });

    describe("when paused",function() {
        streamStartOfOne(function() {
            beforeEach(async function() {
                await this.streamPayOfInstallment.pause(this.opts);
            })

            it("reverts",async function() {
                await truffleAssert.reverts(
                    this.streamPayOfInstallment.transferWithInstallment(this.streamId,this.opts,),
                    "Pausable: paused",
                );
            });
        });
    });
}

module.exports = shouldBehaveLikeInstallmentTransferStream;

