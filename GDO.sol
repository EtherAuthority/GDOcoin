pragma solidity 0.8.4; /*


___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_




 ██████╗ ██████╗  ██████╗      ██████╗ ██████╗ ██╗███╗   ██╗
██╔════╝ ██╔══██╗██╔═══██╗    ██╔════╝██╔═══██╗██║████╗  ██║
██║  ███╗██║  ██║██║   ██║    ██║     ██║   ██║██║██╔██╗ ██║
██║   ██║██║  ██║██║   ██║    ██║     ██║   ██║██║██║╚██╗██║
╚██████╔╝██████╔╝╚██████╔╝    ╚██████╗╚██████╔╝██║██║ ╚████║
 ╚═════╝ ╚═════╝  ╚═════╝      ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                            
                                                                                                                                                          

=== 'GDO Coin' Token contract with following features ===
    => Only GDO employees can buy the tokens.
    => Percentage of Profit will be shared to all the token holders.
    => Top tokens will be used, so risk will be alleviated, and value will rise in long term.
    => BEP20 Compliance
    => Mostly decentralized. Owner control only whitelisting for token purchase. Owner can not restrict token sale.
    => Burnable and minting only through incoming or outgoing of CONG tokens
    => user whitelisting. Only authorized wallet can buy tokens
    => in-built buy/sell functions 
    => Fund remains in the smart contract to ensure 100% liquidity of the tokens.


======================= Quick Stats ===================
    => Name             : GDO Coin
    => Symbol           : GDO
    => Initial supply   : 0
    => Decimals         : 18


============= Independant Audit of the code ============
    => Multiple Auditors of EtherAuthority
    
    
-------------------------------------------------------------------
 "SPDX-License-Identifier: MIT"
 Copyright (c) 2018 onwards GDO Inotech Pvt Ltd. ( https://GDO.co.in )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
*/ 



//*******************************************************************//
//------------------ Interfaces for external calls ------------------//
//*******************************************************************//

interface IpanCakeRouter{
    function getAmountsOut(uint amountIn, address[] memory path) external view returns(uint[] memory amounts);
}


interface IBEP20{
    function balanceOf(address user) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
}




//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = payable(0);
    }
}
 

    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract GDOcoin is owned {
    

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    string constant private _name = "GDO Coin";
    string constant private _symbol = "GDO";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply;
    address[] reserveTokens;
    address public panCakeRouter = 0x87bA9F94DB64C6a5d0221f73721Bb92008835E66;
    address public BUSDaddress = 0xc6876a7a89F193FcDE0d5E8259E724cCd41945d3;
    

    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public whitelisted;


    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);



    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/
    
    /**
     * Returns name of token 
     */
    function name() external pure returns(string memory){
        return _name;
    }
    
    /**
     * Returns symbol of token 
     */
    function symbol() external pure returns(string memory){
        return _symbol;
    }
    
    /**
     * Returns decimals of token 
     */
    function decimals() external pure returns(uint256){
        return _decimals;
    }
    
    /**
     * Returns totalSupply of token.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * Returns balance of token 
     */
    function balanceOf(address user) external view returns(uint256){
        return _balanceOf[user];
    }
    
    /**
     * Returns allowance of token 
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    

    /**
        * Transfer tokens
        *
        * Send `_value` tokens to `_to` from your account
        *
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        * Transfer tokens from other address
        *
        * Send `_value` tokens to `_to` in behalf of `_from`
        *
        * @param _from The address of the sender
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        * Set allowance for other address
        *
        * Allows `_spender` to spend no more than `_value` tokens in your behalf
        *
        * @param _spender The address authorized to spend
        * @param _value the max amount they can spend
        */
    function approve(address _spender, uint256 _value) external returns (bool success) {
        /* AUDITOR NOTE:
            Many dex and dapps pre-approve large amount of tokens to save gas for subsequent transaction. This is good use case.
            On flip-side, some malicious dapp, may pre-approve large amount and then drain all token balance from user.
            So following condition is kept in commented. It can be be kept that way or not based on client's consent.
        */
        //require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function increase_allowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender] + value;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function decrease_allowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender] - value;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    constructor(address[] memory tokens) {
        /*
            Reserve tokens would be following:
            
                WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
                BTC  = 0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c
                ETH  = 0x2170ed0880ac9a755fd29b2688956bd959f933f8
                TRX  = 0x85eac5ac2f758618dfa09bdbe0cf174e7d574d5b
                CAKE = 0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82
            
        */
        reserveTokens = tokens;
    }
    
    
    //It rejects all the incoming BNB. Instead, send WBNB
    //receive () external payable {}
    
    
    
    

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) external returns (bool success) {
        _burn(msg.sender, _value);
        return true;
    }

        
    
    function totalFundValueUSD() external view returns(uint256){
        uint256 totalReserveTokens = reserveTokens.length;
        uint256 totalValueUSD;
        
        
        for(uint256 i = 0; i < totalReserveTokens; i++){
            
            
            //first get token price in BUSD from panCakeSwap
            address[] memory path = new address[](2);
            path[0] = reserveTokens[i];
            path[1] = BUSDaddress;
            uint256[] memory tokenPrice = IpanCakeRouter(panCakeRouter).getAmountsOut(1111, path);
            
            
            //now check the token amount in the contract
            uint256 tokenBalance = IBEP20(reserveTokens[i]).balanceOf(address(this));
            
            
            //current USD value of the particular token in the smart contract
            uint256 usdValue = tokenBalance * tokenPrice[0];
            
            
            //this USD value of particular token will be incremented with other reserve tokens.
            totalValueUSD += usdValue;
        }
        
        //finally returning total USD value of all the reserve tokens in the contract
        return totalValueUSD;
    }
    
    
    
    function buyTokens(address tokenContract) external returns(uint256){
        
        require(whitelisted[msg.sender], 'Invalid caller');
    }

        
    
    //------------------------------------------------//
    //-------------- Inernal Functions ---------------//
    //------------------------------------------------//
    
    
    
    /**
     * Internal transfer, only can be called by this contract 
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from] - _value;    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to] + _value;        // Add the same to the recipient
        
        // emit Transfer event
        emit Transfer(_from, _to, _value);
    }
    
    
    
    /**
     * Internal burn function
     */
     function _burn(address user, uint256 value) internal {
        _balanceOf[user] = _balanceOf[user] - value;  // Subtract from the sender
        _totalSupply = _totalSupply - value;                      // Updates totalSupply
        emit Transfer(user, address(0), value);
     }
     
    
    /** 
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param target Address to receive the tokens
        * @param mintedAmount the amount of tokens it will receive
        */
    function _mint(address target, uint256 mintedAmount) internal {
        _balanceOf[target] = _balanceOf[target] + mintedAmount;
        _totalSupply = _totalSupply + mintedAmount;
        emit Transfer(address(0), target, mintedAmount);
    }
    
    
    
    
    
    //------------------------------------------------//
    //--------------- Admin Functions ----------------//
    //------------------------------------------------//
    
    /**
     * Whitelist any user address - only Owner can do this
     *
     * It will add user address in whitelisted mapping
     */
    function whitelistUser(address userAddress) onlyOwner external{
        whitelisted[userAddress] = true;
    }
    
    
    
    

    
    

}
