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
    STANDARD_SALARY,
    STANDARD_TIME_OFFSET,
    ZERO_ADDRESS,
} = devConstants;

function shouldBehaveLikeFixedFlowrateRemainder(alice, bob) {
    const sender = alice;
    const opts = { from: sender };
    const now = new BigNumber(dayjs().unix());
    const recipient = bob;
    const startTime = now.plus(STANDARD_TIME_OFFSET);
    const maxAmount = new BigNumber(2005105000);
    const ratePersecond = new BigNumber(45132132).toString(10);

    describe("when the sablier contract has enough allowance", function() {
        beforeEach(async function() {
            await this.token.approve(this.streamPayOfFixedFlowrate.address, maxAmount.toString(10), opts);
        });

        // describe("create stream", async function() {
        //     it("create the stream",async function() {
        //         const result = await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(
        //             recipient,
        //             maxAmount,
        //             this.token.address,
        //             ratePersecond,
        //             startTime,
        //             opts,
        //         );
        //         const fixedFlowrateObject = await this.streamPayOfFixedFlowrate.getFixedFlowrateStream(Number(result.logs[0].args.streamId));
        //         console.log(fixedFlowrateObject.startTime);
        //         console.log(fixedFlowrateObject.maxStopTime);
        //     });
        // });

        describe('balance',async function() {
            it("not stoptime",async function() {
                const result = await this.streamPayOfFixedFlowrate.createFixedFlowrateStream(
                    recipient,
                    maxAmount,
                    this.token.address,
                    ratePersecond,
                    startTime,
                    opts,
                );

                this.streamId = Number(result.logs[0].args.streamId);

                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(43).toNumber(),);
                const balance = await this.streamPayOfFixedFlowrate.fixedFlowrateBalanceOf.call(this.streamId,recipient,opts);
                console.log(balance.toString());

                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(44).toNumber(),);
                const balance1 = await this.streamPayOfFixedFlowrate.fixedFlowrateBalanceOf.call(this.streamId,recipient,opts);
                console.log(balance1.toString());

                await traveler.advanceBlockAndSetTime(now.plus(STANDARD_TIME_OFFSET).plus(45).toNumber(),);
                const balance2 = await this.streamPayOfFixedFlowrate.fixedFlowrateBalanceOf.call(this.streamId,recipient,opts);
                console.log(balance2.toString());

                await traveler.advanceBlockAndSetTime(now.toNumber());
            });
        });
    });
}

module.exports = shouldBehaveLikeFixedFlowrateRemainder;