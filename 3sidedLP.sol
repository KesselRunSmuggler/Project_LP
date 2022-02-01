pragma solidity ^0.5.0;
import "USDT.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/drafts/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";



contract StableLP{
    using SafeMath for uint; //required for safemath operations
    using Counters for Counters.Counter;
    Counters.Counter loanIDs;
    
    //setting the addresses for the stablecoins
    address BUSD = 0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2; //(coin 1)
    address USDT = 0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0; //(coin 2)
    address USDC = 0x007F9dAE9B6D099961F39A897e298B8D631BDcd0; //(coin 3)

    mapping(address=>uint) balances; //creates mapping for deposits and withdrawals
    mapping(address=>uint) loanIDMap; //creates mapping for a loan from each address
    mapping(uint=>uint) loanValueMap; //creates mapping for each loan's value
    mapping(uint=>uint) loanTimesMap; //creates mapping for each loan's timestamp
    mapping(uint=>address) loanCurrencyMap; //creates mapping for each loan's currency type

    uint feeMult = 10**10; // creates 10 decimal precision for fee taking
    uint profitShare= 90; // 90% of profit goes to depositers 
    uint totalDeposits = 0; //total amount of deposits (divided by feeMult)
    uint loanInterestRate = 20; //simple interest for loans, set to 20% as anchor protocol offers ~19% APY
    //set to 200000 for testing (1 second = 10000 seconds) 

    address owner = msg.sender;

        // sets the minimum swap amount to $50
    modifier minSwap(uint swap) {
        require(swap >= 50);
        _;
    }

    
    modifier onlyOwner {
        require(msg.sender == owner, "You do not have permission to complete this action! Please contact the admin for further assistance.");
        _;
    }

    //checks who the owner is
    function checkOwner() public view returns(address){
        return owner;
    }

    // functions to deposit funds into liquidity pool
    function depositBUSD(uint amount) public payable {
        deposit(amount,BUSD);
    }

    function depositUSDT(uint amount) public payable {
        deposit(amount,USDT);
    }

    function depositUSDC(uint amount) public payable {
        deposit(amount,USDC);
    }

    //function to actually deposit tokens
    function deposit(uint amount, address depositToken) private {
        IERC20 depositToken = IERC20(depositToken); 
        amount = amount.mul(10**18); //to decimals 
        depositToken.transferFrom(msg.sender,address(this),amount); //deposits tokens
        amount = amount.mul(10**10); //extra precision for feeMult
        amount = amount.div(feeMult); //taking into account current fees accumulated

        balances[msg.sender] = balances[msg.sender].add(amount);
        totalDeposits = totalDeposits.add(amount);
    }




    //functions to withdraw deposits, no optional params in solidity 
    //may input anything in amount if max param is 1, otherwise may input anything else in max param
    function withdrawBUSD(uint amount, uint max) public {
        withdraw(amount,max,address(BUSD));    
    }

    function withdrawUSDT(uint amount, uint max) public {
        withdraw(amount,max,address(USDT));    
    }

    function withdrawUSDC(uint amount, uint max) public {
        withdraw(amount,max,address(USDC));    
    }

    //function to execute withdrawal
    function withdraw(uint amount, uint max, address withdrawToken) private {
        IERC20 withdrawToken = IERC20(withdrawToken);
        if (max == 1){
            amount = balances[msg.sender]; //max withdraw
            totalDeposits = totalDeposits.sub(amount);
            amount = amount.mul(feeMult); // converts to USD value leading digits
            amount = amount.div(10**10); // converts to USD value
            require(amount <= withdrawToken.balanceOf(address(this)), "Insufficient liquidity");

            //sends token
            uint fees = calculateFees(address(withdrawToken),amount);
            amount = amount.sub(fees);
            withdrawToken.transfer(msg.sender,amount);
            balances[msg.sender] = 0;
        } else {
            amount = amount.mul(10**18); // converts it to correct decimals
            require(amount <= withdrawToken.balanceOf(address(this)), "Insufficient liquidity");
            uint amountTemp = amount.mul(10**10); //temp variable to check balance
            amountTemp = amountTemp.div(feeMult); 
            require(amountTemp<=balances[msg.sender], "Not enough deposits to withdraw");

            //sends token
            uint fees = calculateFees(address(withdrawToken),amount);
            amount = amount.sub(fees);
            withdrawToken.transfer(msg.sender,amount);
            balances[msg.sender] = balances[msg.sender].sub(amountTemp);
            totalDeposits = totalDeposits.sub(amountTemp);
        }
    }

    // checks total amount available to withdraw
    function availableWithdrawal() public view returns(uint) {
        uint balance = balances[msg.sender];
        balance = balance.mul(feeMult);
        balance = balance.div(10**10);
        return balance;
    }

    // function to calculate fees
    // returns fees in 18 decimals 
    // fees = (1-portion of total liquidity of output token) * 0.1%
    // if all pools have same liquidity, should expect average fee of 0.067%
    function calculateFees(address output, uint swap) private returns(uint){

        IERC20 outputToken = IERC20(output); 

        uint totalUSD = totalBalance(); // stores total balance of all coins
        uint outputAmount = outputToken.balanceOf(address(this)); // stores total balance of output token
        outputAmount = outputAmount.sub(swap.div(2)); // accounts for magnitude of swap
        outputAmount = outputAmount.mul(10**12); // gives fees 12 decimals of precision
        uint outputPortion = outputAmount.div(totalUSD); //leading digits fo propotion
        uint maxFee = 10**12;
        uint fee = maxFee.sub(outputPortion);
        fee = fee.mul(swap);
        fee = fee.div(10**15);
        
        // passes down 90% of fees to depositers
        accumulateFees(fee);

        return fee;
    }

    //exchange functions of different pairs
    function BUSDtoUSDT(uint swapAmount) public payable minSwap(swapAmount) {
        swap(swapAmount, BUSD, USDT);
    }
    function BUSDtoUSDC(uint swapAmount) public payable minSwap(swapAmount) {
        swap(swapAmount, BUSD, USDC);
    }
    function USDTtoBUSD(uint swapAmount) public payable minSwap(swapAmount) {
        swap(swapAmount, USDT, BUSD);
    }
    function USDTtoUSDC(uint swapAmount) public payable minSwap(swapAmount) {
        swap(swapAmount, USDT, USDC);
    }
    function USDCtoBUSD(uint swapAmount) public payable minSwap(swapAmount) {
        swap(swapAmount, USDC, BUSD);
    }
    function USDCtoUSDT(uint swapAmount) public payable minSwap(swapAmount) {
        swap(swapAmount, USDC, USDT);
    }

    //function that performs the actual exchange
    function swap(uint swap, address inputToken, address outputToken) private {
        swap = swap.mul(10**18); //adjusts the swap into decimals
        IERC20 inputToken = IERC20(inputToken); 
        IERC20 outputToken = IERC20(outputToken); 
        //checks to see if there is enough of USDT in contract
        uint outputTokenBalance = outputToken.balanceOf(address(this));
        require(swap <= outputTokenBalance, "Insufficient liquidity!");

        //taking tokens from msg.sender into contract for swap
        inputToken.transferFrom(msg.sender,address(this),swap);

        // calculating fees = (output-swap/2) / (total balance) * 0.1%
        uint fee = calculateFees(address(outputToken),swap);

        //tokens - fees being sent back to msg.sender for swap 
        swap = swap.sub(fee);
        outputToken.transfer(msg.sender,swap);
    }

    //90% of all trading fees go to liquidity providers 
    function accumulateFees(uint fee) private {
        uint totalBalance = totalBalance();
        fee = fee.mul(10**30); //increases precision for calculations
        uint feeProportion = fee.div(totalBalance); 
        feeProportion = feeProportion.mul(profitShare);
        feeProportion = feeProportion.div(100);
        feeProportion = feeProportion.add(10**30);
        feeMult = feeMult.mul(feeProportion);
        feeMult = feeMult.div(10**30);
    }

    function feesCheck() public view returns(uint) {
        return feeMult;
    }

    //functions to check balance of each coin
    function BUSDbal() public view returns(uint){
        IERC20 coin1 = IERC20(BUSD);
        return coin1.balanceOf(address(this));
    }

    function USDTbal() public view returns(uint){
        IERC20 coin1 = IERC20(USDT);
        return coin1.balanceOf(address(this));
    }

    function USDCbal() public view returns(uint){
        IERC20 coin1 = IERC20(USDC);
        return coin1.balanceOf(address(this));
    }

    //function to check balance of all coins combined
    function totalBalance() public view returns(uint){
        
        IERC20 BUSDToken = IERC20(BUSD);
        IERC20 USDTToken = IERC20(USDT);
        IERC20 USDCToken = IERC20(USDC);
        
        uint BUSDbal = IERC20(BUSD).balanceOf(address(this));
        uint USDTbal = IERC20(USDT).balanceOf(address(this));
        uint USDCbal = IERC20(USDC).balanceOf(address(this));

        uint totalBal = BUSDbal.add(USDTbal.add(USDCbal));

        return totalBal;
    }

    function updateProfitShare(uint newProfitShare) public onlyOwner {
        require(newProfitShare<=100, "Cannot share more than 100% of fees");
        profitShare = newProfitShare;
    }

    //calculates how much of the protocol is profit
    function protocolOwnership() public view returns(uint){
        uint totalUSD = totalDeposits.mul(feeMult);
        totalUSD = totalUSD.div(10**10);
        uint totalBalance = totalBalance();
        totalUSD = totalBalance.sub(totalUSD);
        return totalUSD;
    }

    //withdraws profit in decimals (since other functions are in decimals)
    function withdrawOwnership(uint withdraw, address tokenAddress) public onlyOwner {
        require(withdraw <= protocolOwnership(),"Cannot withdraw more than you own");
        IERC20 tokenAddress = IERC20(tokenAddress);
        require(withdraw<=tokenAddress.balanceOf(address(this)), "Insufficient liquidity");
        tokenAddress.transfer(msg.sender,withdraw);
    }

    //create a function to approve a loan (will need a mapping of timestamp)
    //only the CO may approve
    //assumes the CO has done sufficient background checks + collected security
    //primitive implementation of loans
    function approveLoan (address borrower, uint loanSize, address loanCurrency) private onlyOwner {
        IERC20 loanCurrency = IERC20(loanCurrency);
        loanSize = loanSize.mul(10**18); //converts loan size to decimals
        require(loanSize<=loanCurrency.balanceOf(address(this)),"Insufficient liquidity"); 
        require(loanIDMap[borrower] == 0, "User must only have one loan");

        loanIDs.increment();
        uint loanID = loanIDs.current();
        loanIDMap[borrower] = loanID;

        //saves all data of loanID into their respective mappings
        loanValueMap[loanID] = loanSize;
        loanCurrencyMap[loanID] = address(loanCurrency);
        loanTimesMap[loanID] = block.timestamp;

        //transfers funds to the recipient
        loanCurrency.transfer(borrower,loanSize);
    }

    function approveBUSDLoan(address borrower, uint loanSize) public {
        approveLoan(borrower, loanSize, BUSD);
    }

    function approveUSDTLoan(address borrower, uint loanSize) public {
        approveLoan(borrower, loanSize, USDT);
    }

    function approveUSDCLoan(address borrower, uint loanSize) public {
        approveLoan(borrower, loanSize, USDC);
    }

    //pays off full balance of loan
    function loanPayOff() public {
        require(loanIDMap[msg.sender] != 0, "You must have an active loan");

        //getting details of loan
        uint loanID = loanIDMap[msg.sender];
        uint loanSize = loanValueMap[loanID];
        IERC20 loanCurrency = IERC20(loanCurrencyMap[loanID]);
        uint loanTime = loanTimesMap[loanID];

        //calculating interest fees for loan
        uint timeElapsed = block.timestamp.sub(loanTime);
        uint interest = loanSize.mul(loanInterestRate.mul(timeElapsed));
        interest = interest/(100*365*24*60*60); //since blockchain time in unix time

        loanSize = loanSize.add(interest); //includes interest in payment

        //transfers loan balance back
        loanCurrency.transferFrom(msg.sender,address(this), loanSize);

        //profit sharing interest charges
        accumulateFees(interest);
    }

    //checks the loan balance of the current address
    function checkLoanBalance() public view returns(uint) {
        require(loanIDMap[msg.sender] != 0, "You must have an active loan");
        //getting details of loan
        uint loanID = loanIDMap[msg.sender];
        uint loanSize = loanValueMap[loanID];
        address loanCurrency = loanCurrencyMap[loanID];
        uint loanTime = loanTimesMap[loanID];

        //calculating interest fees for loan
        uint timeElapsed = block.timestamp.sub(loanTime);
        uint interest = loanSize.mul(loanInterestRate.mul(timeElapsed));
        interest = interest/(100*365*24*60*60); //since blockchain time in unix time

        loanSize = loanSize.add(interest); //includes interest in payment

        return loanSize;

    }

    //checks how many seconds the loan has existed for
    function checkTimeElapsed() public view returns(uint) {
        uint loanID = loanIDMap[msg.sender];
        uint timeElapsed = block.timestamp.sub(loanTimesMap[loanID]);
        return(timeElapsed);
    }

    //checks how much interest has been charged in cents
    function checkInterestCharge() public view returns(uint) {
        uint loanID = loanIDMap[msg.sender];
        uint timeElapsed = block.timestamp.sub(loanTimesMap[loanID]);
        uint loanSize = loanValueMap[loanID];
        uint interest = loanSize.mul(loanInterestRate.mul(timeElapsed));

        interest = interest.div(10**16);
        return(interest);
    }

    function checkBlockTimestamp() public view returns(uint) {
        return(block.timestamp);
    }

    //update the loan interest rates
    function updateLoanInterestRate(uint newInterestRate) public onlyOwner {
        require(newInterestRate>=20, "Interest rate cannot be lower than Anchor Protocol's return");
        loanInterestRate = newInterestRate;
    }

}