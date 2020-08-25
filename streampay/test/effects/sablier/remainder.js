const { devConstants  } = require("../../../node_modules/dev-utils");
const BigNumber = require("../../../node_modules/bignumber.js");
const dayjs = require("../../../node_modules/dayjs")
const truffleAssert = require("../../../node_modules/truffle-assertions");
const should = require('../../../node_modules/chai')
    .use(require('../../../node_modules/chai-bignumber')(BigNumber))
    .should();
const traveler = require("../../../node_modules/ganache-time-traveler");


const {
    STANDARD_TIME_OFFSET,
    STANDARD_TIME_DELTA,
} = devConstants;

function shouldBehaveLikeERC1620Stream(alice, bob) {
    const sender = alice;
    const opts = { from: sender };
    const now = new BigNumber(dayjs().unix());
    const recipient = bob;
    const startTime = now.plus(STANDARD_TIME_OFFSET);
    const stopTime = startTime.plus(895);
    const deposit = new BigNumber(36000556460);

    describe("when the sablier contract has enough allowance", function() {
        beforeEach(async function() {
            await this.token.approve(this.sablier.address, deposit.toString(10), opts);
        });

        // describe("create stream", async function() {
        //     it("creates the stream", async function() {
        //         const result = await this.sablier.createStream(
        //             recipient,
        //             deposit,
        //             this.token.address,
        //             startTime,
        //             stopTime,
        //             opts,
        //         );
        //         const streamObject = await this.sablier.getStream(Number(result.logs[0].args.streamId));
        //         console.log(streamObject.ratePerSecond.toString(10));
        //         console.log(streamObject.startTime.toString(10));
        //         console.log(streamObject.stopTime.toString(10));
        //         console.log(streamObject.deposit.toString(10));
        //
        //         // streamObject.sender.should.be.equal(sender);
        //         // streamObject.recipient.should.be.equal(recipient);
        //         // streamObject.deposit.should.be.bignumber.equal(deposit);
        //         // streamObject.tokenAddress.should.be.equal(this.token.address);
        //         // streamObject.startTime.should.be.bignumber.equal(startTime);
        //         // streamObject.stopTime.should.be.bignumber.equal(stopTime);
        //         // streamObject.ratePerSecond.should.be.bignumber.equal(STANDARD_RATE_PER_SECOND);
        //     });
        // });

        describe('balance',async function() {
            it("not stoptime",async function() {
                const result = await this.sablier.createStream(
                    recipient,
                    deposit,
                    this.token.address,
                    startTime,
                    stopTime,
                    opts,
                );

                this.streamId = Number(result.logs[0].args.streamId);
                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(893).toNumber(),);
                const balance3 = await this.sablier.balanceOf(this.streamId,recipient,opts);
                console.log(balance3.toString());

                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(894).toNumber(),);
                const balance = await this.sablier.balanceOf(this.streamId,recipient,opts);
                console.log(balance.toString());

                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(895).toNumber(),);
                const balance1 = await this.sablier.balanceOf(this.streamId,recipient,opts);
                console.log(balance1.toString());

                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(896).toNumber(),);
                const balance2 = await this.sablier.balanceOf(this.streamId,recipient,opts);
                console.log(balance2.toString());

                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(1000).toNumber(),);
                const balance4 = await this.sablier.balanceOf(this.streamId,recipient,opts);
                console.log(balance4.toString());

                await traveler.advanceBlockAndSetTime(now.toNumber());
            });


        })
    });
}

module.exports = shouldBehaveLikeERC1620Stream;