pragma solidity ^0.5.16;

interface streamPayOfInstallmentInterface{
    /**
     * @notice Emits when the owner takes the earnings.
     */
    event TakeEarnings(address indexed tokenAddress, uint256 indexed amount);
    
    
    event UpdateFee(uint256 indexed fee);

    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateInstallmentStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 numberOfInstallments,
        uint256 feesOfRecipientPer
    );
    
    /**
     * Emit when Renewal maxAmount
     */
    event TransferWithInstallment(
        uint256 indexed streamId,
        uint256 transferAmount
    );
    
    /**
     * Emit when recipient withdraw money from stream.
     */
    event WithdrawFromInstallmentStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount,
        uint256 actualAmount,
        uint256 feesOfProtocol
    );
    
    /**
     * Emit when recipient or sender finish stream.
     */
    event CancelInstallmentStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance,
        uint256 feesOfProtocol
    );
    
    function installmentBalanceOf(uint256 streamId, address who) external returns (uint256 balance);

    function getInstallmentStream(uint256 streamId) external view returns(
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
        uint256 withdrawalAmount);

    function createInstallmentStream(address recipient,uint256 deposit,address tokenAddress,uint256 startTime,uint256 stopTime,uint256 numberOfInstallments,uint256 feesOfRecipientPer) external returns(uint256);
    
    function transferWithInstallment(uint256 streamId) external returns(bool);
    
    function withdrawInstallmentStream(uint256 streamId,uint256 amount) external returns(bool);

    function cancelInstallmentStream(uint256 streamId) external returns(bool);

}

