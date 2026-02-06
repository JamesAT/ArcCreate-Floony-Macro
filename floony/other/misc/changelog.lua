require 'floony.lib.macroUtil'
require 'floony.lib.utils'

FolderNew('floony', 'floony.changelog', 'e873', '- Changelog -')

local function formatText(text)
    -- Replace **text** with <b>text</b> - BOLD
    text = text:gsub("%*%*(.-)%*%*", "<b>%1</b>")    
    -- Replace ~~text~~ with <s>text</s> - STRIKETHROUGH
    text = text:gsub("%~%~(.-)%~%~", "<s>%1</s>")
    -- Replace `text` with <u>text</u> - UNDERLINE
    text = text:gsub("`([^`]+)`", "<u>%1</u>")   
    -- Replace _text_ with <i>text</i> - ITALICS
    text = text:gsub("%_([^%_]+)%_", "<i>%1</i>")   
    -- Replace *text* with <size=75%>text</size> - SMALL TEXT
    text = text:gsub("%*(.-)%*", "<size=75%%>%1</size>")    
    -- Replace #text# with <size=115%>text</size> - BIG TEXT
    text = text:gsub("#(.-)#", "<size=115%%>%1</size>")
    return text
end

local function addChangelog(version, release, description)
    MacroNewNOCMD(
        "floony.changelog", "floony.changelog." .. version:gsub("%s+", ""), version, "e5df",
        function()
            local infoField = DialogField.create("Info")
                .description(formatText("Version: " .. version .. " " .. "*_(" .. release .. ")_*"))
            local msgField = DialogField.create(version)
                .description(formatText(description))
            local dialogInput = DialogInput.withTitle("What's New?")
                .requestInput(
                    {
                        infoField,
                        msgField,
                    }
                )
            coroutine.yield()
        end
    )
end

-- Tricks for description bugs (Text cut off), use spaces to stretch out the description, lmao.
addChangelog(
    "6.9.8", "???, 2025", 
    [[
#> Adjustment / Improvement# <size=90%>
- `Random Selection` is now select based on TG selected.
- nothing much, just changed the internal coding stuff.
- Modified `Arc Rain` to use a 2-point selection. I realized that picking two diagonal points covers the same X/Y range as picking four separate bounds, so I've simplified the workflow.
#> Addition# <size=90%>
- Added `Range Select Area` under Selection category, although it only select arcs (for now)
- Added `Notes Trail` under Special Category (wow there are so many special macro huh), to replicate that motion blur effect on notes (refer to 0thElement Hecatoncheir)
</size>



]]
)


addChangelog(
    "6.9.7", "November 22, 2025", 
    [[
#> Adjustment / Improvement# <size=90%>
- Added arrow icon on the `Shift ArcPos` to increase clarity
- The `Snap to Start Timing` has been revised and renamed to `Split & Snap Start Arcs`, where it now splits the arcs based on density and then snaps to the first selected arcs.
- In the `Arcs Segmentation` category, you can now select and split multiple arcs at once.
- Added `Timing Duration` under Special category. This is useful in SceneControl to quickly determine the duration without manually calculating it.
- Reword vague parameters (mostly labelling / dialogField) to clearly describe their function.
 </size>
#> Addition# <size=90%>
- Added `Random Selection` under Selection category, perfect if you want to assign different tg timing to create that parallax-ish effect.
</size>
#> WIP# <size=90%>
- Added a manual category with explanations and usage instructions for every macro (only for few macro, others coming up soon...?). NOTE TO MYSELF: Rephrase the whole things, so it won't look like I just type a prompt onto chatGPT and just copy and paste it without any modification.
</size>




]]
)

addChangelog(
    "6.9.6a", "May 14, 2025", 
    [[
#> Addition# <size=90%>
- Added `Camera to Arc` as opposition of `Arc to Camera` the function is self-explanitory, it uses for well... snapping thingy (for my use case), free camera can't help you snap stuff, especially on the middle.
- Added an `Accumulate Segment` to `Progress Length` for those with multiple charted segments who want to see the cumulative total. (yes, this was made for the event, but I'm kinda lazy to implement it-) [] IN WIP (doesn't exists yet)
</size>
#> Adjustment / Improvement# <size=90%>
- Removed `Persistent` on Gradual Timing, I don't think it has any uses in that, in fact, it annoys the frick out of me using it when going on between session.
- `Repeat Events` uses the current timing group by default now. Enable `All Groups` to include all timing groups in that area. Also have custom start timing I suppose.
- Fixed a bug in `Density / Progress` where 0% completion caused issues (I just make it a warning lol)
</size>






]]
)

