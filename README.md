# MysticMaestro
Auction house automation addon for mystic enchants

To-Do List
- [ ] Ways to count the trinkets owned/posted
  - [x] Count the number of trinkets in inventory of each RE
  - [ ] Count how many of any given RE that has been posted on the AH.
- [ ] New interface elements for when the AH is opened
  - [ ] List of all enchants player has posted
  - [ ] List of selected RE auctions
  - [ ] Buttons for Scan function
- [ ] Methods for posting to the AH
  - [ ] Need to fix the seller name data
  - [ ] Helper functions for considering the post price
- [ ] Settings menu GUI
  - [ ] scan options
  - [ ] post options


Completed Goals
- [x] First we need methods for doing our scan
- [x] Evaluation of the auction results
  - [x] methods for compiling daily averages
  - [x] methods for compiling 10d
- [x] Algorythms for removing outliers
- [x] Methods for cleaning up old scan data
  - [x] both listings and stats
  - [x] method for cleaning over 10 day old entries in stats
  - [x] method for cleaning listings
- [x] Methods for creating the averages and min/max
  - [ ] ~~gathering listing data for non trinkets in ["other"]~~
  - [x] combined all listings into one value, which is normalized to remove outliers
- [x] UI elements for displaying the information
- [x] A way to sort the data into the most profitable based on value per orb
