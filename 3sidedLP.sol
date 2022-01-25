pragma solidity ^0.5.0;
import "USDT.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";



contract StableLP{

    //setting the addresses for the stablecoins
    //address BUSD = 0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2 (coin 1)
    //address USDT = 0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0 (coin 2)
    //address USDC = 0x007F9dAE9B6D099961F39A897e298B8D631BDcd0 (coin 3)
    
    using SafeMath for uint256;

        // sets the minimum swap amount to $50
    modifier minSwap(uint swap) {
        require(swap >= 50);
        _;
    }

    // function to calculate fees
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

        return fee;
    }

    //function that exchanges function to exchange BUSD into USDT
    function swap12(uint256 swap) public payable minSwap(swap) {

        swap = swap.mul(10**18); //adjusts the swap into decimals
        IERC20 inputToken = IERC20(0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2); //BUSD
        IERC20 outputToken = IERC20(0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0); //USDT
        //checks to see if there is enough of USDT in contract
        uint256 outputTokenBalance = outputToken.balanceOf(address(this));
        require(swap <= outputTokenBalance, "Insufficient liquidity!");

        //taking tokens from msg.sender into contract for swap
        inputToken.transferFrom(msg.sender,address(this),swap);

        // calculating fees = (output-swap/2) / (total balance) * 0.1%
        uint fee = calculateFees(address(outputToken),swap);

        //tokens - fees being sent back to msg.sender for swap 
        swap = swap.sub(fee);
        outputToken.transfer(msg.sender,swap);
    }

    //function that exchanges function to exchange BUSD into USDC
    function swap13(uint256 swap) public payable minSwap(swap) {

        swap = swap.mul(10**18); //adjusts the swap into decimals
        IERC20 inputToken = IERC20(0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2); //BUSD
        IERC20 outputToken = IERC20(0x007F9dAE9B6D099961F39A897e298B8D631BDcd0); //USDC
        //checks to see if there is enough of USDT in contract
        uint256 outputTokenBalance = outputToken.balanceOf(address(this));
        require(swap <= outputTokenBalance, "Insufficient liquidity!");

        //taking tokens from msg.sender into contract for swap
        inputToken.transferFrom(msg.sender,address(this),swap);

        // calculating fees = (output-swap/2) / (total balance) * 0.1%
        uint fee = calculateFees(address(outputToken),swap);

        //tokens - fees being sent back to msg.sender for swap 
        swap = swap.sub(fee);
        outputToken.transfer(msg.sender,swap);
    }

    //function that exchanges function to exchange USDT into BUSD
    function swap21(uint256 swap) public payable minSwap(swap) {

        swap = swap.mul(10**18); //adjusts the swap into decimals
        IERC20 inputToken = IERC20(0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0); //USDT
        IERC20 outputToken = IERC20(0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2); //BUSD
        //checks to see if there is enough of USDT in contract
        uint256 outputTokenBalance = outputToken.balanceOf(address(this));
        require(swap <= outputTokenBalance, "Insufficient liquidity!");

        //taking tokens from msg.sender into contract for swap
        inputToken.transferFrom(msg.sender,address(this),swap);

        // calculating fees = (output-swap/2) / (total balance) * 0.1%
        uint fee = calculateFees(address(outputToken),swap);

        //tokens - fees being sent back to msg.sender for swap 
        swap = swap.sub(fee);
        outputToken.transfer(msg.sender,swap);
    }

    //swaps USDT into USDC
    function swap23(uint256 swap) public payable minSwap(swap) {

        swap = swap.mul(10**18); //adjusts the swap into decimals
        IERC20 inputToken = IERC20(0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0); //USDT
        IERC20 outputToken = IERC20(0x007F9dAE9B6D099961F39A897e298B8D631BDcd0); //USDC
        //checks to see if there is enough of USDT in contract
        uint256 outputTokenBalance = outputToken.balanceOf(address(this));
        require(swap <= outputTokenBalance, "Insufficient liquidity!");

        //taking tokens from msg.sender into contract for swap
        inputToken.transferFrom(msg.sender,address(this),swap);

        // calculating fees = (output-swap/2) / (total balance) * 0.1%
        uint fee = calculateFees(address(outputToken),swap);

        //tokens - fees being sent back to msg.sender for swap 
        swap = swap.sub(fee);
        outputToken.transfer(msg.sender,swap);
    }

    //swaps USDC into BUSD
    function swap31(uint256 swap) public payable minSwap(swap) {

        swap = swap.mul(10**18); //adjusts the swap into decimals
        IERC20 inputToken = IERC20(0x007F9dAE9B6D099961F39A897e298B8D631BDcd0); //USDC
        IERC20 outputToken = IERC20(0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2); //BUSD
        //checks to see if there is enough of USDT in contract
        uint256 outputTokenBalance = outputToken.balanceOf(address(this));
        require(swap <= outputTokenBalance, "Insufficient liquidity!");

        //taking tokens from msg.sender into contract for swap
        inputToken.transferFrom(msg.sender,address(this),swap);

        // calculating fees = (output-swap/2) / (total balance) * 0.1%
        uint fee = calculateFees(address(outputToken),swap);

        //tokens - fees being sent back to msg.sender for swap 
        swap = swap.sub(fee);
        outputToken.transfer(msg.sender,swap);
    }

    //swaps USDC into USDT
    function swap32(uint256 swap) public payable minSwap(swap) {

        swap = swap.mul(10**18); //adjusts the swap into decimals
        IERC20 inputToken = IERC20(0x007F9dAE9B6D099961F39A897e298B8D631BDcd0); //USDC
        IERC20 outputToken = IERC20(0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0); //USDT
        //checks to see if there is enough of USDT in contract
        uint256 outputTokenBalance = outputToken.balanceOf(address(this));
        require(swap <= outputTokenBalance, "Insufficient liquidity!");

        //taking tokens from msg.sender into contract for swap
        inputToken.transferFrom(msg.sender,address(this),swap);

        // calculating fees = (output-swap/2) / (total balance) * 0.1%
        uint fee = calculateFees(address(outputToken),swap);

        //tokens - fees being sent back to msg.sender for swap 
        swap = swap.sub(fee);
        outputToken.transfer(msg.sender,swap);
    }

    //functions to check balance of each coin
    function BUSDbal() public view returns(uint){
        IERC20 coin1 = IERC20(0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2);
        return coin1.balanceOf(address(this));
    }

    function USDTbal() public view returns(uint){
        IERC20 coin1 = IERC20(0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0);
        return coin1.balanceOf(address(this));
    }

    function USDCbal() public view returns(uint){
        IERC20 coin1 = IERC20(0x007F9dAE9B6D099961F39A897e298B8D631BDcd0);
        return coin1.balanceOf(address(this));
    }

    //function to check balance of all coins combined
    function totalBalance() public view returns(uint){
        
        IERC20 BUSD = IERC20(0x6Eb713eA34C034d18a82B884A5deD76fb4038fd2);
        IERC20 USDT = IERC20(0x808AA85F04e8728644Adc2A4D3C46C3c948b70E0);
        IERC20 USDC = IERC20(0x007F9dAE9B6D099961F39A897e298B8D631BDcd0);
        
        uint BUSDbal = BUSD.balanceOf(address(this));
        uint USDTbal = USDT.balanceOf(address(this));
        uint USDCbal = USDC.balanceOf(address(this));

        uint totalBal = BUSDbal.add(USDTbal.add(USDCbal));

        return totalBal;
    }

    


}