addChangelog(
    "6.9.5", "January 20, 2025", 
    [[
#> Addition# <size=90%>
- Added `Spiral Trace` on Special Category, based on rech "Arghena intro spiral trace generator", but with more customizable setting like postion, start/end timing, etc
- Did I accidentally deleted `Offset by BPM` macro...? Welp... I... uh added it back. Either way, idk if this has any use at all, because this is inaccurate.
</size>
#> Adjustment / Improvement# <size=90%>
- Improve `Repeat` macaro but first... it changed its name to `Events Repeat` idk, it functions like copy-paste but can grab **Scenecontrol and Timing**, also; I added **Arctap** support. So it's not that useless anymore, yippee.
</size>
#> Bug Fix# <size=90%>
- I think when working on 6.9.48, I accidentally reversed the version of `Effects / Gimmick`... oops, well this fixes that. Man-
</size>




]]
)

addChangelog(
    "6.9.48", "January 9, 2025", 
    [[
#> Adjustment / Improvement# <size=90%>
- Made some adjustments on `Progress Length` macro.
- Added more, if not all, available easing on `Gradual` and `Bounce` from timing category.
  Special thanks to **Exiatist** for contributing to it!
</size>
]]
)


addChangelog(
    "6.9.47", "January 5, 2025", 
    [[
#> Adjustment / Improvement# <size=90%>
- Added Arctap support on `Notes to Shadow`
- idk why I somehow deleted the length / duration progress macro, but it's here now... and improved!
</size>
]]
)

addChangelog(
    "6.9.45", "January 4, 2025", 
    [[
#> Addition# <size=90%>
- Added `Line` and `Point` on Arcs Segmentation, they provide no combo (aka 0ms arcs) but they are interesting effect to mess with.
- Added `Stream Placement` feature on Special; creates 0ms arcs on each note to indicate which finger should be used. However, it may be inaccurate when handling taps and skynotes simultaneously.
- Added `Notes to Shadow` feature on Special; which creates shadow notes and positions them at the very top. It also creates a new timing group with 'noinput' and similar settings.
</size>
#> Adjustment / Improvement# <size=90%>
- `Teleport` on Timing has a overshoots tolerance of 17ms, so even if the EndTiming of one event overshot the StartTiming of the next, they will still be treated as a single seamless teleport.
</size>




]]
)

addChangelog(
    "6.9.4", "November 20, 2024", 
    [[
#> Addition# <size=90%>
- Added a `Moderate` option to `Shift ArcPos`, which shifts the arc position by 0.25.
- Added an option to `Set Stop BPM` under the `[Pause]` menu, allowing to set a value other than the default 0.01.
</size>
#> Adjustment / Improvement# <size=90%>
- Cleaned up and organized the Lua code for better readability and easier navigation.
- Fixed an issue where `Shift ArcPos` was undoing individual arcs.
- Improved the `Cut on Timing`: it now supports cutting multiple selected notes at once, and without conflicting with any attached SkyTaps.
- Improved the `Glitch Timing`; now it's more jittery and organized a bit. I realize a bit of random chaos isn't noticeable, and it looks ugly.
</size>



]]
)

