pragma solidity ^0.5.16;

interface streamPayOfInstallmentWithDPInterface{
    /**
     * @notice Emits when the owner takes the earnings.
     */
    event TakeEarnings(address indexed tokenAddress, uint256 indexed amount);
    
    event UpdateFee(uint256 indexed fee);

    
    /**
     * Emit when Renewal maxAmount
     */
    event TransferWithDP(
        uint256 indexed streamId,
        uint256 transferAmount
    );
    
    /**
     * installmentWithDownPay
     */
     
    event CreateInstallmentWithDPStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 numberOfInstallments,
        uint256 downPaymentRatio,
        uint256 feesOfRecipientPer
    );
    
        /**
     * Emit when recipient withdraw money from stream.
     */
    event WithdrawFromInstallmentWithDPStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount,
        uint256 actualAmount,
        uint256 feesOfProtocol
    );
    
    /**
     * Emit when recipient or sender finish stream.
     */
    event CancelInstallmentWithDPStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance,
        uint256 feesOfProtocol
    );
    
    function createInstallmentWithDPStream(address recipient,uint256 deposit,address tokenAddress,uint256 startTime,
    uint256 stopTime,uint256 numberOfInstallments,uint256 downPaymentRatio,uint256 feesOfRecipientPer) external returns(uint256);
    
    function installmentWithDPBalanceOf(uint256 streamId, address who) external returns (uint256 balance);
    
    function withdrawInstallmentWithDPStream(uint256 streamId,uint256 amount) external returns(bool);
    
    function cancelInstallmentWithDPStream(uint256 streamId) external returns(bool);
    
    function transferWithDP(uint256 streamId) external returns(bool);

    function getInstallmentWithDPStream(uint256 streamId) external view returns(
        address sender,
        address recipient,
        uint256 deposit,
        uint256 downPaymentRatio,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 numberOfInstallments,
        uint256 feesOfRecipientPer,
        uint256 ratePerSecond,
        uint256 haveBeenNumberOfInstallment,
        uint256 withdrawalAmount);
}

