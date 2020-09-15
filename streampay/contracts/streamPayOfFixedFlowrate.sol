pragma solidity 0.5.16;

import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

import "./tools-contracts/OwnableWithoutRenounce.sol";
import "./tools-contracts/PausableWithoutRenounce.sol";
import "./tools-contracts/CarefulMath.sol";

import "./interface/streamPayOfFixedFlowrateInterface.sol";
import './Types.sol';

/**
 * @title 流付/StreamPay's money streaming of fixedFlowrateStream
 * @author StreamPay
 */

contract streamPayOfFixedFlowrate is OwnableWithoutRenounce, PausableWithoutRenounce, CarefulMath, ReentrancyGuard, streamPayOfFixedFlowrateInterface{
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
    mapping(uint256 =>Types.FixedFlowrateStream) private fixedFlowrateStreams;
    
    /*** Modifiers ***/
    
    /**
     * @dev Throws if the caller not sender or recipient of the stream.
     */
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == fixedFlowrateStreams[streamId].sender || msg.sender == fixedFlowrateStreams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

    /**
     * @dev Throws if the provided id does not point to a valid stream.
     */
    modifier streamExists(uint256 streamId) {
        require(fixedFlowrateStreams[streamId].isEntity, "stream does not exist");
        _;
    }
    
    /*** Contract Logic Starts Here */

    constructor() public {
        OwnableWithoutRenounce.initialize(msg.sender);
        PausableWithoutRenounce.initialize(msg.sender);
        nextStreamId = 1;
        symbol = 2000000;
    }
    
    /*** Owner Functions ***/

    /**
     * @notice Returns the fixedflowratestream with all its properties.
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     * @return The fixedflowratestream object.
     */
    function getFixedFlowrateStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 maxAmount,
            address tokenAddress,
            uint256 startTime,
            uint256 maxStopTime,
            uint256 ratePerSecond,
            uint256 withdrawalAmount
            )
    {
        sender = fixedFlowrateStreams[streamId].sender;
        recipient = fixedFlowrateStreams[streamId].recipient;
        maxAmount = fixedFlowrateStreams[streamId].maxAmount;
        tokenAddress = fixedFlowrateStreams[streamId].tokenAddress;
        startTime = fixedFlowrateStreams[streamId].startTime;
        maxStopTime = fixedFlowrateStreams[streamId].maxStopTime;
        ratePerSecond = fixedFlowrateStreams[streamId].ratePerSecond;
        withdrawalAmount = fixedFlowrateStreams[streamId].withdrawalAmount;

    }
    
    struct CreateFixedFlowrateStreamLocalVars {
        MathError mathErr;
        uint256 maxStopTime;
        uint256 duration;
    }
    
    /**
     * @notice Create a fixedflowratestream funded by `msg.sender` and paid towards `recipient`..
     * @dev Throws if paused.
     * Throw if the recipient is zero address,the contract itself or the msg.sender.
     * Throw if the maxAmount is 0.
     * Throw if ratePerSecond is 0.
     * Throw if maxAmount is smaller than ratePerSecond.
     * Throw if startTime is smaller than block.timestamp.
     * Throw if the streamId calculation has a math error.
     * Throw if the remainder calculation has a math error.
     * Throw if the maxStopTime calculation has a math error.
     * Throw if the nextStreamId calculation has a math error.
     * @param recipient The address of receipt stream money.
     * maxAmount The max amount of stream.
     * tokenAddress The ERC20 token.
     * ratePerSecond The flow rate of the stream.Example 10000000000000000 per second.
     * startTime The time of stream start.
     * @return The id of the stream.
     */
    function createFixedFlowrateStream(address recipient,uint256 maxAmount,address tokenAddress,uint256 ratePerSecond,uint256 startTime) 
        public
        whenNotPaused
        returns(uint256)
    {
        require(recipient != address(0x00),"stream to the zero address");
        require(recipient != address(this),"stream to the contract");
        require(recipient != msg.sender,"stream to the caller");
        require(maxAmount > 0,"maxAmount is 0");
        require(ratePerSecond > 0,"ratePerSecond is 0");
        require(maxAmount >= ratePerSecond,"maxAmount is smaller than ratePerSecond");
        require(startTime >= block.timestamp, "start time before block.timestamp");

        CreateFixedFlowrateStreamLocalVars memory vars;

        (vars.mathErr,vars.maxStopTime) = divThenAddUInt(maxAmount,ratePerSecond,startTime);
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.duration) = subUInt(vars.maxStopTime, startTime);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        uint256 streamId;
        (vars.mathErr,streamId) = addUInt(symbol,nextStreamId);
        assert(vars.mathErr == MathError.NO_ERROR); 

        fixedFlowrateStreams[streamId] = Types.FixedFlowrateStream({
            maxAmount: maxAmount,
            ratePerSecond: ratePerSecond,
            startTime: startTime,
            maxStopTime: vars.maxStopTime,
            recipient: recipient,
            sender: msg.sender,
            withdrawalAmount:0,
            tokenAddress: tokenAddress,
            isEntity: true
        });
        
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        assert(vars.mathErr == MathError.NO_ERROR);
        
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), maxAmount),"create stream,transfer failure");
        emit CreateFixedFlowrateStream(streamId, msg.sender, recipient, maxAmount, tokenAddress, startTime,vars.maxStopTime,ratePerSecond);
        return streamId;
    }

    /**
     * @notice return the duration of the stream
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     * @return The duration of the stream's startTime to now.
     */
    function fixedFlowrateDeltaOf(uint256 streamId)
        public
        view
        streamExists(streamId)
        returns(uint256)
    {
        Types.FixedFlowrateStream memory fixedFlowrateStream =  fixedFlowrateStreams[streamId];

        if(block.timestamp <= fixedFlowrateStream.startTime) return 0;
        if(block.timestamp < fixedFlowrateStream.maxStopTime) return block.timestamp - fixedFlowrateStream.startTime;
        return fixedFlowrateStream.maxStopTime - fixedFlowrateStream.startTime;
    }

    struct FixedFlowrateBalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 senderBalance;
        uint256 handleBalance;
        uint256 remainder;
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
    function fixedFlowrateBalanceOf(uint256 streamId,address who)
        public
        view
        streamExists(streamId)
        returns(uint256 balance)
    {
        Types.FixedFlowrateStream memory fixedFlowrateStream =  fixedFlowrateStreams[streamId];
        FixedFlowrateBalanceOfLocalVars memory vars;

        uint256 delta= fixedFlowrateDeltaOf(streamId);
        
        (vars.mathErr,vars.handleBalance) = mulUInt(delta,fixedFlowrateStream.ratePerSecond);
        assert(vars.mathErr == MathError.NO_ERROR);

        if (block.timestamp >= fixedFlowrateStream.maxStopTime){
            (vars.mathErr,vars.remainder) = modUInt(fixedFlowrateStream.maxAmount,fixedFlowrateStream.ratePerSecond);
            assert(vars.mathErr == MathError.NO_ERROR);
        
            (vars.mathErr,vars.handleBalance) = addUInt(vars.remainder,vars.handleBalance);
            assert(vars.mathErr == MathError.NO_ERROR);
        }
        
        (vars.mathErr,vars.recipientBalance) = subUInt(vars.handleBalance,fixedFlowrateStream.withdrawalAmount);
        assert(vars.mathErr == MathError.NO_ERROR);

        if(who == fixedFlowrateStream.recipient) return vars.recipientBalance;
        if(who == fixedFlowrateStream.sender){
            (vars.mathErr,vars.senderBalance) = subUInt(fixedFlowrateStream.maxAmount,vars.handleBalance);
            assert(vars.mathErr == MathError.NO_ERROR);

            return vars.senderBalance;
        }
        return 0;
    }
    
    struct TransferLocalVars {
        MathError mathErr;
    }
    
    /**
     * @notice renewal maxAmount for continue stream.
     * @dev Throws if paused.
     * Throws if the streamId does not exist.
     * Throw if the maxAmount calculation has a math error.
     * Throw if the remainder calculation has a math error.
     * Throw if the maxStopTime calculation has a math error.
     * @param streamId The id of the stream to query.
     * amount The amount of continue stream for Increase maxAmount.
     * @return The bool of transfer amount.
     */
    function transferWithFixedFlowrate(uint256 streamId,uint256 amount)
        external
        whenNotPaused
        nonReentrant
        streamExists(streamId)
        returns(bool)
    {
        Types.FixedFlowrateStream memory fixedFlowrateStream =  fixedFlowrateStreams[streamId];
        TransferLocalVars memory vars;

        require(block.timestamp < fixedFlowrateStream.maxStopTime,"block.timeStamp bigger than maxStopTime");
        require(amount > 0,"maxAmount is 0");
        
        (vars.mathErr,fixedFlowrateStreams[streamId].maxAmount) = addUInt(fixedFlowrateStream.maxAmount,amount);
        assert(vars.mathErr == MathError.NO_ERROR);
        
        (vars.mathErr,fixedFlowrateStreams[streamId].maxStopTime) = divThenAddUInt(fixedFlowrateStreams[streamId].maxAmount,fixedFlowrateStream.ratePerSecond,fixedFlowrateStream.startTime);   
        assert(vars.mathErr == MathError.NO_ERROR);
        
        require(IERC20(fixedFlowrateStream.tokenAddress).transferFrom(msg.sender,address(this),amount),'transfer failure');
        emit TransferWithFixedFlowrate(streamId,amount);

        return true;
    }
    
    struct WithdrawLocalVars {
        MathError mathErr;
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
     * @return The bool of transfer.
     */
    function withdrawFromFlowrateStream(uint256 streamId,uint256 amount)
        external
        whenNotPaused
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns(bool)
    {
        Types.FixedFlowrateStream memory fixedFlowrateStream =  fixedFlowrateStreams[streamId];
        require(amount > 0,"amount is zero");
        
        uint256 balance = fixedFlowrateBalanceOf(streamId,fixedFlowrateStream.recipient);
        require(balance >= amount,"amount exceeds the available balance");
        
        withdrawFromFlowrateStreamInterval(streamId,amount);
        return true;
    }
    
    /**
     * @notice transfer withdraw amount to recipient.
     * @dev Throws if the streamId does not exist.
     * Throw if the withdrawalAmount calculation has a math error.
     * @param streamId The id of the stream to query.
     * amount The amount of withdraw from stream.
     */
    function withdrawFromFlowrateStreamInterval(uint256 streamId,uint256 amount)
        internal
    {
        Types.FixedFlowrateStream memory fixedFlowrateStream =  fixedFlowrateStreams[streamId];
        WithdrawLocalVars memory vars;
        
        (vars.mathErr,fixedFlowrateStreams[streamId].withdrawalAmount) = addUInt(fixedFlowrateStream.withdrawalAmount,amount);
        assert(vars.mathErr == MathError.NO_ERROR);

        require(IERC20(fixedFlowrateStream.tokenAddress).transfer(fixedFlowrateStream.recipient, amount), "token transfer failure");
        emit WithdrawFromFixedFlowrateStream(streamId,fixedFlowrateStream.recipient,amount);
    }
    
    /**
     * @notice Finish the stream.
     * @dev Throws if the streamId does not exist.
     * Throw if caller is not sender or recipient.
     * @param streamId The id of the stream to query.
     * @return The bool of transfer amount.
     */
    function cancelFlowrateStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns(bool)
    {
        cancelFlowrateStreamInternal(streamId);
        return true;
    }
    
    /**
     * @notice transfer amount to recipient and sender of finish stream account.
     * @dev Throws if the streamId does not exist.
     * @param streamId The id of the stream to query.
     */
    function cancelFlowrateStreamInternal(uint256 streamId) internal{
        Types.FixedFlowrateStream memory fixedFlowrateStream =  fixedFlowrateStreams[streamId];
        
        uint256 senderBalance = fixedFlowrateBalanceOf(streamId,fixedFlowrateStream.sender);
        uint256 recipientBalance = fixedFlowrateBalanceOf(streamId,fixedFlowrateStream.recipient);
        
        delete fixedFlowrateStreams[streamId];

        IERC20 token = IERC20(fixedFlowrateStream.tokenAddress);
        if (recipientBalance > 0)
            require(token.transfer(fixedFlowrateStream.recipient, recipientBalance), "recipient token transfer failure");
        if (senderBalance > 0) require(token.transfer(fixedFlowrateStream.sender,senderBalance));
        emit CancelFixedFlowrateStream(streamId, fixedFlowrateStream.sender, fixedFlowrateStream.recipient,senderBalance,recipientBalance,block.timestamp);
    }
}