# Hardcore Unlocked (HCU)
A modification of the Hardcore addon which allows for custom (or no) rulesets.  This addon aims to improve performance and user experience by removing verification and other memory/cpu intensive features from the original Hardcore addon.  In lieu of verification features, this variant focuses on providing guard rails for a custom challenge and displays your ruleset to others. This addon will __not__ qualify you for the online leaderboard, and players using the original HC addon may not group with you or allow you in their guild. This addon includes faction-wide or guid death alerts, the deathlog, and achievements in addition to the custom ruleset.

## Roadmap
- 0.0.1b1 Removed verification features, allow for custom rulesets, guild mandated rulesets
- 0.0.1b2 Strip down databases.  They are currently very large and we now have the data to get what we need with 10% of the dbs
- 0.0.1b3 Share hyperlink rulesets; rulesets in character inspect
- 0.0.1 Official server release (1.14.4)
- 0.0.1+ Bug fixes for current acheivements.  Updated UI and customizations. Some additional fonts. Max level toast alert (guild and faction-wide), rulesets integrated into deathlog, rulesets integrated into character history, data recovery via screenshots.Add minimalism mode: turns off achievement tracking, deathlog recording (alerts will still work); Chat hyperlinks for rulesets

## Motivation and Demographic
- Enable players who do not want to follow the Solo-Self Found ruleset, to enjoy the Hardcore Addon features (Achievements, Death Alerts, Death log)
- Enable players to craft their own ruleset.  Players can activate their preferred ruleset from a collection of rules found in the main menu.
- Enable guilds to enforce their own ruleset.  Guilds can use officer notes to create a guild-wide ruleset.  Players in a guild with a guild-wide ruleset will have their addons automatically enable the rules in the guild-wide ruleset.
- Enable players who hit level 60 to follow their elite guild's ruleset.
- Players that prefer a minimal version of the HC addon
- Players who dislike the verification featues in the HC addon


## Features

### Customizeable Ruleset
**Using rulesets is optional!!!** Mix and match rules to cater to your Hardcore journey.  Join guilds with guild-wide rulesets to automatically participate.  Rulesets are integrated into character inspection frames. Rulesets can be hyperlinked through chat.  Future plans to integrate rulesets into the deathlog, so you can view what rules other players were following when they died.

### Guild Mandated Rulesets
Officers: Copy achievement code specified by `officer code` in the main menu in the guild information.  Players with this addon will automatically be assigned the matching ruleset.

### Inspect Ruleset
Inspect to see a characters ruleset ![ruleset](git_images/inspecthcu.png)

### Link Ruleset
Clicking a ruleset hyperlink shows ![ruleset](git_images/itemrefhcu.png)

### Level 60 toast
New level 60s in the guild will now alert with ![ruleset](git_images/level60toast.png)

### Removed Verification Components
Rules in this addon function as guiderails and there is no "Failure" that can be appealed.  For example, the `No Auction House` rule will close the auction house if you attempt to open interact with the auctioneer, as opposed to applying a `failed` status to your character.  Security related warning text, verification tab, and verification status via inspection have been removed.  Since this is a self-imposed challenge, this addon makes no effort to detect cheating. Instead it provides a framework for communities to use rulesets (if they want), and aims to optimize for performance and user experience.

## Instructions
### Import from the Hardcore Addon
You can import character information from the Hardcore addon to HardcoreUnlocked (but not the other way around).  In order to do this, you need to have both addons running at the same time.  Upon login you should see a message saying that both addon version are detected.  You can type `/hcu ImportFromHCU` in order to import your character data.  Upon entering that command, you should see a messaage saying that the import was successful.  If you see a message saying that the Hardcore Addon was not detected, make sure that both addons are running.  **NOTE** Make sure to turn off the Hardcore addon after importing.

## Contributions

Please reachout to Yazpad (discord: lakai.#2409) to request additional rules/features/suggestions.  Feel free to copy or distribute (GNU GPLv3).  Feel free to make pull requests on github.
