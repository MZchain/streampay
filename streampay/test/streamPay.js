const { devConstants } = require("../node_modules/dev-utils");
const shouldBehaveLikeStreamPay  = require("./streamPay.behavior");

const testDAI = artifacts.require("TestnetDAI");
const sablier = artifacts.require("./sablier.sol")
const streamPayOfFixedFlowrate = artifacts.require("./streamPayOfFixedFlowrate.sol");
const streamPayOfInstallment = artifacts.require("./streamPayOfInstallment.sol");
const streamPayOfInstallmentWithDP = artifacts.require("./streamPayOfInstallmentWithDP.sol");

testDAI.numberFormat = "BigNumber";
sablier.numberFormat = "BigNumber";
streamPayOfFixedFlowrate.numberFormat = "BigNumber";
streamPayOfInstallment.numberFormat = "BigNumber";
streamPayOfInstallmentWithDP.numberFormat = "BigNumber";

const { STANDARD_SALARY } = devConstants;

contract("streamPay",function streamPay([alice,bob,carol,eve]) {
    beforeEach(async function() {
        const opts = {from:alice};
        this.token = await testDAI.new(opts);
        await this.token.mint(alice,STANDARD_SALARY.multipliedBy(3).toString(10),opts);
        await this.token.approve(this.token.address, STANDARD_SALARY.toString(10), opts);
        this.sablier = await sablier.new(opts)
        this.streamPayOfFixedFlowrate = await streamPayOfFixedFlowrate.new(opts);
        this.streamPayOfInstallment = await streamPayOfInstallment.new(opts);
        this.streamPayOfInstallmentWithDP = await streamPayOfInstallmentWithDP.new(opts);
    });

    shouldBehaveLikeStreamPay(alice,bob,carol,eve);
})