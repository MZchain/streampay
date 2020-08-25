pragma solidity 0.5.16;

library Types{
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 duration;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }
    
    struct FixedFlowrateStream {
        uint256 maxAmount;
        uint256 ratePerSecond;
        uint256 startTime;
        uint256 maxStopTime;
        address recipient;
        address sender;
        uint256 withdrawalAmount;
        address tokenAddress;
        bool isEntity;
    }
    
    struct InstallmentStream{
        uint256 deposit;
        uint256 installmentAmountWithFees;
        uint256 oneOfInstallmentAmount;
        uint256 oneOfInstallmentTime;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        uint256 numberOfInstallments;
        uint256 ratePerSecond;
        uint256 feesOfRecipientPer;
        uint256 haveBeenNumberOfInstallment;
        uint256 haveBeenPaidAmount;
        uint256 withdrawalAmount;
        address tokenAddress;
        bool isEntity;
    }
    
    struct InstallmentWithDPStream{
        uint256 deposit;
        uint256 downPaymentAmount;
        uint256 installmentAmountWithFees;
        uint256 oneOfInstallmentAmount;
        uint256 oneOfInstallmentTime;
        uint256 downPaymentRatio;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        uint256 numberOfInstallments;
        uint256 ratePerSecond;
        uint256 feesOfRecipientPer;
        uint256 haveBeenNumberOfInstallment;
        uint256 haveBeenPaidAmount;
        uint256 withdrawalAmount;
        address tokenAddress;
        bool isEntity;
    }
}