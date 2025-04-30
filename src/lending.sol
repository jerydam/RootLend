// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract P2PLending is Ownable(msg.sender) {
    constructor(
        address _treasuryaddr,
        address Root,
        address usdt,
        address dai
    ) Ownable(msg.sender) {
        treasuryAddress = _treasuryaddr;
        _addCollateral(Root);
        _addCollateral(usdt);
        _addCollateral(dai);
    }

    uint public constant MIN_LOAN_AMOUNT = 0.001 ether;
    uint public constant MAX_LOAN_AMOUNT = 100000 ether;
    uint public constant MIN_INTEREST_RATE = 2;
    uint public constant MAX_INTEREST_RATE = 20;
    uint public constant SERVICE_FEE_PERCENTAGE = 2;

    struct Loan {
        uint loan_id;
        uint amount;
        uint interest;
        uint duration;
        uint repaymentAmount;
        uint fundingDeadline;
        uint collateralAmount;
        address borrower;
        address payable lender;
        address collateral;
        bool isCollateralErc20;
        bool active;
        bool repaid;
    }

    mapping(uint => Loan) public loans;
    mapping(address => uint) public defaulters;
    mapping(address => bool) public outstanding;
    mapping(address => bool) public accepteddCollaterals;
    address[] public accepted_collaterals;
    uint public loanCount;
    address public treasuryAddress;
    address public dao;
    uint public totalServiceCharges;

    address public aiOperator = 0x82aD97bEf0b7E17b1D30f56e592Fc819E1eeDAfc; // 👈 New: AI Operator address

    event LoanCreated(uint loanId, uint amount, uint interest, uint duration, uint fundingDeadline, address borrower, address lender);
    event LoanFunded(uint loanId, address funder, uint amount);
    event LoanRepaid(uint loanId, uint amount);
    event ServiceFeeDeducted(uint loanId, uint amount);
    event ServiceChargesWithdrawn(address owner, uint amount);
    event CollateralClaimed(uint loanId, address lender);
    event CollateralAdded(address collateral);

    modifier onlyActiveLoan(uint _loanId) {
        require(loans[_loanId].active, "Loan is not active");
        _;
    }

    modifier isCollateral(address _addr) {
        require(accepteddCollaterals[_addr] == true, "collateral not acceptable");
        _;
    }

    modifier onlyDao(address _caller) {
        require(_caller == dao, "unauthorized");
        _;
    }

    modifier onlyBorrower(uint _loanId) {
        require(msg.sender == loans[_loanId].borrower, "Only the borrower can perform this action");
        _;
    }

    modifier onlyAiOperator() {
        require(msg.sender == aiOperator, "Only AI Operator allowed");
        _;
    }

    // --- ADMIN FUNCTIONS ---

    function setAdaOaddress(address _dao) public onlyOwner {
        dao = _dao;
    }

    function setAiOperator(address _aiOperator) external onlyOwner {
        aiOperator = _aiOperator;
    }

    function addCollateral(address _collateral) public onlyOwner {
        _addCollateral(_collateral);
        emit CollateralAdded(_collateral);
    }

    function _addCollateral(address _collateral) internal {
        accepteddCollaterals[_collateral] = true;
        accepted_collaterals.push(_collateral);
    }

    function getAllLoans() external view returns (Loan[] memory) {
        Loan[] memory allLoans = new Loan[](loanCount);
        for (uint i = 0; i < loanCount; i++) {
            allLoans[i] = loans[i];
        }
        return allLoans;
    }

    // --- LOAN CREATION ---

    function createLoan(
        uint _amount,
        uint _interest,
        uint _duration,
        uint _collateralamount,
        address _collateral,
        bool _isERC20,
        uint _fundingDeadline
    ) external payable isCollateral(_collateral) {
        require(_amount >= MIN_LOAN_AMOUNT && _amount <= MAX_LOAN_AMOUNT, "Loan amount invalid");
        require(_interest >= MIN_INTEREST_RATE && _interest <= MAX_INTEREST_RATE, "Interest rate invalid");
        require(_duration > 0, "Loan duration must be > 0");
        require(outstanding[msg.sender] == false, "settle outstanding loan first");

        uint loanId = loanCount++;
        Loan storage loan = loans[loanId];

        uint _repaymentAmount = _amount + (_amount * _interest) / 100;

        loan.loan_id = loanId;
        loan.amount = _amount;
        loan.interest = _interest;
        loan.duration = _duration + block.timestamp;
        loan.repaymentAmount = _repaymentAmount;
        loan.fundingDeadline = _fundingDeadline + block.timestamp;
        loan.borrower = msg.sender;
        loan.collateral = _collateral;
        loan.collateralAmount = _collateralamount;
        loan.isCollateralErc20 = _isERC20;
        loan.lender = payable(address(0));
        loan.active = true;
        loan.repaid = false;

        if (_isERC20) {
            require(
                IERC20(_collateral).transferFrom(
                    msg.sender,
                    address(this),
                    _collateralamount
                ),
                "ERC20 transfer failed"
            );
        } else {
            IERC721(_collateral).transferFrom(
                msg.sender,
                address(this),
                _collateralamount
            );
        }

        emit LoanCreated(loanId, _amount, _interest, _duration, _fundingDeadline, msg.sender, address(0));
    }

    function fundLoan(uint _loanId) external payable onlyActiveLoan(_loanId) {
        Loan storage loan = loans[_loanId];
        require(msg.sender != loan.borrower, "Borrower cannot fund");
        require(block.timestamp <= loan.fundingDeadline, "Funding deadline passed");

        payable(msg.sender).transfer(loan.amount);
        loan.lender = payable(msg.sender);
        outstanding[loan.borrower] = true;

        emit LoanFunded(_loanId, msg.sender, loan.amount);
    }

    function repayLoan(uint _loanId) external payable onlyActiveLoan(_loanId) onlyBorrower(_loanId) {
        _processRepayment(_loanId, msg.sender);
    }

    // --- AI PAYMENT SYSTEM ---

    function aiFundLoan(uint _loanId, address _funder) external payable onlyAiOperator onlyActiveLoan(_loanId) {
        Loan storage loan = loans[_loanId];
        require(_funder != loan.borrower, "Borrower cannot fund");
        require(block.timestamp <= loan.fundingDeadline, "Funding deadline passed");

        payable(_funder).transfer(loan.amount);
        loan.lender = payable(_funder);
        outstanding[loan.borrower] = true;

        emit LoanFunded(_loanId, _funder, loan.amount);
    }

    function aiRepayLoan(uint _loanId, address _borrower) external payable onlyAiOperator onlyActiveLoan(_loanId) {
        _processRepayment(_loanId, _borrower);
    }

    function _processRepayment(uint _loanId, address _borrower) internal {
        Loan storage loan = loans[_loanId];
        require(!loan.repaid, "Already repaid");
        require(_borrower == loan.borrower, "Invalid borrower");

        uint interestAmount = (loan.amount * loan.interest) / 100;
        uint repaymentAmount = loan.amount + interestAmount;
        uint serviceFee = (repaymentAmount * SERVICE_FEE_PERCENTAGE) / 100;
        uint amountAfterFee = repaymentAmount - serviceFee;

        loan.lender.transfer(amountAfterFee);
        payable(treasuryAddress).transfer(serviceFee);

        if (loan.isCollateralErc20) {
            require(IERC20(loan.collateral).transfer(_borrower, loan.collateralAmount), "ERC20 collateral return failed");
        } else {
            IERC721(loan.collateral).transferFrom(address(this), _borrower, loan.collateralAmount);
        }

        totalServiceCharges += serviceFee;

        loan.repaid = true;
        loan.active = false;
        outstanding[_borrower] = false;

        emit LoanRepaid(_loanId, repaymentAmount);
        emit ServiceFeeDeducted(_loanId, serviceFee);
    }

    // --- COLLATERAL & WITHDRAWALS ---

    function claimCollateral(uint _loanId) external onlyActiveLoan(_loanId) {
        Loan storage loan = loans[_loanId];
        require(block.timestamp > loan.fundingDeadline && !loan.repaid, "Loan still active");

        require(msg.sender == loan.lender, "Only lender");

        if (loan.isCollateralErc20) {
            require(IERC20(loan.collateral).transfer(msg.sender, loan.collateralAmount), "ERC20 collateral claim failed");
        } else {
            IERC721(loan.collateral).transferFrom(address(this), msg.sender, loan.collateralAmount);
        }

        loan.active = false;
        defaulters[loan.borrower] += 1;
        outstanding[loan.borrower] = false;

        emit CollateralClaimed(_loanId, msg.sender);
    }

    function withdrawFunds(uint _loanId) external onlyBorrower(_loanId) {
        Loan storage loan = loans[_loanId];
        require(loan.collateralAmount != 0, "No collateral");
        require(block.timestamp > loan.fundingDeadline, "Funding deadline not yet passed");

        loan.active = false;
        loan.collateralAmount = 0;
        loan.collateral = address(0);

        if (loan.isCollateralErc20) {
            require(IERC20(loan.collateral).transfer(msg.sender, loan.collateralAmount), "ERC20 collateral withdraw failed");
        } else {
            IERC721(loan.collateral).transferFrom(address(this), msg.sender, loan.collateralAmount);
        }
    }

    function getLoanInfo(uint _loanId) external view returns (Loan memory) {
        return loans[_loanId];
    }

    receive() external payable {}
    fallback() external payable {}
}