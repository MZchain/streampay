pragma solidity ^0.5.16;

interface streamPayOfFixedFlowrateInterface{
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateFixedFlowrateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 maxAmount,
        address tokenAddress,
        uint256 startTime,
        uint256 maxStopTime,
        uint256 ratePerSecond
    );
    
    /**
     * Emit when Renewal maxAmount
     */
    event TransferWithFixedFlowrate(
        uint256 indexed streamId,
        uint256 amount
    );
    
    /**
     * Emit when recipient withdraw money from stream.
     */
    event WithdrawFromFixedFlowrateStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );
    
    /**
     * Emit when recipient or sender finish stream.
     */
    event CancelFixedFlowrateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance,
        uint256 timestamp
    );
    
    function fixedFlowrateBalanceOf(uint256 streamId,address who) external view returns (uint256 balance);

    function getFixedFlowrateStream(uint256 streamId)
        external
        view
        returns(
            address sender,
            address recipient,
            uint256 maxAmount,
            address tokenAddress,
            uint256 startTime,
            uint256 maxStopTime,
            uint256 ratePerSecond,
            uint256 withdrawalAmount);

    function createFixedFlowrateStream(address recipient,uint256 maxAmount,address tokenAddress,uint256 ratePerSecond,uint256 startTime) 
        external
        returns(uint256 streamId);
    
    function transferWithFixedFlowrate(uint256 streamId,uint256 amount) external returns(bool);
    
    function withdrawFromFlowrateStream(uint256 streamId,uint256 amount) external returns(bool);

    function cancelFlowrateStream(uint256 streamId) external returns(bool);
}

