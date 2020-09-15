pragma solidity ^0.5.16;

import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "./tools-contracts/OwnableWithoutRenounce.sol";
import "./tools-contracts/Exponential.sol";
import "./tools-contracts/PausableWithoutRenounce.sol";
import "./interface/streamPayOfInstallmentWithDPInterface.sol";
import './Types.sol';

/**
 * @title 流付/StreamPay's money streaming of installmentStreamWithDownPayment
 * @author StreamPay
 */

contract streamPayOfInstallmentWithDP is OwnableWithoutRenounce, PausableWithoutRenounce, Exponential, ReentrancyGuard, streamPayOfInstallmentWithDPInterface{
    /*** Storage Properties ***/
    
    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;
    
    /**
     * @notice symbol of difference content.
     */
    uint256 symbol;

    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 =>Types.InstallmentWithDPStream) private installmentWithDPStreams;

    /**
     * @notice The percentage fee charged by the contract on the accrued interest, 1 is 1 / 1e18
     */
    Exp public expFeeOfProtocol;

    /**
     * @notice In Exp terms, 1e14 is 0.0001, or 0.01%
     */
    uint256 constant oneOfTenThousand = 1e14;

    /**
     * @notice In Exp terms, 1e16 is 0.01, or 1%
     */
    uint256 constant onePercent = 1e16;
    
    /**
     * @notice The amount of interest has been accrued per token address.
     */
    mapping(address => uint256) private earnings;
    
    /*** Modifiers ***/
    
    /**
     * Throws if the caller not sender or recipient of the stream.
     */
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == installmentWithDPStreams[streamId].sender || msg.sender == installmentWithDPStreams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }
        
    /**
     * Throws if the streamId not exist.
     */
    modifier streamExists(uint256 streamId) {
        require(installmentWithDPStreams[streamId].isEntity, "stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor() public {
        OwnableWithoutRenounce.initialize(msg.sender);
        PausableWithoutRenounce.initialize(msg.sender);
        nextStreamId = 1;
        symbol = 4000000;
    }
    
    /*** Owner Functions ***/

    struct UpdateFeePerLocalVars {
        MathError mathErr;
        uint256 feePerMantissa;
    }

    /**
     * @notice update feeOfProtocolPer.
     * @dev Throws if the caller is not owner.
     * @param feePer The new feeOfProtocolPer.
     */
    function updateFeesOfProtocolPer(uint256 feePer) external onlyOwner{
        require(feePer <= 10000, "feePer higher than 100%");
        UpdateFeePerLocalVars memory vars;

        (vars.mathErr, vars.feePerMantissa) = mulUInt(feePer, oneOfTenThousand);
        assert(vars.mathErr == MathError.NO_ERROR);

        expFeeOfProtocol = Exp({ mantissa:vars.feePerMantissa });
        emit UpdateFee(feePer);    
    }
    
    /**
     * @notice Returns the amount of interest that has been accrued for the given token address.
     * @param tokenAddress The address of the token to get the earnings for.
     * @return The amount of interest as uint256.
     */
    function getEarnings(address tokenAddress) external view returns (uint256) {
        return earnings[tokenAddress];
    }

    struct TakeEarningsLocalVars {
        MathError mathErr;
    }
    
    /**
     * @notice Withdraws the earnings for the given token address.
     * @dev Throws if `amount` exceeds the available balance.
     * @param tokenAddress The address of the token to withdraw earnings for.
     * @param amount The amount of tokens to withdraw.
     */
    function takeEarnings(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "amount is zero");
        require(earnings[tokenAddress] >= amount, "amount exceeds the available balance");

        InterestOfLocalVars memory interestVars;
        
        (interestVars.mathErr, earnings[tokenAddress]) = subUInt(earnings[tokenAddress], amount);
        assert(interestVars.mathErr == MathError.NO_ERROR);

        emit TakeEarnings(tokenAddress, amount);
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "token transfer failure");
    }
    
    struct InterestOfLocalVars{
        MathError mathErr;
        Exp feesOfRecipient;
        Exp feesOfProtocol;
    }
    
    /**
     * @notice calculation the fee charged of recipient,include the fee charged of feesOfProtocol.
     * @dev Throw if the feesOfRecipient calculation has a math error.
     * @param deposit The amount of installmentStreamWithDP.
     * downPaymentAmount The downPayment of stream
     * feesOfRecipientPer The percentage fee charged by the recipient on the accrued interest, 1 is 1 / 1e18
     * duration The time interval of stopTime and starttime.
     * numberOfInstallments The numbers of installments.
     * @return The fee charged Of Recipient.
     */
    function calculationFees(uint256 deposit,uint256 downPaymentAmount,uint256 feesOfRecipientPer,uint256 duration,uint256 numberOfInstallments)
        internal
        pure
        returns(uint256)
    {
        InterestOfLocalVars memory vars;
        vars.feesOfRecipient = Exp({mantissa:feesOfRecipientPer});

        uint256 installmentAmount;
        (vars.mathErr,installmentAmount) = subUInt(deposit,downPaymentAmount);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr,vars.feesOfRecipient) = mulScalar(vars.feesOfRecipient,installmentAmount);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr,vars.feesOfRecipient) = mulScalar(vars.feesOfRecipient,duration);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr,vars.feesOfRecipient) = mulScalar(vars.feesOfRecipient,numberOfInstallments);
        assert(vars.mathErr == MathError.NO_ERROR);

        uint256 fees = truncate(vars.feesOfRecipient);

        uint256 installmentAmountWithFees;
        (vars.mathErr,installmentAmountWithFees) = addUInt(fees,installmentAmount);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        return installmentAmountWithFees;
    }
    
    /**
     * @notice calculation the fee charged of protocol.
     * @dev Throw if the feesOfProtocol calculation has a math error.
     * @param amount The amount is the recipient withdraw or cancel stream's.
     * duration The time interval of stopTime and startTime.
     * numberOfInstallments The numbers of installments.
     * @return The fee charged Of Protocol.
     */
    function calculationFeesOfProtocol(uint256 amount)
        public
        view
        returns(uint256)
    {
        InterestOfLocalVars memory vars;

        (vars.mathErr,vars.feesOfProtocol) = mulScalar(expFeeOfProtocol,amount);
        assert(vars.mathErr == MathError.NO_ERROR);

        return (truncate(vars.feesOfProtocol));
    }

    struct DownPaymentLocalVars{
        MathError mathErr;
        Exp downPaymentAmount;
    }

    /**
     * @notice calculation the downPayment of stream.
     * @dev Throw if the downPaymentRatio higher than 100.
     * Throw if the downPaymentRatio calculation has a math error.
     * Throw if the downPaymentAmount calculation has a math error.
     * @param deposit The amount of installmentStreamWithDP.
     * downPaymentRatio The down payment ratio of installmentStreamWithDP.
     * @return The down payment amount.
     */
    function calculationDownPaymentAmount(uint256 deposit,uint256 downPaymentRatio)
        public
        pure
        returns(uint256)
    {
        require(downPaymentRatio <= 100, "fee percentage higher than 100%");
        DownPaymentLocalVars memory vars;

        (vars.mathErr, downPaymentRatio) = mulUInt(downPaymentRatio, onePercent);
        assert(vars.mathErr == MathError.NO_ERROR);

        Exp memory downPaymentRatios = Exp({mantissa:downPaymentRatio});

        (vars.mathErr,vars.downPaymentAmount) = mulScalar(downPaymentRatios,deposit);
        assert(vars.mathErr == MathError.NO_ERROR);

        return (truncate(vars.downPaymentAmount));
    }
    
    /**
     * @notice Returns the installmentStreamWithDP with all its properties.
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     * @return The installmentStreamWithDP object.
     */
    function getInstallmentWithDPStream(uint256 streamId) external view streamExists(streamId) returns(
        address sender,
        address recipient,
        uint256 deposit,
        uint256 downPaymentAmount,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 numberOfInstallments,
        uint256 feesOfRecipientPer,
        uint256 haveBeenNumberOfInstallment,
        uint256 haveBeenPaidAmount,
        uint256 withdrawalAmount)
    {
        sender = installmentWithDPStreams[streamId].sender;
        recipient = installmentWithDPStreams[streamId].recipient;
        deposit = installmentWithDPStreams[streamId].deposit;
        downPaymentAmount = installmentWithDPStreams[streamId].downPaymentAmount;
        tokenAddress = installmentWithDPStreams[streamId].tokenAddress;
        startTime = installmentWithDPStreams[streamId].startTime;
        stopTime = installmentWithDPStreams[streamId].stopTime;
        numberOfInstallments = installmentWithDPStreams[streamId].numberOfInstallments;
        feesOfRecipientPer = installmentWithDPStreams[streamId].feesOfRecipientPer;  
        haveBeenNumberOfInstallment = installmentWithDPStreams[streamId].haveBeenNumberOfInstallment;
        haveBeenPaidAmount = installmentWithDPStreams[streamId].haveBeenPaidAmount;
        withdrawalAmount = installmentWithDPStreams[streamId].withdrawalAmount;
    }

    function getInstallmentWithDPStreamCal(uint256 streamId) external view streamExists(streamId) returns(
        uint256 installmentAmountWithFees,
        uint256 oneOfInstallmentAmount,
        uint256 oneOfInstallmentTime,
        uint256 ratePerSecond)
    {
        installmentAmountWithFees = installmentWithDPStreams[streamId].installmentAmountWithFees;
        oneOfInstallmentAmount = installmentWithDPStreams[streamId].oneOfInstallmentAmount;
        oneOfInstallmentTime = installmentWithDPStreams[streamId].oneOfInstallmentTime;
        ratePerSecond = installmentWithDPStreams[streamId].ratePerSecond;
    }
    
    struct CreateInstallmentWithDPStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 downPaymentAmount;
        uint256 oneOfInstallmentAmount;
        uint256 oneOfInstallmentTime;
        uint256 ratePerSecond;
        uint256 firstPayAmount;
        uint256 haveBeenNumberOfInstallment;
        uint256 haveBeenPaidAmount;
    }
    
    /**
     * @notice Create a installmentStreamWithDP.
     * @dev Throws if paused.
     * Throw if the recipient is 0,the contract itself or the msg.sender.
     * Throw if the deposit is 0.
     * Throws if the start time is before `block.timestamp`.
     * Throws if the stop time is before the start time.
     * Throw if startTime is smaller than block.timestamp.
     * Throw if maxAmount is smaller than ratePerSecond.
     * Throw if deposit is smaller than numberOfInstallments.
     * Throw if numberOfInstallments is less than 2.
     * Throw if the streamId calculation has a math error.
     * Throw if the duration calculation has a math error.
     * Throw if the deposit is smaller than duration.
     * Throws if the deposit is not a multiple of the duration.
     * Throw if the oneOfInstallmentTime calculation has a math error.
     * Throw if the oneOfInstallmentAmount calculation has a math error.
     * Throw if the ratePerSecond calculation has a math error.
     * Throw if the nextStreamId calculation has a math error.
     * Throw if the haveBeenNumberOfInstallment calculation has a math error.
     * @param recipient The address of receipt stream money.
     * deposit The amount of installment stream.
     * tokenAddress The ERC20 token.
     * startTime The time of stream start.
     * stopTime The time of stream stop.
     * numberOfInstallments The number of installments.
     * downPaymentRatio The down payment ratio of installmentStreamWithDP.
     * feesOfRecipientPer The fee charged by the recipient on the accrued interest, 1 is 1 / 1e18.
     * @return The id of the stream.
     */

    function createInstallmentWithDPStream(address recipient,uint256 deposit,address tokenAddress,uint256 startTime,
    uint256 stopTime,uint256 numberOfInstallments,uint256 downPaymentRatio,uint256 feesOfRecipientPer)
        public
        whenNotPaused
        returns(uint256)
    {
        require(recipient != address(0x00),"stream to the zero address");
        require(recipient != address(this),"stream to the contract");
        require(recipient != msg.sender,"stream to the caller");
        require(deposit > 0, "deposit is zero");
        require(startTime >= block.timestamp, "start time before block.timestamp");
        require(stopTime > startTime, "stop time before the start time");
        require(deposit > numberOfInstallments,"numberOfInstallments bigger than deposit");
        require(numberOfInstallments >=2,"numberOfInstallments is small 2");
        
        CreateInstallmentWithDPStreamLocalVars memory vars;
        
        (vars.mathErr,vars.duration) = subUInt(stopTime,startTime);
        assert(vars.mathErr == MathError.NO_ERROR);
        require(deposit >= vars.duration,"deposit smaller than time delta");
        require(vars.duration >= numberOfInstallments,"duration < numberOfInstallmentStream");
        require(vars.duration % numberOfInstallments == 0,"duration % numberOfInstallments have remainder");
        
        vars.downPaymentAmount = calculationDownPaymentAmount(deposit,downPaymentRatio);
        
        uint256 installmentAmountWithFees = calculationFees(deposit,vars.downPaymentAmount,feesOfRecipientPer,vars.duration,numberOfInstallments);
        
        (vars.mathErr,vars.oneOfInstallmentAmount) = divUInt(installmentAmountWithFees,numberOfInstallments);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr,vars.oneOfInstallmentTime) = divUInt(vars.duration,numberOfInstallments);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr,vars.ratePerSecond) = divUInt(vars.oneOfInstallmentAmount,vars.oneOfInstallmentTime);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr,vars.firstPayAmount) = addUInt(vars.oneOfInstallmentAmount,vars.downPaymentAmount);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        uint256 streamId;
        (vars.mathErr,streamId) = addUInt(symbol,nextStreamId);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.haveBeenNumberOfInstallment) = addUInt(vars.haveBeenNumberOfInstallment, uint256(1));
        assert(vars.mathErr == MathError.NO_ERROR);

        vars.haveBeenPaidAmount = vars.firstPayAmount;
        
        installmentWithDPStreams[streamId] = Types.InstallmentWithDPStream({
            deposit:deposit,
            downPaymentAmount:vars.downPaymentAmount,
            installmentAmountWithFees:installmentAmountWithFees,
            oneOfInstallmentAmount:vars.oneOfInstallmentAmount,
            oneOfInstallmentTime:vars.oneOfInstallmentTime,
            downPaymentRatio:downPaymentRatio,
            startTime:startTime,
            stopTime:stopTime,
            recipient:recipient,
            sender:msg.sender,
            numberOfInstallments:numberOfInstallments,
            ratePerSecond:vars.ratePerSecond,
            feesOfRecipientPer:feesOfRecipientPer,
            haveBeenNumberOfInstallment:vars.haveBeenNumberOfInstallment,
            haveBeenPaidAmount:vars.firstPayAmount,
            withdrawalAmount:0,
            tokenAddress:tokenAddress,
            isEntity:true
        });
        
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        assert(vars.mathErr == MathError.NO_ERROR);

        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), vars.firstPayAmount), "token transfer failure");
        emit CreateInstallmentWithDPStream(streamId,msg.sender,recipient,deposit,tokenAddress,startTime,stopTime,numberOfInstallments,
        downPaymentRatio,feesOfRecipientPer,vars.haveBeenPaidAmount,installmentAmountWithFees);

        return streamId;
    } 

    /**
     * @notice return the duration of the stream
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     * @return The duration of the stream's startTime to now.
     */
    function installmentDeltaOf(uint256 streamId) public view streamExists(streamId) returns(uint256){
        Types.InstallmentWithDPStream memory installmentWithDPStream =  installmentWithDPStreams[streamId];
        
        if(block.timestamp <= installmentWithDPStream.startTime) return 0;
        if(block.timestamp < installmentWithDPStream.stopTime) return block.timestamp - installmentWithDPStream.startTime;
        return installmentWithDPStream.stopTime - installmentWithDPStream.startTime;
    }
    
    struct InstallmentWithDPBalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 senderBalance;
        uint256 handleBalance;
        uint256 numberOfTime;
        uint256 remainderOfInstallmentAmountWithFees;
        uint256 remainderOfOneInstallment;
    }

    /**
     * @notice return the accountBalance of sender or recipient.
     * @dev Throws if the streamId does not exist.
     * Throw if the handleBalance calculation has a math error.
     * Throw if the recipientBalance calculation has a math error.
     * Throw if the senderBalance calculation has a math error.
     * @param streamId The id of the stream to query.
     * who The account of the sender or recipient.
     * @return The account balance of sender or recipient.
     */
    function installmentWithDPBalanceOf(uint256 streamId, address who)
        public
        view
        streamExists(streamId)
        returns (uint256 balance)
    {
        Types.InstallmentWithDPStream memory installmentWithDPStream =  installmentWithDPStreams[streamId];
        InstallmentWithDPBalanceOfLocalVars memory vars;
        
        uint256 delta = installmentDeltaOf(streamId);
        
        (vars.mathErr, vars.handleBalance) = mulUInt(delta,installmentWithDPStream.ratePerSecond);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        if(block.timestamp >= installmentWithDPStream.startTime){
            (vars.mathErr, vars.handleBalance) = addUInt(vars.handleBalance,installmentWithDPStream.downPaymentAmount);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        if (delta >= installmentWithDPStream.oneOfInstallmentTime){
            (vars.mathErr, vars.numberOfTime) = divUInt(delta,installmentWithDPStream.oneOfInstallmentTime);
            assert(vars.mathErr == MathError.NO_ERROR);

            if(vars.numberOfTime > installmentWithDPStream.haveBeenNumberOfInstallment){
                vars.numberOfTime = installmentWithDPStream.haveBeenNumberOfInstallment;
            }

            (vars.mathErr,vars.remainderOfOneInstallment) = modUInt(installmentWithDPStream.oneOfInstallmentAmount,installmentWithDPStream.oneOfInstallmentTime);
            assert(vars.mathErr == MathError.NO_ERROR);

            (vars.mathErr,vars.remainderOfOneInstallment) = mulUInt(vars.numberOfTime,vars.remainderOfOneInstallment);
            assert(vars.mathErr == MathError.NO_ERROR);

            (vars.mathErr,vars.handleBalance) = addUInt(vars.handleBalance,vars.remainderOfOneInstallment);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        if (block.timestamp >= installmentWithDPStream.stopTime){
            (vars.mathErr,vars.remainderOfInstallmentAmountWithFees) = modUInt(installmentWithDPStream.installmentAmountWithFees,installmentWithDPStream.numberOfInstallments);
            assert(vars.mathErr == MathError.NO_ERROR);
            
            (vars.mathErr,vars.handleBalance) = addUInt(vars.handleBalance,vars.remainderOfInstallmentAmountWithFees);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        if (vars.handleBalance >= installmentWithDPStream.haveBeenPaidAmount){
            vars.handleBalance = installmentWithDPStream.haveBeenPaidAmount;
        }
        
        (vars.mathErr,vars.recipientBalance) = subUInt(vars.handleBalance,installmentWithDPStream.withdrawalAmount);
        assert(vars.mathErr == MathError.NO_ERROR);

        if (who == installmentWithDPStream.recipient) return vars.recipientBalance;
        if (who == installmentWithDPStream.sender){
            (vars.mathErr,vars.senderBalance) = subUInt(installmentWithDPStream.haveBeenPaidAmount,vars.handleBalance);
            assert(vars.mathErr == MathError.NO_ERROR);

            return vars.senderBalance;
        }
        return 0;
    
    }
    
    struct TransferWithDPLocalVars {
        MathError mathErr;
        uint256 transferAmount;
        uint256 remainderOfInstallmentAmountWithFees;
        uint256 nextStopInstallmentTime;
        uint256 startTimeOfInstallment;
    }

    /**
     * @notice transfer installment amount for continue stream.
     * @dev Throws if paused.
     * Throws if the streamId does not exist.
     * Throws if the block.timestamp rather than nextStopInstallmentTime.
     * Throws if the block.timestamp not arrive startOfInstallmentTime.
     * Throw if the remainderOfInstallmentAmountWithFees calculation has a math error.
     * Throw if the transferAmount calculation has a math error.
     * Throw if the haveBeenNumberOfInstallment calculation has a math error.
     * Throw if the haveBeenPaidAmount calculation has a math error.
     * @param streamId The id of the stream to query.
     * @return The bool of transfer.
     */
    function transferWithDP(uint256 streamId)
        public
        whenNotPaused
        streamExists(streamId)
        returns(bool)
    {
        TransferWithDPLocalVars memory vars;
        Types.InstallmentWithDPStream memory installmentWithDPStream =  installmentWithDPStreams[streamId];

        require(installmentWithDPStream.haveBeenNumberOfInstallment < installmentWithDPStream.numberOfInstallments,"installment is finish");
        
        (vars.mathErr,vars.nextStopInstallmentTime) = mulThenAddUint(installmentWithDPStream.oneOfInstallmentTime,installmentWithDPStream.haveBeenNumberOfInstallment,installmentWithDPStream.startTime);
        assert(vars.mathErr == MathError.NO_ERROR);        
        
        require(block.timestamp < vars.nextStopInstallmentTime,"installmentStream is finish,rather than StopInstallmentTime");

        if (installmentWithDPStream.haveBeenNumberOfInstallment < installmentWithDPStream.numberOfInstallments - 1){
            vars.transferAmount = installmentWithDPStream.oneOfInstallmentAmount;
        }else if(installmentWithDPStream.haveBeenNumberOfInstallment == installmentWithDPStream.numberOfInstallments - 1){
            (vars.mathErr,vars.remainderOfInstallmentAmountWithFees) = modUInt(installmentWithDPStream.installmentAmountWithFees,installmentWithDPStream.numberOfInstallments);
            assert(vars.mathErr == MathError.NO_ERROR);
            
            (vars.mathErr,vars.transferAmount) = addUInt(installmentWithDPStream.oneOfInstallmentAmount,vars.remainderOfInstallmentAmountWithFees);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        (vars.mathErr, installmentWithDPStreams[streamId].haveBeenNumberOfInstallment) = addUInt(installmentWithDPStream.haveBeenNumberOfInstallment,uint256(1));
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr, installmentWithDPStreams[streamId].haveBeenPaidAmount) = addUInt(installmentWithDPStream.haveBeenPaidAmount,vars.transferAmount);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        require(IERC20(installmentWithDPStream.tokenAddress).transferFrom(msg.sender, address(this), vars.transferAmount), "token transfer failure");
        emit TransferWithDP(streamId,vars.transferAmount,installmentWithDPStreams[streamId].haveBeenPaidAmount,installmentWithDPStreams[streamId].haveBeenNumberOfInstallment);

        return true;
    }

    /**
     * @notice withdraw from stream.
     * @dev Throws if paused.
     * Throws if the streamId does not exist.
     * Throw if caller is not recipient.
     * Throw if the amount = 0.
     * Throw if the amount is bigger than balance;
     * @param streamId The id of the stream to query.
     * amount The amount of withdraw from stream.
     * @return The bool of transfer amount.
     */
    function withdrawInstallmentWithDPStream(uint256 streamId,uint256 amount)
        external
        whenNotPaused
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns(bool)
    {
        require(amount > 0,"amount is zero");
        Types.InstallmentWithDPStream memory installmentWithDPStream =  installmentWithDPStreams[streamId];
        
        uint256 balance = installmentWithDPBalanceOf(streamId,installmentWithDPStream.recipient);
        require(balance >= amount,"amount exceeds the available balance");
        
        withdrawInstallmentWithDPStreamInterval(streamId,amount);
        return true;
    }
    
    struct WithdrawLocalVars {
        MathError mathErr;
        uint256 actualAmount;
        uint256 depositWithFees;
    }

    /**
     * @notice transfer withdraw amount to recipient.
     * @dev Throws if the streamId does not exist.
     * Throw if the withdrawalAmount calculation has a math error.
     * @param streamId The id of the stream to query.
     * amount The amount of withdraw from stream.
     */
    function withdrawInstallmentWithDPStreamInterval(uint256 streamId,uint256 amount) internal{
        Types.InstallmentWithDPStream memory installmentWithDPStream =  installmentWithDPStreams[streamId];
        WithdrawLocalVars memory vars;

        (vars.mathErr,installmentWithDPStreams[streamId].withdrawalAmount) = addUInt(installmentWithDPStream.withdrawalAmount,amount);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        uint256 feesOfProtocol = calculationFeesOfProtocol(amount);
        
        (vars.mathErr, earnings[installmentWithDPStream.tokenAddress]) = addUInt(earnings[installmentWithDPStream.tokenAddress], feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr, vars.actualAmount) = subUInt(amount, feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);

        require(IERC20(installmentWithDPStream.tokenAddress).transfer(installmentWithDPStream.recipient, vars.actualAmount), "token transfer failure");
        emit WithdrawFromInstallmentWithDPStream(streamId,installmentWithDPStream.recipient,amount,vars.actualAmount,feesOfProtocol);
    }    

    /**
     * @notice Finish the stream.
     * @dev Throws if the streamId does not exist.
     * Throw if caller is not sender or recipient.
     * @param streamId The id of the stream to query.
     * @return The bool of transfer amount.
     */
    function cancelInstallmentWithDPStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns(bool)
    {
        cancelInstallmentWithDPStreamInternal(streamId);
        return true;
    }
    
    struct CancelLocalVars {
        MathError mathErr;
        uint256 actualRecipientBalance;
    }

    /**
     * @notice transfer amount to recipient and sender of finish stream account.
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     */
    function cancelInstallmentWithDPStreamInternal(uint256 streamId) internal{
        Types.InstallmentWithDPStream memory installmentWithDPStream =  installmentWithDPStreams[streamId];
        CancelLocalVars memory vars;

        uint256 senderBalance = installmentWithDPBalanceOf(streamId,installmentWithDPStream.sender);
        uint256 recipientBalance = installmentWithDPBalanceOf(streamId,installmentWithDPStream.recipient);
        uint256 feesOfProtocol = calculationFeesOfProtocol(recipientBalance);
        
        (vars.mathErr, earnings[installmentWithDPStream.tokenAddress]) = addUInt(earnings[installmentWithDPStream.tokenAddress], feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.actualRecipientBalance) = subUInt(recipientBalance, feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        delete installmentWithDPStreams[streamId];
        
        IERC20 token = IERC20(installmentWithDPStream.tokenAddress);
        if (recipientBalance > 0)
            require(token.transfer(installmentWithDPStream.recipient, vars.actualRecipientBalance), "recipient token transfer failure");
        if (senderBalance > 0) require(token.transfer(installmentWithDPStream.sender,senderBalance));
        
        emit CancelInstallmentWithDPStream(streamId,installmentWithDPStream.sender,installmentWithDPStream.recipient,senderBalance,recipientBalance,feesOfProtocol,block.timestamp);
    }
}