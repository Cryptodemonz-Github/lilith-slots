# CryptoDemonz, Slot machine

This game has 3 circular, independently operated reels. A series of 6 different symbols (1, 2, 3, 4, 5, 6) is put on each reel. The player places a certain amount of bet and starts the round. During the game, reels are spinning & spinning then they stop at a random symbol. There are a series of rules on which results payout and how much. Different combinations offer different payouts.

## The Ruleset
The real challenge of making this game is figuring out a ruleset that is psychologically attractive for players but profitable in the long term for us. By choosing various winning lines, reels and many symbols, defining a ruleset can be quite complex. I chose 3 reels to be simple in the beginning of the development. So this will be a solid foundation of the game which we can extend by adding more reels & rules.
In my approach, each reel contains 6 different symbols which means we have totally 6 x 6 x 6 = 216 combinations or ways. Each round has 1 winning line and the player can bet only a certain amount. This example uses 1 $LLTH as the fixed bet amount which we can adjust later by a multiplier that reflects the exchange rate.

 
| **Winning Combination**           | **Pays**                              | **Ways to Win**   | **Total Payout**  |                            |
| --------------------------------- | ------------------------------------- | ----------------- | ----------------- | -------------------------- |
| 6-6-6                             | 20                                    | 1                 | 20                |                            |
| 1-1-1, 2-2-2, 3-3-3, 4-4-4, 5-5-5 | 5                                     | 5                 | 25                |                            |
| 6-6-x, 6-x-6, x-6-6               | 4                                     | 15                | 60                |                            |
| 6-x-x, x-6-x, x-x-6               | 1                                     | 75                | 75                |                            |
|                                   | **Total Ways To Win:**                | 96                | 180               | **Total Payout**           |
|                                   | **Total Ways:**                       | 216               |                   |                            |
|                                   | **Hit Frequency:**                    | 44.44%            | 83.33%            | **RTP (Return to Player)** |
|                                   | **Avg. Spins until Win:**             | 2.27              |                   |                            |

**Winning Combination & Pays:** it lists each of the 3-symbol combinations, ways and its associated payout value. In case of 6-6-6, the player will get 20 $LLTH for that 1 $LLTH spent on this round.<br /><br />
**Hit Frequency:** it represents how often a player will win something from a play of the game.<br />
`(Total Ways to Win) / (Total Ways) = 96 / 216 = 44.44%`<br /><br />
**Avg. Spins until Win:** from Hit Frequency we can easily calculate on average how many spins it takes for the player to win something:<br /> `1 / (Hit Frequency) = 1 / 0.44 = 2.27`<br /><br />
**Return to Player (RTP):** the amount that a player can expect to win on any given spin.<br />
`(Total Payout) / (Total Ways) = 180 / 216 = 83.33%`<br /> <br /> 
In other words: if the player places 1 $LLTH bet, they will get back on average 0.8333 $LLTH.<br />
