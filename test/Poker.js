const PokerContract = artifacts.require('Poker.sol');


const BN = require('bignumber.js');

function toReadable(num) {
  return web3.utils.fromWei(num, 'ether');
}





contract('Poker', function(accounts) {

  // let DestOne, DestTwo, DestThree, DestFour, TTR, StakeTokenOne, StakeTokenTwo, StakeTokenThree, StakeTokenFour
  let UP, Poker, Player1, Player2, Player3, Player4, Player5, NotPlayer;

  beforeEach(async () => {
    UP = await PokerContract.new();
    Player1 = accounts[0];
    Player2 = accounts[1];
    Player3 = accounts[2];
    Player4 = accounts[3];
    Player5 = accounts[4];
    NotPlayer = accounts[5]
    await UP.newPlayer(Player1, { from: accounts[0] });
    await UP.newPlayer(Player2, { from: accounts[0] });
    await UP.newPlayer(Player3, { from: accounts[0] });
    await UP.newPlayer(Player4, { from: accounts[0] });
    await UP.newPlayer(Player5, { from: accounts[0] });
  });
  describe('Check post deployment state', async function() {
    it('Should return true for registered players',  async () => {
      let isPlayer = await UP.isPlayer(Player1);
      assert.equal(isPlayer, true);
      isPlayer = await UP.isPlayer(Player2);
      assert.equal(isPlayer, true);
      isPlayer = await UP.isPlayer(Player3);
      assert.equal(isPlayer, true);
      isPlayer = await UP.isPlayer(Player4);
      assert.equal(isPlayer, true);
      isPlayer = await UP.isPlayer(Player5);
      assert.equal(isPlayer, true);
      isNotPlayer = await UP.isPlayer(NotPlayer);
      assert.equal(isNotPlayer, false);
    });
    it('Should return false for gameInProgress',  async () => {
      assert.equal(false, await UP.gameInProgress());
    });
    it('Should revert if newplayer is already a player',  async () => {
      try {
        await UP.newPlayer(Player2, { from: accounts[0] });
        assert.fail('failed');
      } catch(e) {
        // console.log(e);
        if (e.message.search('revert') >= 0) {
          assert('reverted');
        };
      }
    });
  });
// TO BE CONTINUED
});
