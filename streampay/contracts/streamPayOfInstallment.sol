pragma solidity ^0.5.16;

import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "./tools-contracts/OwnableWithoutRenounce.sol";
import "./tools-contracts/Exponential.sol";
import "./tools-contracts/PausableWithoutRenounce.sol";
import "./interface/streamPayOfInstallmentInterface.sol";
import './Types.sol';

/**
 * @title 流付/StreamPay's money streaming of installmentStream.
 * @author StreamPay
 */
 
contract streamPayOfInstallment is OwnableWithoutRenounce, PausableWithoutRenounce, Exponential, ReentrancyGuard, streamPayOfInstallmentInterface{
    /*** Storage Properties ***/
    
    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;
    
    /**
     * @notice in order to distinguish difference part of StreamPay through symbol.
     */
    uint256 symbol;    
    
    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 =>Types.InstallmentStream) private installmentStreams;

    /**
     * @notice In Exp terms, 1e14 is 0.0001, or 0.01%
     */
    uint256 constant oneOfTenThousand = 1e14;
    
    /**
     * @notice The fee charged by the contract on the accrued interest, 1 is 1 / 1e18
     */
    Exp public expFeeOfProtocol;
    
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
            msg.sender == installmentStreams[streamId].sender || msg.sender == installmentStreams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }
        
    /**
     * Throws if the streamId not exist.
     */
    modifier streamExists(uint256 streamId) {
        require(installmentStreams[streamId].isEntity, "stream does not exist");
        _;
    }
    
    /*** Contract Logic Starts Here */

    constructor() public {
        OwnableWithoutRenounce.initialize(msg.sender);
        PausableWithoutRenounce.initialize(msg.sender);
        nextStreamId = 1;
        symbol = 3000000;
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

        TakeEarningsLocalVars memory vars;
        
        (vars.mathErr, earnings[tokenAddress]) = subUInt(earnings[tokenAddress], amount);
        assert(vars.mathErr == MathError.NO_ERROR);

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
     * @param deposit The installment amount of the stream.
     * feesOfRecipientPer The fee charged by the recipient on the accrued interest, 1 is 1 / 1e18
     * duration The time interval of stopTime and starttime.
     * numberOfInstallments The numbers of installments.
     * @return The fee charged Of Recipient add deposit.
     */
    function calculationFees(uint256 deposit,uint256 feesOfRecipientPer,uint256 duration,uint256 numberOfInstallments)
        internal
        pure
        returns(uint256)
    {
        InterestOfLocalVars memory vars;
        vars.feesOfRecipient = Exp({mantissa:feesOfRecipientPer});
        
        (vars.mathErr,vars.feesOfRecipient) = mulScalar(vars.feesOfRecipient,deposit);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr,vars.feesOfRecipient) = mulScalar(vars.feesOfRecipient,duration);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr,vars.feesOfRecipient) = mulScalar(vars.feesOfRecipient,numberOfInstallments);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        uint256 fees = truncate(vars.feesOfRecipient);

        uint256 installmentAmountWithFees;
        (vars.mathErr,installmentAmountWithFees) = addUInt(fees,deposit);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        return installmentAmountWithFees;
    }
    
    /**
     * @notice calculation the fee charged of protocol.
     * @dev Throw if the feesOfProtocol calculation has a math error.
     * @param amount The amount is the recipient withdraw or cancel stream's.
     * duration The time interval of stopTime and starttime.
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
    
    /**
     * @notice Returns the installmentStream with all its properties.
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     * @return The installmentStream object.
     */
    function getInstallmentStream(uint256 streamId) external view streamExists(streamId) returns(
        address sender,
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 numberOfInstallments,
        uint256 feesOfRecipientPer,
        uint256 ratePerSecond,
        uint256 haveBeenNumberOfInstallment,
        uint256 withdrawalAmount)
    {
        sender = installmentStreams[streamId].sender;
        recipient = installmentStreams[streamId].recipient;
        deposit = installmentStreams[streamId].deposit;
        tokenAddress = installmentStreams[streamId].tokenAddress;
        startTime = installmentStreams[streamId].startTime;
        stopTime = installmentStreams[streamId].stopTime;
        numberOfInstallments = installmentStreams[streamId].numberOfInstallments;
        feesOfRecipientPer = installmentStreams[streamId].feesOfRecipientPer;  
        ratePerSecond = installmentStreams[streamId].ratePerSecond;
        haveBeenNumberOfInstallment = installmentStreams[streamId].haveBeenNumberOfInstallment;
        withdrawalAmount = installmentStreams[streamId].withdrawalAmount;
    }    
    
    struct CreateInstallmentStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 oneOfInstallmentAmount;
        uint256 oneOfInstallmentTime;
        uint256 ratePerSecond;
        uint256 haveBeenNumberOfInstallment;
        uint256 haveBeenPaidAmount;
    }
    
    /**
     * @notice Create a installmentStream.
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
     * Throw if the installmentAmountWithFees calculation has a math error.
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
     * feesOfRecipientPer The fee charged by the recipient on the accrued interest, 1 is 1 / 1e18.
     * @return The id of the stream.
     */
    function createInstallmentStream(address recipient,uint256 deposit,address tokenAddress,uint256 startTime,
    uint256 stopTime,uint256 numberOfInstallments,uint256 feesOfRecipientPer)
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
        require(deposit >= numberOfInstallments,"numberOfInstallments bigger than deposit");
        require(numberOfInstallments >=2,"numberOfInstallments is small 2");
        
        CreateInstallmentStreamLocalVars memory vars;
        
        (vars.mathErr,vars.duration) = subUInt(stopTime,startTime);
        assert(vars.mathErr == MathError.NO_ERROR);

        require(deposit >= vars.duration,"deposit smaller than time delta");
        require(vars.duration >= numberOfInstallments,"duration < numberOfInstallmentStream");
        require(vars.duration % numberOfInstallments == 0,"duration % numberOfInstallments have remainder");
        
        uint256 installmentAmountWithFees = calculationFees(deposit,feesOfRecipientPer,vars.duration,numberOfInstallments);
    
        (vars.mathErr,vars.oneOfInstallmentAmount) = divUInt(installmentAmountWithFees,numberOfInstallments);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr,vars.oneOfInstallmentTime) = divUInt(vars.duration,numberOfInstallments);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr,vars.ratePerSecond) = divUInt(vars.oneOfInstallmentAmount,vars.oneOfInstallmentTime);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        uint256 streamId;
        (vars.mathErr,streamId) = addUInt(symbol,nextStreamId);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.haveBeenNumberOfInstallment) = addUInt(vars.haveBeenNumberOfInstallment, uint256(1));
        assert(vars.mathErr == MathError.NO_ERROR);

        vars.haveBeenPaidAmount = vars.oneOfInstallmentAmount;

        installmentStreams[streamId] = Types.InstallmentStream({
            deposit:deposit,
            installmentAmountWithFees:installmentAmountWithFees,
            oneOfInstallmentAmount:vars.oneOfInstallmentAmount,
            oneOfInstallmentTime:vars.oneOfInstallmentTime,
            startTime:startTime,
            stopTime:stopTime,
            recipient:recipient,
            sender:msg.sender,
            numberOfInstallments:numberOfInstallments,
            ratePerSecond:vars.ratePerSecond,
            feesOfRecipientPer:feesOfRecipientPer,
            haveBeenNumberOfInstallment:vars.haveBeenNumberOfInstallment,
            haveBeenPaidAmount:vars.haveBeenPaidAmount,
            withdrawalAmount:0,
            tokenAddress:tokenAddress,
            isEntity:true
        });
        
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        assert(vars.mathErr == MathError.NO_ERROR);

        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), vars.oneOfInstallmentAmount), "token transfer failure");
        
        emit CreateInstallmentStream(streamId,msg.sender,recipient,deposit,tokenAddress,startTime,stopTime,numberOfInstallments,feesOfRecipientPer);
        return streamId;
    } 

    /**
     * @notice return the duration of the stream
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     * @return The duration of the stream's startTime to now.
     */
    function installmentDeltaOf(uint256 streamId)
        public
        view
        streamExists(streamId)
        returns(uint256)
    {
        Types.InstallmentStream memory installmentStream =  installmentStreams[streamId];
        
        if(block.timestamp <= installmentStream.startTime) return 0;
        if(block.timestamp < installmentStream.stopTime) return block.timestamp - installmentStream.startTime;
        return installmentStream.stopTime - installmentStream.startTime;
    }
    
    struct InstallmentBalanceOfLocalVars {
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
    function installmentBalanceOf(uint256 streamId, address who)
        public
        streamExists(streamId)
        returns (uint256 balance)
    {
        Types.InstallmentStream memory installmentStream = installmentStreams[streamId];
        InstallmentBalanceOfLocalVars memory vars;
        
        uint256 delta = installmentDeltaOf(streamId);
        
        (vars.mathErr, vars.handleBalance) = mulUInt(delta,installmentStream.ratePerSecond);
        assert(vars.mathErr == MathError.NO_ERROR);

        if (delta >= installmentStream.oneOfInstallmentTime){
            (vars.mathErr, vars.numberOfTime) = divUInt(delta,installmentStream.oneOfInstallmentTime);
            assert(vars.mathErr == MathError.NO_ERROR);

            (vars.mathErr,vars.remainderOfOneInstallment) = modUInt(installmentStream.oneOfInstallmentAmount,installmentStream.oneOfInstallmentTime);
            assert(vars.mathErr == MathError.NO_ERROR);

            (vars.mathErr,vars.remainderOfOneInstallment) = mulUInt(vars.numberOfTime,vars.remainderOfOneInstallment);
            assert(vars.mathErr == MathError.NO_ERROR);

            (vars.mathErr,vars.handleBalance) = addUInt(vars.handleBalance,vars.remainderOfOneInstallment);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        if (block.timestamp >= installmentStream.stopTime){
            (vars.mathErr,vars.remainderOfInstallmentAmountWithFees) = modUInt(installmentStream.installmentAmountWithFees,installmentStream.numberOfInstallments);
            assert(vars.mathErr == MathError.NO_ERROR);
            
            (vars.mathErr,vars.handleBalance) = addUInt(vars.handleBalance,vars.remainderOfInstallmentAmountWithFees);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        if (vars.handleBalance >= installmentStream.haveBeenPaidAmount){
            vars.handleBalance = installmentStream.haveBeenPaidAmount;
        }
        
        (vars.mathErr,vars.recipientBalance) = subUInt(vars.handleBalance,installmentStream.withdrawalAmount);
        assert(vars.mathErr == MathError.NO_ERROR);

        if (who == installmentStream.recipient) return vars.recipientBalance;
        if (who == installmentStream.sender){
            (vars.mathErr,vars.senderBalance) = subUInt(installmentStream.haveBeenPaidAmount,vars.handleBalance);
            assert(vars.mathErr == MathError.NO_ERROR);

            return vars.senderBalance;
        }
        return 0;
    
    }
    
    struct TransferLocalVars {
        MathError mathErr;
        uint256 transferAmount;
        uint256 remainderOfInstallmentAmountWithFees;
        uint256 nextStopInstallmentTime;
        uint256 startOfInstallmentTime;
    }

    /**
     * @notice transfer installment amount for continue stream.
     * @dev Throws if paused.
     * Throws if the streamId does not exist.
     * Throws if the block.timestamp rather than nextStopInstallmentTime.
     * Throw if the remainderOfInstallmentAmountWithFees calculation has a math error.
     * Throw if the transferAmount calculation has a math error.
     * Throw if the haveBeenNumberOfInstallment calculation has a math error.
     * Throw if the haveBeenPaidAmount calculation has a math error.
     * @param streamId The id of the stream to query.
     * @return The bool of transfer.
     */
    function transferWithInstallment(uint256 streamId)
        public
        whenNotPaused
        streamExists(streamId)
        returns(bool)
    {
        TransferLocalVars memory vars;
        Types.InstallmentStream memory installmentStream =  installmentStreams[streamId];

        require(installmentStream.haveBeenNumberOfInstallment < installmentStream.numberOfInstallments,"installment is finish");
        
        (vars.mathErr,vars.nextStopInstallmentTime) = mulThenAddUint(installmentStream.oneOfInstallmentTime,installmentStream.haveBeenNumberOfInstallment,installmentStream.startTime);
        assert(vars.mathErr == MathError.NO_ERROR);  
        
        require(block.timestamp < vars.nextStopInstallmentTime,"installmentStream is finish,rather than StopInstallmentTime");
        
        if (installmentStream.haveBeenNumberOfInstallment < installmentStream.numberOfInstallments - 1){
            vars.transferAmount = installmentStream.oneOfInstallmentAmount;
        }else if(installmentStream.haveBeenNumberOfInstallment == installmentStream.numberOfInstallments - 1){
            (vars.mathErr,vars.remainderOfInstallmentAmountWithFees) = modUInt(installmentStream.installmentAmountWithFees,installmentStream.numberOfInstallments);
            assert(vars.mathErr == MathError.NO_ERROR);
            
            (vars.mathErr,vars.transferAmount) = addUInt(installmentStream.oneOfInstallmentAmount,vars.remainderOfInstallmentAmountWithFees);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        (vars.mathErr, installmentStreams[streamId].haveBeenNumberOfInstallment) = addUInt(installmentStream.haveBeenNumberOfInstallment,uint256(1));
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr, installmentStreams[streamId].haveBeenPaidAmount) = addUInt(installmentStream.haveBeenPaidAmount,vars.transferAmount);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        require(IERC20(installmentStream.tokenAddress).transferFrom(msg.sender, address(this), vars.transferAmount), "token transfer failure");
        emit TransferWithInstallment(streamId,vars.transferAmount);

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
    function withdrawInstallmentStream(uint256 streamId,uint256 amount)
        external
        whenNotPaused
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns(bool)
    {
        require(amount > 0,"amount is zero");
        Types.InstallmentStream memory installmentStream =  installmentStreams[streamId];
        uint256 balance = installmentBalanceOf(streamId,installmentStream.recipient);
        require(balance >= amount,"amount exceeds the available balance");
        
        withdrawInstallmentStreamInterval(streamId,amount);
        return true;
    }
    
    struct WithdrawLocalVars {
        MathError mathErr;
        uint256 actualAmount;
    }

    /**
     * @notice transfer withdraw amount to recipient.
     * @dev Throws if the streamId does not exist.
     * Throw if the withdrawalAmount calculation has a math error.
     * @param streamId The id of the stream to query.
     * amount The amount of withdraw from stream.
     */
    function withdrawInstallmentStreamInterval(uint256 streamId,uint256 amount) internal{
        Types.InstallmentStream memory installmentStream =  installmentStreams[streamId];
        WithdrawLocalVars memory vars;

        (vars.mathErr,installmentStreams[streamId].withdrawalAmount) = addUInt(installmentStream.withdrawalAmount,amount);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        if (installmentStreams[streamId].withdrawalAmount == installmentStream.installmentAmountWithFees) delete installmentStreams[streamId];
        
        uint256 feesOfProtocol = calculationFeesOfProtocol(amount);
        
        (vars.mathErr, earnings[installmentStream.tokenAddress]) = addUInt(earnings[installmentStream.tokenAddress], feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr, vars.actualAmount) = subUInt(amount, feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);

        require(IERC20(installmentStream.tokenAddress).transfer(installmentStream.recipient, vars.actualAmount), "token transfer failure");
        emit WithdrawFromInstallmentStream(streamId,installmentStream.recipient,amount,vars.actualAmount,feesOfProtocol);
    }    


    /**
     * @notice Finish the stream.
     * @dev Throws if the streamId does not exist.
     * Throw if caller is not sender or recipient.
     * @param streamId The id of the stream to query.
     * @return The bool of transfer amount.
     */
    function cancelInstallmentStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns(bool)
    {
        cancelInstallmentStreamInternal(streamId);
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
    function cancelInstallmentStreamInternal(uint256 streamId) internal{
        Types.InstallmentStream memory installmentStream =  installmentStreams[streamId];
        CancelLocalVars memory vars;

        uint256 senderBalance = installmentBalanceOf(streamId,installmentStream.sender);
        uint256 recipientBalance = installmentBalanceOf(streamId,installmentStream.recipient);
        uint256 feesOfProtocol = calculationFeesOfProtocol(recipientBalance);
        
        (vars.mathErr, earnings[installmentStream.tokenAddress]) = addUInt(earnings[installmentStream.tokenAddress], feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.actualRecipientBalance) = subUInt(recipientBalance, feesOfProtocol);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        delete installmentStreams[streamId];
        
        IERC20 token = IERC20(installmentStream.tokenAddress);
        if (recipientBalance > 0)
            require(token.transfer(installmentStream.recipient, vars.actualRecipientBalance), "recipient token transfer failure");
        if (senderBalance > 0) require(token.transfer(installmentStream.sender,senderBalance));
        
        emit CancelInstallmentStream(streamId,installmentStream.sender,installmentStream.recipient,senderBalance,recipientBalance,feesOfProtocol);
    }
}