pragma solidity ^0.5.0;
import "USDT.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";



contract StableLP{
    //using SafeMath for uint256;
    
    //setting the addresses for the stablecoins
    address BUSD = 0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2; //(coin 1)
    address USDT = 0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0; //(coin 2)
    address USDC = 0x007F9dAE9B6D099961F39A897e298B8D631BDcd0; //(coin 3)

    mapping(address=>uint)balances; //creates mapping for deposits and withdrawals
    uint feeMult = 10**10; // creates 10 decimal precision for fee taking
    uint profitShare= 90; // 90% of profit goes to depositers 
    

    address owner;

        // sets the minimum swap amount to $50
    modifier minSwap(uint swap) {
        require(swap >= 50);
        _;
    }

    
    modifier onlyOwner {
        require(msg.sender == owner, "You do not have permission to mint these tokens!");
        _;
    }

    constructor() public {
        address owner = msg.sender;
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

    //90% of all trading fees go to liquidit providers 
    function accumulateFees(uint fee) public returns(uint) {
        fee = fee.mul(10**16);
        uint totalBalance = totalBalance();
        fee = fee.mul(10**30); //increases precision for calculations
        uint feeProportion = fee.div(totalBalance.mul(profitShare)); 
        feeProportion = feeProportion.div(100);
        feeProportion = feeProportion.add(10**30);
        feeMult = feeMult.mul(feeProportion);
        feeMult = feeMult.div(10**30);
        return feeMult;
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
        profitShare = newProfitShare;
    }



}