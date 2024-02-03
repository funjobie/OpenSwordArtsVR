# Game Design document

# Classes

X (Viper): Melee class with two swords. Gameplay is a more intense beat-saber style with hit blocks moving towards you. is mobile.
might for example have an attack  where you with the thumbstick select the attack direction (aoe line indicator) and for enemies in between you get a few hits. after performing this move you are located at the other end of the room.
not sure if camera follows along directly or is teleported later, depends on motion sickness.

Monk: Melee class with fists. Gameplay is a kind of boxing style.

Bard: has to actually sing songs according to melodies (microphone integration)
Is a support class that gives buffs to players and debuffs to enemies.

Dancer: has to dance. maybe requires full body tracking?
Is a support class that gives buffs to players and debuffs to enemies.

Healer(white mage): gameplay is a more sailormoon-etc stick waving. but also CPR for people that are on the ground. has buffs and regends but few attacks.

Alchemist: can use a variety of potions, to heal, damage, buff etc. has an expanded potion inventory that are all pre-made so has to manage inventory more.
can also heal but would for example apply bandages.

archer: classic bow and arrow, using realistic controls and physics.

mage: classic mage. but controls not clear yet.




Also differerentiate the way of getting XP. possibly half-half (e.g. combat 50% and off-combat 50%. current level is min(combat,off-combat).
E.g. mage: studying tomes
Bard: perform
Warrior: combat, maybe duels in arena
Archer: hunting wildlife
Arrow mechanic, limit to ca 8 arrows in quiver, recall mechanics, arrows as customizable equipment


# Trade and housing

In games that enable trading, there are (at least) two categories:
 - some games hide trading away behind UIs, like the market board in FFXIV
 - same games let players choose where to setup trading, to some degree, but don't really ensure a clean city layout (e.g. ragnarok online)
Also, while some players may want to go deep into interior design, the vast majority just want to trade.
There is also the topic that player owned shops can have a tendendy to cause a dead-game impression as people over time get inactive and leave their claims behind.

In this design, players bid for market spaces. The bidding works as follows:
Until the end of the bidding phase, each player can bid for any kind of asset and put down any amount of in-game currency.
The money is locked and automatically returned if the player does not win the bid.
When the bidding phase ends, the highest bidder is informed and now has to commit. There can only be one commitment per category, so only one "trade" asset rented at a time.
The player has time until the commit phase ends to decide which one to take. 
Once the player has commited, the payment is due and the player bid is taken, however not the full amount but rather the amount of the second-highest bidder.
If the player does not commit then among their claims with hiddest bid invest, one is chosen at random.

The amount a player bids increases the chance of winning, but with a reduced impact.
the relative weight is equal to the log2 of the bid.
so a player bidding 1 coin has a weight of 1, but a player bidding 1000 has a weight of ~10.
This gives a realistic chance to win also for newcomers and casual players. It also acts as a money-sink.

certain kind of shops are locked to trading categories. This is done both from an astetic but also gameplay perspective:
 - a potion shop can be designed by the level designer with a lot of care, while a player from the outside can see its a potion shop and enter with certain expectations

The different shop and stall options are meant to target different kinds of players. Some players want to go deeper into the experience of trading, while others might just want to cash in 1-2 items.

The custom shop in particular allow the player to setup the store layout however they want (with limits of course).
The details on this will need a lot of fine-tuning. But there are options from just being able to change a few settings to full "empty-room to full shop decoration" builds.

| Asset                | category | bidding phase | commit phase | rental duration | notes                                     | customizable |
| -------------------- | -------- | ------------- | ------------ | --------------- | ----------------------------------------- | ------------ |
| weapon shop          | trade    | 48h           | 24h          | 1h              | locked to trading weapons                 | no           |
| potion shop          | trade    | 48h           | 24h          | 1h              | locked to trading potions and ingredients | no           |
| armor shop           | trade    | 48h           | 24h          | 1h              | locked to trading armor                   | no           |
| pawn shop            | trade    | 48h           | 24h          | 1h              | locked to selling to the owner            | no           |
| general purpose shop | trade    | 48h           | 24h          | 1h              | no trade restrictions                     | no           |
| custom shop          | trade    | 7d            | 3d           | 7d              | no trade restrictions                     | yes          |
| small stall          | trade    | 24h           | 6h           | 30m             | no trade restrictions                     | no           |
| custom stall         | trade    | 3d            | 1d           | 2h              | no trade restrictions                     | yes          |
| open trade space     | trade    | 2h            | 1h           | 15m             | no trade restrictions                     | no           |

similar alternatives can be considered for player housing, as well as event squares.
housing would be e.g. pre-build houses, renting an apartment.
event can be an empty event square, renting a bar etc.