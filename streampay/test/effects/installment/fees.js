const { devConstants  } = require("../../../node_modules/dev-utils");
const BigNumber = require("../../../node_modules/bignumber.js");
const dayjs = require("../../../node_modules/dayjs")
const truffleAssert = require("../../../node_modules/truffle-assertions");
const should = require('../../../node_modules/chai')
    .use(require('../../../node_modules/chai-bignumber')(BigNumber))
    .should();
const traveler = require("../../../node_modules/ganache-time-traveler");


const {
    STANDARD_RATE_PER_SECOND,
    STANDARD_TIME_OFFSET,
    STANDARD_TIME_DELTA,
} = devConstants;

function shouldBehaveLikeInstallmentFee(alice, bob) {
    const sender = alice;
    const opts = { from: sender };
    const now = new BigNumber(dayjs().unix());
    const recipient = bob;
    const startTime = now.plus(STANDARD_TIME_OFFSET);
    const stopTime = startTime.plus(462);
    const deposit = new BigNumber(3000000000000000000);
    const NUMBEROFINSTALLMENTS = 3;
    const feesOfRecipientPer = 100000;

    // const feesOfRecipientPer = new BigNumber(1000000).toString(10);
    // const fees = new BigNumber(STANDARD_TIME_DELTA * NUMBEROFINSTALLMENTS * feesOfRecipientPer * 3600);

    describe("when the streamPayOfInstallment contract has enough allowance", function() {
        beforeEach(async function() {
            await this.token.approve(this.streamPayOfInstallment.address, deposit.toString(10), opts);
        });

        describe("crete installmentStream",function() {
            it("creates the stream", async function() {
                const result = await this.streamPayOfInstallment.createInstallmentStream(
                    recipient,
                    deposit,
                    this.token.address,
                    startTime,
                    stopTime,
                    NUMBEROFINSTALLMENTS,
                    feesOfRecipientPer,
                    opts,
                );
                this.streamId = Number(result.logs[0].args.streamId);
                //计算fee
                // const streamObject = await this.streamPayOfInstallment.getInstallmentStream(Number(result.logs[0].args.streamId));
                // const balance = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,sender,opts);
                // console.log(balance.toString());

                //计算提取金额
                // await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(100).toNumber(),);
                // const withdrawalAmount = new BigNumber(100000000);
                // await this.streamPayOfInstallment.withdrawInstallmentStream(this.streamId, withdrawalAmount, opts);
                // const balance = await this.token.balanceOf(recipient);
                // console.log(balance.toString())
                // await traveler.advanceBlockAndSetTime(now.toNumber());

                //计算getEarnings
                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(100).toNumber(),);
                const withdrawalAmount = new BigNumber(100000000);
                await this.streamPayOfInstallment.updateFeesOfProtocolPer(5000);
                await this.streamPayOfInstallment.withdrawInstallmentStream(this.streamId, withdrawalAmount, opts);
                const balance = await this.token.balanceOf(recipient);
                console.log(balance.toString());
                const balance1 = await this.streamPayOfInstallment.getEarnings(this.token.address);
                console.log(balance1.toString());

                await traveler.advanceBlockAndSetTime(now.toNumber());




                // console.log(streamObject.deposit.toString());
                // console.log(streamObject.startTime.toString());
                // console.log(streamObject.stopTime.toString());
                // console.log(streamObject.numberOfInstallments.toString());
                // console.log(streamObject.ratePerSecond.toString());
                // console.log(streamObject.haveBeenNumberOfInstallment.toString());
                // console.log(streamObject.feesOfRecipientPer.toString());

                // streamObject.sender.should.be.equal(sender);
                // streamObject.recipient.should.be.equal(recipient);
                // streamObject.deposit.should.be.bignumber.equal(deposit);
                // streamObject.tokenAddress.should.be.equal(this.token.address);
                // streamObject.startTime.should.be.bignumber.equal(startTime);
                // streamObject.stopTime.should.be.bignumber.equal(stopTime);
                // streamObject.numberOfInstallments.should.be.bignumber.equal(NUMBEROFINSTALLMENTS);
                // streamObject.feesOfRecipientPer.should.be.bignumber.equal(feesOfRecipientPer);
                // streamObject.ratePerSecond.should.be.bignumber.equal(1);
            });
        });
        // describe('balance',async function() {
            // it("not stoptime",async function() {
            //     const result = await this.streamPayOfInstallment.createInstallmentStream(
            //         recipient,
            //         deposit,
            //         this.token.address,
            //         startTime,
            //         stopTime,
            //         NUMBEROFINSTALLMENTS,
            //         feesOfRecipientPer,
            //         opts,
            //     );
            //     this.streamId = Number(result.logs[0].args.streamId);
            //
            //     //第一期
            //     await this.streamPayOfInstallment.transferWithInstallment(this.streamId, opts);
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(153).toNumber(),);
            //
            //     const balance = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance.toString());
            //
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(154).toNumber(),);
            //     const balance1 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance1.toString());
            //
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(155).toNumber(),);
            //     const balance2 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance2.toString());
            //
            //
            //     //第二期
            //
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(307).toNumber(),);
            //     // await this.streamPayOfInstallment.transferWithInstallment(this.streamId, opts);
            //     const balance4 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance4.toString());
            //
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(308).toNumber(),);
            //     const balance5 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance5.toString());
            //
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(309).toNumber(),);
            //     const balance6 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance6.toString());
            //
            //     //第三期
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(461).toNumber(),);
            //     const balance7 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance7.toString());
            //
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(462).toNumber(),);
            //     const balance8 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance8.toString());
            //
            //     await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(463).toNumber(),);
            //     const balance9 = await this.streamPayOfInstallment.installmentBalanceOf.call(this.streamId,recipient,opts);
            //     console.log(balance9.toString());
            //
            //     await traveler.advanceBlockAndSetTime(now.toNumber());
            // });
        // });
    });
}

module.exports = shouldBehaveLikeInstallmentFee;