addChangelog(
    "6.9.3", "October 12, 2024", 
    [[
#> Addition# <size=90%>
- Added Select Current TG Notes to range select notes within the currently selected timing group.
- Added `Hold to Groupalpha` since everyone likes to use them on ACC6 :hearteyes:
</size>
#> Adjustment / Improvement# <size=90%>
- Copy Timing Group now copies the selected timing group (why I didn't thought of using Context.currentTimingGroup earlier-)
- I don't know what I changed so far.
</size>
]]
)

addChangelog(
    "6.9.25", "August 9, 2024", 
    [[
#> Adjustment / Improvement# <size=90%>
- Changed most of dialog popups to notifications to make them less distracting.
- Macro Command now includes the parent ID as well.
- Added `Persistent` class to some of the settings so they remain consistent across sessions.
- All macros that require selected notes will now return false and display a warn notify if no notes are selected.
- `Tap to Hidegroup` affects the currently selected timing group.
- Fake notes stats have been included in the `Chart Information`
</size>
#> Bug Fix# <size=90%>
- Fix the issue where executing the `Split > Normal` macro runs the `Arc Rain > Normal` macro instead (id issue).
</size>
]]
)

addChangelog(
    "6.9.22", "August 4, 2024", 
    [[
**The "sort of" biggest update since 0th finally release ArcCreate v1.2 after... idk how long lol**

#> Major Changes# <size=90%>
- Rewrite / Updated most of macros using New APIs. ArcCreate v1.2 or later is required for them to function properly.
- i̸d̵k̴ ̶w̶h̴a̷t̸ ̴i̸ ̷c̵h̶a̵n̷g̸e̷d̵,̵ ̴h̸e̸l̶p̴
</size>
#> Addition# <size=90%>
- New categories: `The funny`. A silly macro doing their job.
- Re:added `Changelog` yay.
</size>
#> Removal# <size=90%>
- Deprecated `Clean 0ms` because it's kinda difficult to improve it.
</size>
#> Adjustment / Improvement# <size=90%>
- Better Naming / Icon Convention
- `Camera > Repeat` will now repeat the camera based on the current selected timing group.
- `Tap to Hidegroup` sequence can be reversed, allowing you to unhide the group first.
- Cancel the `Camera bounce or flick` if no position or rotation is selected.
- Improve `Chart Information` and `Chart Progress` which is changed into `Density / Progress` (Thanks zeroth.element for the original code <3)
- `Arcs Segmentation` can modify both `void / trace arcs`, without checking the errors.
</size>
#> TO:DO# <size=90%>
- Pattern Switcher - Special
- Fake note stats in `Chart Information`
</size>




]]
)

addChangelog(
    "6.1.25", "April 19, 2024",
    [[
I somehow accidentally released a rough version :skull:

#> Removal# <size=90%>
- Temporary Deprecated `Changelog` as there's a bug with the description. I probably bring it up again in the future.
</size>
#> Adjustment / Improvement# <size=90%>
- Doing some cleaning *(name, moving stuff, etc)*
- `Convert to Trace` is now named `Notes to Trace` and moved to Special Category
- `Timing Stash` moved to Special Category
- Change Skynote/ArcTap name to `SkyTap`
</size>
]]
)

addChangelog(
    "6.1.2", "Arpil 14, 2024",
    [[
#> Addition# <size=90%>
- Added `Modification > Curve Alignment` that select split arcs and shifts them to align with the timing of the first arc, forming a curved trace art. ~~can be use for abstruse dilemma slam~~
- Added `Changelog` which is this... lol.
- `Camera > Bounce` is now includes the inverse ease option (instead of [qo, qi], it's now [qi, qo])
</size>
#> Adjustment / Improvement# <size=90%>
- `Timing > Glitch` is now more consistent and improved, but this means lax of the randomness (can be adjusted), but at least it's more like a glitch than random movement that doesn't make sense.
- Further improve `Chart Information` by including fake notes, divider, since base group is considered 0 so... oh, and name changes.
- Modified and separated `Arc Rain` into two categories: Normal and `Tunnel` *(Found in Callima Karma Trace Gimmick)*.
</size>
> Few changes




]]
)

addChangelog(
    "6.0 (Alpha)", "February 17, 2024",
    [[
_Finally i can be free from this-_

#> Arcs segmentation *(wow I finally understand this code)*# <size=90%>
- Various Changes has been made. (Naming, Setting, etc)
- Added `Square Wave` arcs. (thanks to rech for the original code)
- Added `Reverse Ran` because why not.
- Separate `Amygdata` into `Normal` and `Amygdata`, it will bypassed `Force Lines option` on `Setting` but I still keeping that option in case for other arc types.
- Modify the `Stasis Arc` option into dropdown menu - Disable, None, Add Void / Trace. *(pls fix dropdown bug)*
</size>
#> Effects / Gimmick# <size=90%>
- Enhancements to Arc Rain:
	- Added `Intensity`
	- Fixed `Add Arctaps` where it would go outside of its parent arc boundaries causing error.
</size>
#> Special# <size=90%>
- Added `Arc To Camera` on `Camera` Category. (Special thanks for recharge-sp for the original arc2cam)
- There is now an `Information/Help` under the `Special` Category (Similar to the zero macro help), ~~it will take a long time for it on every category~~
</size>
#> Information# <size=90%>
- Improved `Chart Progress`
</size>
#> Create Elements# <size=90%>
- Added `Appearing Arctap` *(Thinker with it, I don't know how to describe it)* ~~It's something I want to make a long time ago but unable to, until now~~
- Added `Create Sturdy` that duplicates traces to make them more noticeable.
- Added `Setting` and `Downward` on `Copy Arc`
- Place 'Fake Arctap' in the 'Convert to Traces' category along with the other notes. (thanks to tar1412 for the original code)
</size>
#> Modify Elements# <size=90%>
- Added `Cut on Timing`... Yeah I copied the code from zero macro and paste it here :skull:
- Added `Arc Connect` that connect the first arc to the second one. (thanks to tar1412 for the original code)
- Added `Both` option on `Snap Arc` that snaps end timing of the first arc and start timing of the second arc simultaneously.
</size>
> Various Changes & Fixes, *i forgor to keep track of it.*








]]
)

addChangelog(
    "5.9", "December 13, 2023",
    [[
#> Special Element# <size=90%>
- Include all potential movements under `Camera`, categorized into two types: position and rotation. Additionally, combinations of these movements are possible.
- Added `Duplicate Timing Group` that creates a new timing group containing all timing events from Base Group
- Introduced `Positive (+)` and `Negative (-)` signs for `Camera` movement to indicate their effects on movements. This may be incorrect so let me know.
</size>
#> Create Elements# <size=90%>
- Timing events within `Repeat` are now automatically included by default.
</size>
#> Effects / Gimmick# <size=90%>
- Set default values based on the last user input for `Timing > Smooth`.
- Modified `Timing > Teleport` to use the selected long notes for execution. Also, fixed the bpm drift issue (?) by excluding normal bpm and only applying it to the last selected notes to ensure a proper teleportation.
- Categorized `Sudden` into `Timing + 1 (After)` and `Timing - 1 (Before)`. Be careful, as using too much on `After` might lead to a drifting BPM. Remember to add timing event to its proper timing before spamming `After` to account for this change.
</size>
*_(There's probably more, idk, I accidentally delete the changelog three times)_*

> Known Bugs
- Have yet to discover *~~I'm just lazy~~*







]]
)

addChangelog(
    "5.8 (Beta)", "November 16, 2023",
    [[
*(omg beta version!!11!11!)*

- Special Element
	- Fixed the mirror `Camera: Repeat` to only mirror the X (and rotZ) movement, if you want the y too inform me.
	- Added `Zrotation (Left / Right)` option on `Camera > Flick`
	- Added `Camera Stash`
	
- Create Elements
	- Improved `Repeat` to include timing events and option to alternating selected events
	- Added `Beatline` because apparently I needed it

Known Bugs: 
- Using `Timing > Teleport` on bunch of hold notes can potentially cause the bpm to drift
- The `Altenating` option on `Camera > Flick/Bounce` may not applied correctly when more than 3 hold notes were selected
]]
)

addChangelog(
    "5.75", "September 8, 2023",
    [[
- Added `Camera: Repeat`, same like `Repeat` but for Camera, also included Mirror and Alternating option ~~yeah abuse this~~
- Added `Chart Progress` (Does not account for multiple section charting, idk how to implement that)
- Minor bug fix as always ~~(I'm just changing the integer to float on `Intensity` textField)~~
]]
)

addChangelog(
    "5.7", "September 6, 2023",
    [[
- The Interface looks clean now with clear indication of category, subfolder, etc
- Arc Segmentation `Setting: Followed by 2nd Trace` has been renamed with `Stasis arc` and no, I can't make dedicated one, use rech macro for it

- Special Category:
	- Make the way of selecting in `Camera: Bounce` the same way as `Camera: Flash`
	- Added `Camera: Blank` which add empty camera but with duration of the hold

- Improved `Chart Information`
- Minor bug fix
]]
)

addChangelog(
    "5.3", "August 23, 2023",
    [[
- Revise the macro originally intended for ArcadeZero to be suitable for ArcCreate instead.
- Also I don't know what changes
]]
)

addChangelog(
    "2.0.3", "June 22, 2023",
    [[
**Ultimate Macros, probably (For Ade0 v4)**
(Combined with few macros from 3.0 and some new macros from ArcCreate)

- ???
- oh, and if you're seeing this, well... yeah there's more, but it's only maintained by floofer++ 
_unfortunately, I can't access them._
]]
)