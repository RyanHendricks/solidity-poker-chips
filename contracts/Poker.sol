pragma solidity ^0.5.0;



/**
 * @title Poker
 * @author RH ryanhendricks@gmail.com
 * @dev This contract allows for tracking of player balances for poker games
 * @dev Since the money is not on chain this contract is not entirely trustless
 * @dev However it does provide an immutable record of each player's stats and rankings
 */
contract Poker {

    struct PokerGame {
        bool started;                                   /// has the game started
        bool ended;                                     /// has the game ended
        uint256 totalBuyIns;                            /// total of all buy ins
        uint256 totalCashOuts;                          /// total of all cash outs
        uint256 totalBalance;                           /// total amount in play (buyins minus cashouts)
        mapping(address => uint256) playerTotalBalance; /// balance of each player
        mapping(address => uint256) playerBuyIns;       /// buy in total for each player
        mapping(address => uint256) playerCashOuts;     /// cash out total for each player
    }
    
    
    struct PokerPlayer {
        uint256 playerTotalBalance;                     /// balance of player if player is in the positive
        uint256 playerTotalOwed;                        /// negative balance of player if in the negative
        uint256 playerTotalBuyIns;                      /// total of all buyins made by the player for all games
        uint256 playerTotalCashOuts;                    /// total of all cashouts made by the player for all games
    }

    /// mapping if player has registered in the contract via bool mapped to address
    mapping(address => bool) public isPlayer;
    
    /// mapping PokerPlayer to their address
    mapping(address => PokerPlayer) public playerStats;
    
    /// array of gameHistory
    PokerGame[] public gameHistory;
    
    /// array of PokerPlayers
    PokerPlayer[] public PokerPlayers;
    
    /// current game in progress
    bool public gameInProgress;
    
    /// struct with state of current game
    PokerGame public currentGame;

    /// constructor setting game in progress to false
    constructor () public {
        gameInProgress = false;
    }

    
    /**
     * @dev newPlayer adds a new player to the contract
     * @param _newPlayer address of the new Union Poker Player
     */
    function newPlayer(address _newPlayer) public {
        require(isPlayer[_newPlayer] == false, "player not new");   /// make sure player is new
        
        /// create a new player struct
        PokerPlayer memory player;
        
        /// set balances to 0
        player.playerTotalBalance = 0;
        player.playerTotalOwed = 0;
        player.playerTotalBuyIns = 0;
        player.playerTotalCashOuts = 0;
        
        /// register the player
        isPlayer[_newPlayer] = true;
        
        /// push player struct to the PokerPlayers array
        PokerPlayers.push(player);
        
        /// map the player stat struct to the new player's address
        playerStats[_newPlayer] = player;
    }


    /**
     * @dev newPokerGame creates and starts a new poker game
     * @dev can only be started if no game in progress
     * @dev can be started by anyone but only registered players can buy in
     */
    function newPokerGame() public {
        /// ensure no game currently in progress
        require(gameInProgress == false, "game in progress");
        
        /// create a blank game struct and set state variables
        PokerGame memory newGame;
        newGame.started = true;
        newGame.ended = false;
        newGame.totalBuyIns = 0;
        newGame.totalCashOuts = 0;
        newGame.totalBalance = 0;
    
        /// set game as current game and gameinprogress to true
        currentGame = newGame;
        gameInProgress = true;
    }


    /**
     * @dev buyIn allows a registered player to buy in to the current game
     * @param _amount uint256 buy in amount
     */
    function buyIn(uint256 _amount) public {
        /// require game in progress
        require(gameInProgress == true, "create a game first");

        /// require player is registered player before allowing buy in
        require(isPlayer[msg.sender] == true, "not a registered player");

        /// increase total buy in amount for current game
        currentGame.totalBuyIns += _amount;

        /// increase total balance for current game
        currentGame.totalBalance += _amount;
        
        /// increase player total balance and total buyins for current game
        currentGame.playerTotalBalance[msg.sender] += _amount;
        currentGame.playerBuyIns[msg.sender] += _amount;
    
        /// increase player total balance and total buyins for overall stats
        playerStats[msg.sender].playerTotalOwed += _amount;
        playerStats[msg.sender].playerTotalBuyIns  += _amount;

        /// rebalance player funds
        rebalancePlayerFunds(msg.sender);
    }
    
    
    
    /**
     * @dev cashOut allows player to cash out
     * @param _amount uint256 amount to cash out
     */
    function cashOut(uint256 _amount) public {

        /// assign game totals to variables
        uint256 deposits = currentGame.totalBuyIns;
        uint256 withdraws = currentGame.totalCashOuts;
        uint256 gameBalance = currentGame.totalBalance;
        
        /// check for erroneous game balance
        require(gameBalance == (deposits - withdraws), "error");

        /// prevent excess withdraw amounts
        require((_amount <= deposits + withdraws) && (_amount <= gameBalance), "error");

        /// add cash out amount to total cash outs for current game
        currentGame.totalCashOuts += _amount;

        /// subtract cash out amount from game total balance.
        /// negative results would already have reverted based on above require.
        currentGame.totalBalance -= _amount;

        /// subtract cash out amount from current game total balance for player
        currentGame.playerTotalBalance[msg.sender] -= _amount;

        /// add cash out amount to total game cash outs for player
        currentGame.playerCashOuts[msg.sender] += _amount;
        
        /// add cashout amount to total balance and total cashouts for player overall stats
        playerStats[msg.sender].playerTotalBalance += _amount;
        playerStats[msg.sender].playerTotalCashOuts  += _amount;
        
        /// rebalance player funds
        rebalancePlayerFunds(msg.sender);
        
        /// if no more cash to withdraw from game ie balance is zero then end game
        if (currentGame.totalBalance == 0 && currentGame.totalCashOuts == currentGame.totalBuyIns) {
            gameInProgress = false;
            currentGame.ended = true;
            gameHistory.push(currentGame);
        }

    }

     /**
     * @dev rebalancePlayerFunds reconciles player balance vs player owed amount
     * @dev this function is called internally following a buy in or cash out
     * @param _player address of the player
     */
    function rebalancePlayerFunds(address _player) internal {
        if(playerStats[_player].playerTotalBalance >= playerStats[_player].playerTotalOwed) {
            playerStats[_player].playerTotalBalance -= playerStats[_player].playerTotalOwed;
            playerStats[_player].playerTotalOwed = 0;
        } else {
            playerStats[_player].playerTotalOwed -= playerStats[_player].playerTotalBalance;
            playerStats[_player].playerTotalBalance = 0;
        }
    }


    function playerCurrentGameStats() public view returns(uint256, uint256, uint256) {
        return(currentGame.playerTotalBalance[msg.sender], currentGame.playerCashOuts[msg.sender], currentGame.playerBuyIns[msg.sender]);
    }
}
