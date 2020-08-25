const { devConstants } = require("../node_modules/dev-utils");
const truffleAssert = require("../node_modules/truffle-assertions");

//FixedFlowrate
const shouldBehaveLikeFixedFlowrateStream = require("./effects/fixedFlowrate/CreateFixedFlowrateStream");
const shouldBehaveLikeFixedFlowrateCancelStream = require("./effects/fixedFlowrate/CancelFixedFlowrateStream");
const shouldBehaveLikeFixedFlowrateWithdrawFromStream = require("./effects/fixedFlowrate/WithdrawFromFixedFlowrateStream");
const shouldBehaveLikeFixedFlowrateTransferStream = require("./effects/fixedFlowrate/Transfer");
const shouldBehaveLikeFixedFlowrateRemainder = require("./effects/fixedFlowrate/remainder")

const shouldBehaveLikeFixedFlowrateDeltaOf = require("./views/fixedFlowrate/FixedFlowrateDelataOf");
const shouldBehaveLikeFixedFlowrateBalanceOf = require("./views/fixedFlowrate/FixedFlowrateBalanceOf");
const shouldBehaveLikeFixedFlowrateGetStream = require("./views/fixedFlowrate/GetFixedFlowrateStream");

//Installment
const shouldBehaveLikeInstallmentStream = require("./effects/installment/CreateInstallmentStream")
const shouldBehaveLikeInstallmentWithdrawStream = require("./effects/installment/WithdrawFromInstallmentStream")
const shouldBehaveLikeInstallmentTransferStream = require("./effects/installment/Transfer");
const shouldBehaveLikeInstallmentCancelStream = require("./effects/installment/CancelInstallmentStream");
const shouldBehaveLikeInstallmentRemainder = require("./effects/installment/remainder")
const shouldBehaveLikeInstallmentFee = require("./effects/installment/fees")

const shouldBehaveLikeInstallmentGetStream = require("./views/installment/GetInstallmentStream");
const shouldBehaveLikeInstallBalanceOf = require("./views/installment/InstallmentBalanceOf");
const shouldBehaveLikeInstallDeltaOf = require("./views/installment/InstallmentDelataOf");

//InstallmentWithDP
const shouldBehaveLikeInstallmentWithDPStream = require("./effects/installmentWithDP/CreateInstallmentWithDPStream");
const shouldBehaveLikeInstallmentWithDPWithdrawStream = require("./effects/installmentWithDP/WithdrawFromInstallmentWithDPStream");
const shouldBehaveLikeInstallmentWithDPtransferStream = require("./effects/installmentWithDP/TransferWithDP");
const shouldBehaveLikeInstallmentWithDPCancelStream = require("./effects/installmentWithDP/CancelInstallmentWithDPStream");
const shouldBehaveLikeInstallmentWithDPRemainder = require("./effects/installmentWithDP/remainder");

const shouldBehaveLikeInstallmentWithDPGetStream = require("./views/installmentWithDP/GetInstallmentStreamWithDP");
const shouldBehaveLikeInstallWithDPBalanceOf = require("./views/installmentWithDP/InstallmentWithDPBalanceOf");

//sablier
const shouldBehaveLikeERC1620Stream = require('./effects/sablier/remainder')


const streamPayOfFixedFlowrate = artifacts.require("./streamPayOfFixedFlowrate.sol");
const { ZERO_ADDRESS } = devConstants;

function shouldBehaveLikeStreamPay(alice,bob,carol,eve){

    describe("view functions",function() {
        //fixedFloarate
        // describe("fixedFlowrateGetStream",function(){
        //     shouldBehaveLikeFixedFlowrateGetStream(alice);
        // })
        //
        // describe("fixedFlowrateDeltaOf", function() {
        //     shouldBehaveLikeFixedFlowrateDeltaOf(alice, bob);
        // });
        //
        // describe("fixedFlowrateBalanceOf", function() {
        //     shouldBehaveLikeFixedFlowrateBalanceOf(alice, bob, carol);
        // });

        //Installment
        // describe("installmentGetStream",function(){
        //     shouldBehaveLikeInstallmentGetStream(alice);
        // })
        //
        // describe("installmentDeltaOf", function() {
        //     shouldBehaveLikeFixedFlowrateDeltaOf(alice, bob);
        // });
        //
        // describe("installmentBalanceOf", function() {
        //     shouldBehaveLikeInstallBalanceOf(alice, bob, carol);
        // });

        //InstallmentWithDP
        // describe("installmentGetStream",function(){
        //     shouldBehaveLikeInstallmentGetStream(alice);
        // })
        //
        // describe("installmentDeltaOf", function() {
        //     shouldBehaveLikeFixedFlowrateDeltaOf(alice, bob);
        // });
        //
        // describe("installmentBalanceOf", function() {
        //     shouldBehaveLikeInstallWithDPBalanceOf(alice, bob, carol);
        // });
    })

    describe("effects & interactions functions",function() {
        //fixedFloarate
        // describe("createStream",function() {
        //     shouldBehaveLikeFixedFlowrateStream(alice,bob);
        // });
        //
        // describe("withdrawlStream",function() {
        //     shouldBehaveLikeFixedFlowrateWithdrawFromStream(alice,bob,eve);
        // });
        //
        // describe("cancelStream",function() {
        //     shouldBehaveLikeFixedFlowrateCancelStream(alice,bob,eve);
        // });
        //
        // describe("transfer",function() {
        //     shouldBehaveLikeFixedFlowrateTransferStream(alice,bob);
        // });

        // describe("remainder",function() {
        //     shouldBehaveLikeFixedFlowrateRemainder(alice,bob);
        // });
        //
        //Installment
        // describe("installmentCreateStream",function() {
        //     shouldBehaveLikeInstallmentStream(alice,bob);
        // });
        //
        // describe("installmentWithdrawlStream",function() {
        //     shouldBehaveLikeInstallmentWithdrawStream(alice,bob,eve);
        // });

        // describe("transfer",function() {
        //     shouldBehaveLikeInstallmentTransferStream(alice,bob);
        // });
        //
        // describe("InstallmentCancelStream",function() {
        //     shouldBehaveLikeInstallmentCancelStream(alice,bob,eve);
        // });

        // describe("installmentRemainder",function(){
        //     shouldBehaveLikeInstallmentRemainder(alice,bob);
        // })

        describe("installmentFee",function(){
            shouldBehaveLikeInstallmentFee(alice,bob);
        })

        //InstallmentWithDP
        // describe("installmentWithDPCreateStream",function() {
        //     shouldBehaveLikeInstallmentWithDPStream(alice,bob);
        // });
        //
        // describe("installmentWithDPWithdrawlStream",function() {
        //     shouldBehaveLikeInstallmentWithDPWithdrawStream(alice,bob,eve);
        // });
        //
        // describe("transfer",function() {
        //     shouldBehaveLikeInstallmentWithDPtransferStream(alice,bob);
        // });

        // describe("InstallmentWithDPCancelStream",function() {
        //     shouldBehaveLikeInstallmentWithDPCancelStream(alice,bob,eve);
        // });

        // describe("installmentWithDPRemainder",function(){
        //     shouldBehaveLikeInstallmentWithDPRemainder(alice,bob);
        // })

        //sablier
        // describe("installmentGetStream",function(){
        //     shouldBehaveLikeERC1620Stream(alice,bob);
        // })
    });
}

module.exports = shouldBehaveLikeStreamPay;

