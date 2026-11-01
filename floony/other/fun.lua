require "floony.lib.macroUtil"
require "floony.lib.utils"

------------------------------------\
-- // the funny :sparkles: // --    |
------------------------------------/
FolderNew('floony', 'floony.fun', 'ea65', '- The funny -')

-- // CHARTIFACT OF THE DAY // --
local lastQuoteIndex = nil
MacroNewNOCMD(
    "floony.fun", "floony.chartifact", 
    "Chartifact", "e244",
    function()
        local quotes = require("floony.other.misc.chartifacts")
        if not quotes or #quotes == 0 then
            notifyWarn("No chartifacts found in chartifacts.lua.")
            return
        end

        local showAnother = true

        while showAnother do
            local randomIndex = math.random(1, #quotes)
            if #quotes > 1 and randomIndex == lastQuoteIndex then
                randomIndex = (randomIndex % #quotes) + 1
            end
            lastQuoteIndex = randomIndex

            local quoteText = quotes[randomIndex]
            local titleText = string.format("Chartifact of the Day! [#%d/%d]", randomIndex, #quotes)

            local req = DialogInput.withTitle(titleText).requestInput({
                DialogField.create("quote")
                    .description(quoteText),

                DialogField.create("another")
                    .setLabel("Another One!")
                    .setTooltip("Tick this and hit Confirm to view another random Chartifact right away.")
                    .checkbox()
            })

            coroutine.yield()

            if not req or not req.result then break end

            local again = req.result["another"]
            showAnother = (again == true or tostring(again) == "true")
        end
    end,
    true
)

-- // RAINBOW // --
MacroNew(
    "floony.fun", "rainbow", 
    "Turn Rainbow", "e3fc",
    function(cmd)
        local arc = Request.arc("Select the start of the arc group that you want to turn into a rainbow.")

        local arcs = getFullArc(arc)
        local farcs = {}
        for _, a in ipairs(arcs) do
            arcSplit(a, cmd, farcs)
        end
        cycleColors(farcs, cmd)
    end
)

-- // CHAOTIC RANDOM NOTES // --
MacroNew(
    "floony.fun", "chaotic", 
    "Chaotic Notes", "e043",
    function(cmd)
        local tStart, tEnd = Request.timeRange()

        local dialogFields = {
            DialogField.create("intensity")
                .setLabel("Intensity")
                .setTooltip("How chaotic will it be?")
                .textField(FieldConstraint.create().integer())
                .defaultTo(1),
            DialogField.create("exclude")
                .description("Which Notes to Exclude?"),
            DialogField.create("tap")
                .setLabel("Tap")
                .checkbox(),
            DialogField.create("hold")
                .setLabel("Hold")
                .checkbox(),
            DialogField.create("arc")
                .setLabel("Arc")
                .checkbox(),
            DialogField.create("sky")
                .setLabel("SkyTap")
                .checkbox()
        }

        local dialogRequest = DialogInput.withTitle("Chaotic Notes").requestInput(dialogFields)
        coroutine.yield()
        
        local intensityVal = tonumber(dialogRequest.result["intensity"]) or 1
        local tapEX, holdEX, arcEX, skyEX = dialogRequest.result["tap"], dialogRequest.result["hold"], dialogRequest.result["arc"], dialogRequest.result["sky"]
            
        local chaosTime = Context.beatLengthAt(tStart, Context.currentTimingGroup) / Context.beatlineDensity
        
        for timing = tStart, tEnd - chaosTime, chaosTime do
            for _ = 1, intensityVal do
                if not tapEX then cmd.add(Event.tap(timing + math.random(0, chaosTime), math.random(1, 4), Context.currentTimingGroup).save()) end
                if not holdEX then
                    local holdDuration = math.random(50, 500)
                    local holdTiming = timing + math.random(1, chaosTime - holdDuration)
                    cmd.add(Event.hold(holdTiming, holdTiming + math.random(holdDuration, chaosTime), math.random(1, 4), Context.currentTimingGroup).save())
                end
                if not arcEX then
                    local randomBoolean = math.random() < 0.5
                    local arcTiming = timing + math.random(0, chaosTime)
                    local position, endposition = xy(math.randomf(-0.5, 1.5), math.randomf(0, 1)), xy(math.randomf(-0.5, 2), math.randomf(0, 2))
                    cmd.add(Event.arc(arcTiming, position, arcTiming + math.random(1, 500), endposition, randomBoolean, math.random(0,1), "s", Context.currentTimingGroup).save())
                end
                if not skyEX then
                    local arcTiming = timing + math.random(0, chaosTime)
                    local position = xy(math.randomf(-0.5, 1.5), math.randomf(0, 1))
                    local arcEvent = Event.arc(arcTiming, position, arcTiming + 2, position, true, 0, "s", Context.currentTimingGroup)
                    cmd.add(arcEvent.save())
                    local skyEvent = Event.arctap(timing + 1, arcEvent)
                    cmd.add(skyEvent.save())
                end
            end
        end
    end
)

-- // -0.2 ARCS-INATOR // --
MacroNewNOCMD(
    "floony.fun", "mistake", 
    "Beginner's Mistake", "e99a",
    function()
        local cmd = Command.create("-0.2 arcs")
        local arcs = Event.query(EventSelectionConstraint.create().arc()).arc

        for _, arc in ipairs(arcs) do
            if arc.startXY.y == 0 then
                arc.startXY = xy(arc.startXY.x, -0.2)
            end

            if arc.endXY.y == 0 then
                arc.endXY = xy(arc.endXY.x, -0.2)
            end
            cmd.add(arc.save())
        end

        cmd.commit()
        notify("Enjoy the -0.2 arcs\nBtw you can undo this if you want to.")
    end
)

-- // C0MB0 BR34KER // --
MacroNewNOCMD(
    "floony.fun", "warning", 
    "Don't click this", "e002",
    function()
        -- Pre-warning
        local dialogFields = {
            DialogField.create("prewarn")
                .setLabel("Continue")
                .setTooltip("I click this on purpose. Execute this macro.")
                .checkbox()
        }

        local dialogRequest = DialogInput.withTitle("Did you accidentally click this? If so, then please leave.").requestInput(dialogFields)
        coroutine.yield()
        local prewarn = dialogRequest.result["prewarn"]
        
        -- First warning
        if prewarn then
            local dialogFields2 =  {
                DialogField.create("firstwarn")
                .setLabel("Proceed.")
                .setTooltip("I want to execute this macro.")
                .checkbox()
            }
            local dialogRequest2 = DialogInput.withTitle("Oh really? But this is dangerous.").requestInput(dialogFields2)
            coroutine.yield()
            local firstwarn = dialogRequest2.result["firstwarn"]
            
            -- Second warning
            if firstwarn then
                local dialogFields3 = {
                    DialogField.create("secondwarn")
                    .setLabel("Proceed..")
                    .setTooltip("I am sure.")
                    .checkbox()
                }
                local dialogRequest3 = DialogInput.withTitle("Are you sure? Because once you execute this, it won't be undone.").requestInput(dialogFields3)
                coroutine.yield()
                local secondwarn = dialogRequest3.result["secondwarn"]
                
                -- Third warning
                if secondwarn then
                    local dialogFields4 = {
                        DialogField.create("thirdwarn")
                        .setLabel("Proceed...")
                        .setTooltip("Yes, I understand.")
                        .checkbox()
                    }
                    local dialogRequest4 = DialogInput.withTitle("Last warning, are you really sure!? The consequences will be dire.").requestInput(dialogFields4)
                    coroutine.yield()
                    local thirdwarn = dialogRequest4.result["thirdwarn"]
                    
                    -- Last warning
                    if thirdwarn then
                        local dialogFields5 = {
                            DialogField.create("lastwarn")
                            .setLabel("...")
                            .setTooltip("Type 'Execute' to run the command.")
                            .textField(FieldConstraint.create().any())
                        }
                        local dialogRequest5 = DialogInput.withTitle("ACTUAL LAST WARNING, ARE YOU REALLY VERY SURE????!!!").requestInput(dialogFields5)
                        coroutine.yield()
                        local lastwarn = dialogRequest5.result["lastwarn"]:lower()
                        
                        -- Add random tap note.
                        if lastwarn == "execute" then
                            local cmd = Command.create("Well... your loss then.")
                            for i = 1, math.random(69, 420) do
                                cmd.commit()
                            end
                            cmd.add(Event.tap(math.random(1, Context.songLength), 99, Context.currentTimingGroup).save())
                            cmd.commit()
                        end
                    end
                end
            end
        end
    end
)

-- // koh //--
local outputText = "<size=1><color=#12669dff>█</color><color=#15355aff>██</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#566870ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>█████████</color><color=#15355aff>███</color><color=#1d4d6dff>████</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>██████████████████████████████</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>█████████████████</color><color=#a3a6a6ff>█</color><color=#566870ff>█</color><color=#15355aff>█</color><color=#1d4d6dff>█████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#566870ff>██</color><color=#6591a4ff>██</color><color=#a3a6a6ff>███████████████████████████████</color>\n<color=#15355aff>██</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>████████</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>███</color><color=#1d4d6dff>████</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>██████████████████████████████</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>█████████████████</color><color=#a3a6a6ff>██</color><color=#1d4d6dff>███████</color><color=#566b99ff>█</color><color=#a3a6a6ff>█</color><color=#566870ff>█</color><color=#6591a4ff>████</color><color=#a3a6a6ff>███</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██████████████████████████</color>\n<color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>████████</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>███</color><color=#1d4d6dff>████</color><color=#566870ff>█</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>████████████████████████████████</color><color=#a3a6a6ff>█</color><color=#c5b1b1ff>███</color><color=#a3a6a6ff>███</color><color=#c5b1b1ff>██████████</color><color=#a3a6a6ff>██</color><color=#566870ff>█</color><color=#1d4d6dff>███████</color><color=#566870ff>██</color><color=#6591a4ff>██</color><color=#a3a6a6ff>███</color><color=#6591a4ff>██</color><color=#a3a6a6ff>███████████████████████████</color>\n<color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#a3a6a6ff>███████</color><color=#12669dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>█████</color><color=#566b99ff>█</color><color=#a3a6a6ff>███</color><color=#c5b1b1ff>███████████████████</color><color=#12669dff>█</color><color=#c5b1b1ff>███</color><color=#12669dff>███████</color><color=#a1b2ccff>██████</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>███████████</color><color=#a3a6a6ff>█</color><color=#566870ff>█</color><color=#1d4d6dff>█████████</color><color=#566b99ff>█</color><color=#6591a4ff>███</color><color=#a3a6a6ff>█</color><color=#6591a4ff>██</color><color=#a3a6a6ff>███████████████████████████</color>\n<color=#12669dff>█</color><color=#566870ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██████</color><color=#12669dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>██████</color><color=#566b99ff>█</color><color=#a3a6a6ff>███</color><color=#c5b1b1ff>███████████████████</color><color=#12669dff>█</color><color=#c5b1b1ff>██</color><color=#12669dff>█████</color><color=#a1b2ccff>██</color><color=#12669dff>█</color><color=#a1b2ccff>██████</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>██████████</color><color=#a3a6a6ff>██</color><color=#6591a4ff>█</color><color=#1d4d6dff>██████████</color><color=#566870ff>█</color><color=#6591a4ff>██████</color><color=#a3a6a6ff>██████████████████████████</color>\n<color=#15355aff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#a3a6a6ff>█████</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>███████</color><color=#566870ff>█</color><color=#a3a6a6ff>███</color><color=#c5b1b1ff>████████████████████</color><color=#12669dff>███████</color><color=#a1b2ccff>█████████</color><color=#a3a6a6ff>██████████</color><color=#c5b1b1ff>██</color><color=#a3a6a6ff>███</color><color=#1d4d6dff>███████████</color><color=#566870ff>█</color><color=#6591a4ff>██████</color><color=#a3a6a6ff>█████████████████████████</color>\n<color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>██</color><color=#a3a6a6ff>████</color><color=#566870ff>█</color><color=#12669dff>██</color><color=#15355aff>███</color><color=#1d4d6dff>████████</color><color=#566b99ff>█</color><color=#a3a6a6ff>███</color><color=#c5b1b1ff>█████████████████████</color><color=#12669dff>██████</color><color=#a1b2ccff>██████████</color><color=#a3a6a6ff>█████████</color><color=#c5b1b1ff>██</color><color=#a3a6a6ff>███</color><color=#1d4d6dff>████████████</color><color=#566870ff>█</color><color=#6591a4ff>█████</color><color=#a3a6a6ff>█████████████████████████</color>\n<color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>████</color><color=#566870ff>█</color><color=#12669dff>██</color><color=#15355aff>███</color><color=#1d4d6dff>█████████</color><color=#a3a6a6ff>████</color><color=#c5b1b1ff>█████████████████████</color><color=#12669dff>█████</color><color=#a1b2ccff>████</color><color=#12669dff>███</color><color=#a1b2ccff>██████</color><color=#a3a6a6ff>████████████</color><color=#566870ff>█</color><color=#1d4d6dff>████</color><color=#15355aff>█</color><color=#1d4d6dff>███████</color><color=#566870ff>█</color><color=#6591a4ff>███</color><color=#a3a6a6ff>██████████████████████████</color>\n<color=#15355aff>█</color><color=#6591a4ff>██</color><color=#a3a6a6ff>███</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>█████</color><color=#1d4d6dff>████████</color><color=#566b99ff>█</color><color=#a3a6a6ff>█████</color><color=#c5b1b1ff>█████████████████████</color><color=#12669dff>████</color><color=#a1b2ccff>██████</color><color=#12669dff>██</color><color=#a1b2ccff>████████</color><color=#a3a6a6ff>██████████</color><color=#1d4d6dff>████</color><color=#15355aff>██</color><color=#1d4d6dff>███████</color><color=#566870ff>█</color><color=#6591a4ff>██</color><color=#a3a6a6ff>██████████████████████████</color>\n<color=#15355aff>█</color><color=#6591a4ff>██</color><color=#a3a6a6ff>███</color><color=#12669dff>██</color><color=#15355aff>████</color><color=#1d4d6dff>█████████</color><color=#566b99ff>█</color><color=#a3a6a6ff>█████</color><color=#c5b1b1ff>██████████████████████</color><color=#12669dff>███</color><color=#a1b2ccff>███████</color><color=#12669dff>█</color><color=#a1b2ccff>████████</color><color=#a3a6a6ff>██████████</color><color=#1d4d6dff>█████</color><color=#15355aff>██</color><color=#1d4d6dff>███████</color><color=#566870ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>█████████████████████████</color><color=#12669dff>█</color>\n<color=#15355aff>█</color><color=#6591a4ff>██</color><color=#a3a6a6ff>██</color><color=#15355aff>█</color><color=#12669dff>█</color><color=#15355aff>█████</color><color=#1d4d6dff>█████████</color><color=#566b99ff>█</color><color=#a3a6a6ff>███████</color><color=#c5b1b1ff>███</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>████████████████</color><color=#12669dff>█</color><color=#a1b2ccff>████████</color><color=#12669dff>██</color><color=#a1b2ccff>███████</color><color=#a3a6a6ff>██████████</color><color=#566b99ff>█</color><color=#1d4d6dff>█████</color><color=#15355aff>██</color><color=#12669dff>█</color><color=#1d4d6dff>██████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>████████████████████████</color><color=#566870ff>██</color>\n<color=#12669dff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#a3a6a6ff>█</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>█████</color><color=#1d4d6dff>█████████</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>█████</color><color=#c5b1b1ff>█████</color><color=#a3a6a6ff>█████</color><color=#c5b1b1ff>███████████</color><color=#a3a6a6ff>█</color><color=#c5b1b1ff>██</color><color=#a1b2ccff>█████████████████</color><color=#a3a6a6ff>██████████</color><color=#6591a4ff>█</color><color=#1d4d6dff>█████</color><color=#15355aff>███</color><color=#12669dff>█</color><color=#1d4d6dff>██████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>████████████████████████</color><color=#566870ff>█</color>\n<color=#12669dff>█</color><color=#566b99ff>██</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>█████</color><color=#1d4d6dff>██████████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>█</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>███████████████</color><color=#c5b1b1ff>████████</color><color=#a3a6a6ff>██████</color><color=#a1b2ccff>██████████████████</color><color=#a3a6a6ff>█████████</color><color=#12669dff>█</color><color=#1d4d6dff>█████</color><color=#15355aff>██</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#1d4d6dff>████</color><color=#a3a6a6ff>████████████████████</color><color=#6591a4ff>█</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#12669dff>█</color><color=#566870ff>█</color>\n<color=#12669dff>█</color><color=#566870ff>█</color><color=#566b99ff>█</color><color=#12669dff>██</color><color=#15355aff>█████</color><color=#1d4d6dff>████████</color><color=#12669dff>██</color><color=#6591a4ff>█</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>███████████████████████████████</color><color=#a1b2ccff>█████████████</color><color=#a3a6a6ff>█████████</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>██</color><color=#12669dff>█</color><color=#1d4d6dff>██████</color><color=#15355aff>██</color><color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#1d4d6dff>███</color><color=#566b99ff>█</color><color=#a3a6a6ff>███████████████████</color><color=#566870ff>██</color><color=#a3a6a6ff>██</color><color=#566870ff>█</color>\n<color=#12669dff>█</color><color=#566870ff>██</color><color=#12669dff>█</color><color=#15355aff>█████</color><color=#1d4d6dff>████████</color><color=#12669dff>██</color><color=#6591a4ff>██</color><color=#a1b2ccff>███</color><color=#a3a6a6ff>██████████████████████████████</color><color=#a1b2ccff>██████████████</color><color=#a3a6a6ff>████████</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>█</color><color=#12669dff>██</color><color=#1d4d6dff>█████</color><color=#15355aff>██</color><color=#1d4d6dff>█</color><color=#6591a4ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#1d4d6dff>███</color><color=#a3a6a6ff>██████████████████</color><color=#12669dff>█</color><color=#566870ff>██</color><color=#12669dff>█</color><color=#a3a6a6ff>█</color><color=#6591a4ff>█</color>\n<color=#566870ff>██</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>██████</color><color=#15355aff>█</color><color=#1d4d6dff>██</color><color=#12669dff>██</color><color=#6591a4ff>█</color><color=#a1b2ccff>████</color><color=#a3a6a6ff>██████████████████████████████</color><color=#a1b2ccff>█████████████████</color><color=#a3a6a6ff>█████</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>█</color><color=#12669dff>██</color><color=#1d4d6dff>██</color><color=#12669dff>█</color><color=#1d4d6dff>███</color><color=#15355aff>██</color><color=#6591a4ff>██</color><color=#12669dff>███</color><color=#1d4d6dff>██</color><color=#566870ff>█</color><color=#a3a6a6ff>█████████████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>███</color><color=#566870ff>████</color><color=#12669dff>█</color><color=#6591a4ff>█</color>\n<color=#a3a6a6ff>██</color><color=#12669dff>█</color><color=#15355aff>█████</color><color=#1d4d6dff>█████</color><color=#15355aff>█</color><color=#1d4d6dff>██</color><color=#12669dff>██</color><color=#6591a4ff>██</color><color=#a1b2ccff>████</color><color=#a3a6a6ff>███████████████████████████████</color><color=#a1b2ccff>███████████████</color><color=#a3a6a6ff>███████</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>█</color><color=#12669dff>█████</color><color=#1d4d6dff>████</color><color=#15355aff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#12669dff>████</color><color=#1d4d6dff>██</color><color=#a3a6a6ff>█████████████</color><color=#566870ff>█</color><color=#a3a6a6ff>███</color><color=#566870ff>████</color><color=#12669dff>██</color>\n<color=#a3a6a6ff>█</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>█████</color><color=#15355aff>██</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#6591a4ff>██</color><color=#5baed0ff>█</color><color=#a1b2ccff>███</color><color=#a3a6a6ff>█████████████████████████</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>██</color><color=#a1b2ccff>█████████████████</color><color=#a3a6a6ff>██</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>███</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>█</color><color=#278fafff>██</color><color=#12669dff>███</color><color=#1d4d6dff>██████</color><color=#a1b2ccff>█</color><color=#6591a4ff>█</color><color=#12669dff>███</color><color=#1d4d6dff>██</color><color=#566b99ff>█</color><color=#a3a6a6ff>███████████</color><color=#12669dff>█</color><color=#566870ff>█</color><color=#a3a6a6ff>███</color><color=#566870ff>█████</color><color=#12669dff>█</color>\n<color=#566870ff>█</color><color=#1d4d6dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>█████</color><color=#15355aff>██</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#278fafff>█</color><color=#6591a4ff>██</color><color=#5baed0ff>█</color><color=#a1b2ccff>████</color><color=#a3a6a6ff>████████████████████████</color><color=#a1b2ccff>███</color><color=#a3a6a6ff>█</color><color=#a1b2ccff>█████████████████</color><color=#a3a6a6ff>██</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>██</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>█</color><color=#278fafff>██</color><color=#12669dff>████</color><color=#1d4d6dff>████</color><color=#15355aff>█</color><color=#a3a6a6ff>██</color><color=#12669dff>████</color><color=#1d4d6dff>██</color><color=#a3a6a6ff>██████████</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#a3a6a6ff>███</color><color=#566870ff>██</color><color=#12669dff>████</color>\n<color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>███</color><color=#1d4d6dff>█████</color><color=#15355aff>███</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#6591a4ff>███</color><color=#5baed0ff>██</color><color=#a1b2ccff>████</color><color=#a3a6a6ff>███████████████████</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>██</color><color=#a1b2ccff>█</color><color=#5baed0ff>█</color><color=#a1b2ccff>█████████████</color><color=#5baed0ff>█</color><color=#a1b2ccff>██</color><color=#5baed0ff>██</color><color=#a1b2ccff>█████████</color><color=#5baed0ff>█</color><color=#278fafff>███</color><color=#12669dff>████</color><color=#1d4d6dff>███</color><color=#15355aff>█</color><color=#566b99ff>█</color><color=#a1b2ccff>█</color><color=#566b99ff>█</color><color=#12669dff>███</color><color=#1d4d6dff>██</color><color=#6591a4ff>█</color><color=#a3a6a6ff>████████</color><color=#12669dff>█</color><color=#566870ff>███</color><color=#a3a6a6ff>███</color><color=#566870ff>███</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#566870ff>█</color>\n<color=#1d4d6dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>█████</color><color=#15355aff>██</color><color=#1d4d6dff>██</color><color=#12669dff>███</color><color=#6591a4ff>███</color><color=#5baed0ff>███</color><color=#a1b2ccff>███</color><color=#a3a6a6ff>██████████████████</color><color=#a1b2ccff>█</color><color=#5baed0ff>█</color><color=#4bc8e1ff>█</color><color=#5baed0ff>█████</color><color=#a1b2ccff>████████████</color><color=#5baed0ff>████</color><color=#28acd4ff>█</color><color=#5baed0ff>██</color><color=#a1b2ccff>███</color><color=#5baed0ff>██</color><color=#a1b2ccff>██</color><color=#6591a4ff>█</color><color=#278fafff>███</color><color=#12669dff>█████</color><color=#1d4d6dff>████</color><color=#a1b2ccff>█</color><color=#6591a4ff>█</color><color=#12669dff>████</color><color=#1d4d6dff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>███████</color><color=#6591a4ff>█</color><color=#566870ff>████</color><color=#a3a6a6ff>███</color><color=#566870ff>█</color><color=#1d4d6dff>██</color><color=#566870ff>█</color><color=#1d4d6dff>█</color><color=#566870ff>█</color>\n<color=#1d4d6dff>█</color><color=#15355aff>███</color><color=#1d4d6dff>█████</color><color=#15355aff>███</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#278fafff>██</color><color=#6591a4ff>█</color><color=#5baed0ff>██████</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>████████████████</color><color=#a1b2ccff>██</color><color=#5baed0ff>█</color><color=#4bc8e1ff>█████</color><color=#5baed0ff>███</color><color=#a1b2ccff>█</color><color=#5baed0ff>██</color><color=#a1b2ccff>███████</color><color=#5baed0ff>████</color><color=#28acd4ff>██</color><color=#32c7e6ff>█</color><color=#5baed0ff>███████</color><color=#6591a4ff>█</color><color=#278fafff>███</color><color=#12669dff>█████</color><color=#1d4d6dff>███</color><color=#15355aff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>█</color><color=#278fafff>██</color><color=#12669dff>██</color><color=#566b99ff>█</color><color=#a3a6a6ff>███████</color><color=#566870ff>██</color><color=#1d4d6dff>█</color><color=#566870ff>██</color><color=#a3a6a6ff>███</color><color=#566870ff>█</color><color=#1d4d6dff>██</color><color=#566870ff>███</color>\n<color=#1d4d6dff>█</color><color=#15355aff>███</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#278fafff>██</color><color=#6591a4ff>█</color><color=#5baed0ff>██████</color><color=#a1b2ccff>██</color><color=#5baed0ff>██</color><color=#a3a6a6ff>██████</color><color=#a1b2ccff>█████</color><color=#5baed0ff>██████</color><color=#4bc8e1ff>█████</color><color=#5baed0ff>████</color><color=#4bc8e1ff>█</color><color=#5baed0ff>████</color><color=#4bc8e1ff>█</color><color=#5baed0ff>██████</color><color=#28acd4ff>█████</color><color=#4bc8e1ff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#5baed0ff>██</color><color=#6591a4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>████</color><color=#1d4d6dff>███</color><color=#15355aff>█</color><color=#6591a4ff>█</color><color=#1d4d6dff>██</color><color=#278fafff>████</color><color=#12669dff>█</color><color=#a3a6a6ff>███████</color><color=#566870ff>█</color><color=#1d4d6dff>█</color><color=#566870ff>██</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#1d4d6dff>██</color><color=#566870ff>█</color><color=#1d4d6dff>█</color><color=#566870ff>█</color>\n<color=#1d4d6dff>█</color><color=#15355aff>██</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#1d4d6dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>█</color><color=#12669dff>████</color><color=#6591a4ff>██</color><color=#5baed0ff>███████</color><color=#a1b2ccff>█</color><color=#5baed0ff>███</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>██</color><color=#a1b2ccff>██</color><color=#5baed0ff>██</color><color=#28acd4ff>███████</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#4bc8e1ff>█████████</color><color=#5baed0ff>█</color><color=#4bc8e1ff>███</color><color=#5baed0ff>███</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>██</color><color=#28acd4ff>████</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#32c7e6ff>██</color><color=#28acd4ff>█</color><color=#5baed0ff>██</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>█████</color><color=#1d4d6dff>███</color><color=#566b99ff>█</color><color=#1d4d6dff>██</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#12669dff>█</color><color=#a3a6a6ff>███████</color><color=#566870ff>████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#1d4d6dff>█████</color>\n<color=#1d4d6dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>██</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#15355aff>█████</color><color=#1d4d6dff>█</color><color=#12669dff>████</color><color=#278fafff>█</color><color=#5baed0ff>██████████</color><color=#28acd4ff>██</color><color=#5baed0ff>███</color><color=#a1b2ccff>██</color><color=#5baed0ff>█</color><color=#28acd4ff>█████████</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#4bc8e1ff>████████████████</color><color=#28acd4ff>██</color><color=#32c7e6ff>█████</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#32c7e6ff>███</color><color=#5baed0ff>█</color><color=#28acd4ff>█</color><color=#278fafff>██</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>██████</color><color=#1d4d6dff>███</color><color=#15355aff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>█████</color><color=#6591a4ff>█</color><color=#566870ff>███</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#6591a4ff>█</color><color=#566870ff>██</color><color=#1d4d6dff>████</color>\n<color=#1d4d6dff>███</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#15355aff>████</color><color=#1d4d6dff>██</color><color=#12669dff>████</color><color=#278fafff>██</color><color=#5baed0ff>█████████</color><color=#28acd4ff>██████</color><color=#5baed0ff>███</color><color=#28acd4ff>██████████</color><color=#5baed0ff>█</color><color=#4bc8e1ff>██████████████</color><color=#5baed0ff>█</color><color=#278fafff>█</color><color=#32c7e6ff>████</color><color=#28acd4ff>█</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>███</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#12669dff>█████</color><color=#1d4d6dff>███</color><color=#15355aff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>██</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>██████</color><color=#6591a4ff>████</color><color=#a3a6a6ff>██</color><color=#566870ff>████</color><color=#1d4d6dff>██</color><color=#566870ff>█</color>\n<color=#1d4d6dff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#15355aff>█████</color><color=#1d4d6dff>██</color><color=#12669dff>██</color><color=#278fafff>████</color><color=#28acd4ff>█</color><color=#5baed0ff>████████</color><color=#28acd4ff>███████</color><color=#278fafff>██</color><color=#28acd4ff>█████████</color><color=#278fafff>█</color><color=#5baed0ff>██</color><color=#4bc8e1ff>█████████████</color><color=#28acd4ff>██</color><color=#32c7e6ff>███</color><color=#28acd4ff>██</color><color=#32c7e6ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>████</color><color=#28acd4ff>████</color><color=#278fafff>██</color><color=#28acd4ff>█</color><color=#278fafff>███</color><color=#12669dff>███</color><color=#1d4d6dff>██</color><color=#12669dff>█</color><color=#1d4d6dff>██</color><color=#12669dff>█</color><color=#278fafff>████</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>██████</color><color=#6591a4ff>███</color><color=#a3a6a6ff>███</color><color=#566b99ff>█</color><color=#566870ff>██████</color>\n<color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#15355aff>█████</color><color=#1d4d6dff>██</color><color=#12669dff>██</color><color=#278fafff>████</color><color=#28acd4ff>█</color><color=#5baed0ff>████████</color><color=#28acd4ff>███████</color><color=#278fafff>██</color><color=#28acd4ff>███████████</color><color=#5baed0ff>█</color><color=#4bc8e1ff>████████████</color><color=#5baed0ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>█████</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>██</color><color=#28acd4ff>██████</color><color=#278fafff>█████</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#1d4d6dff>██</color><color=#6591a4ff>██</color><color=#5baed0ff>██</color><color=#28acd4ff>███</color><color=#5baed0ff>█</color><color=#a1b2ccff>██</color><color=#a3a6a6ff>██████</color><color=#6591a4ff>███</color><color=#a3a6a6ff>███</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#6591a4ff>█</color><color=#566870ff>████</color>\n<color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#1d4d6dff>██</color><color=#15355aff>█████</color><color=#1d4d6dff>██</color><color=#12669dff>██</color><color=#278fafff>████</color><color=#28acd4ff>█</color><color=#5baed0ff>████████</color><color=#28acd4ff>████████</color><color=#12669dff>█</color><color=#28acd4ff>██████████</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#4bc8e1ff>████████████</color><color=#5baed0ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>█████</color><color=#28acd4ff>██</color><color=#32c7e6ff>██</color><color=#28acd4ff>███████</color><color=#278fafff>█████</color><color=#28acd4ff>██</color><color=#12669dff>████</color><color=#6591a4ff>█</color><color=#5baed0ff>█████</color><color=#4bc8e1ff>█</color><color=#5baed0ff>█</color><color=#a1b2ccff>████</color><color=#a3a6a6ff>█████</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#a3a6a6ff>███</color><color=#6591a4ff>███████</color>\n<color=#12669dff>█</color><color=#278fafff>██</color><color=#1d4d6dff>██</color><color=#15355aff>██████</color><color=#1d4d6dff>██</color><color=#12669dff>███</color><color=#278fafff>███</color><color=#28acd4ff>██</color><color=#5baed0ff>███████</color><color=#28acd4ff>████████</color><color=#12669dff>█</color><color=#28acd4ff>██████████</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#4bc8e1ff>████████████</color><color=#5baed0ff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>██████</color><color=#28acd4ff>████</color><color=#5baed0ff>██</color><color=#28acd4ff>███</color><color=#278fafff>█████</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>███</color><color=#5baed0ff>██</color><color=#28acd4ff>██</color><color=#5baed0ff>████</color><color=#a1b2ccff>█████</color><color=#a3a6a6ff>█████████</color><color=#566b99ff>█</color><color=#566870ff>█</color><color=#566b99ff>██</color><color=#6591a4ff>███</color>\n<color=#1d4d6dff>█</color><color=#12669dff>██</color><color=#1d4d6dff>██</color><color=#15355aff>█████</color><color=#1d4d6dff>███</color><color=#12669dff>███</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#5baed0ff>███████</color><color=#28acd4ff>███</color><color=#32c7e6ff>█</color><color=#28acd4ff>████</color><color=#278fafff>█</color><color=#28acd4ff>██████</color><color=#32c7e6ff>██</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#4bc8e1ff>███████████████</color><color=#28acd4ff>██</color><color=#278fafff>██</color><color=#28acd4ff>███████</color><color=#5baed0ff>███</color><color=#28acd4ff>███</color><color=#278fafff>█████</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>███</color><color=#5baed0ff>██████</color><color=#a1b2ccff>████</color><color=#a3a6a6ff>█████████</color><color=#6591a4ff>█</color><color=#566870ff>████</color><color=#6591a4ff>██</color>\n<color=#566b99ff>█</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#1d4d6dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>████████</color><color=#12669dff>███</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#5baed0ff>███████</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#32c7e6ff>█</color><color=#28acd4ff>███</color><color=#32c7e6ff>█</color><color=#28acd4ff>███████</color><color=#5baed0ff>█</color><color=#4bc8e1ff>█████████████████</color><color=#32c7e6ff>███</color><color=#28acd4ff>████████</color><color=#5baed0ff>██</color><color=#28acd4ff>███</color><color=#278fafff>█████</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#28acd4ff>██████</color><color=#5baed0ff>█████</color><color=#a1b2ccff>████</color><color=#a3a6a6ff>██████████</color><color=#6591a4ff>█</color><color=#566870ff>███</color><color=#6591a4ff>█</color>\n<color=#6591a4ff>█</color><color=#566b99ff>██</color><color=#15355aff>██</color><color=#1d4d6dff>████████</color><color=#12669dff>██</color><color=#278fafff>██</color><color=#28acd4ff>██████</color><color=#5baed0ff>████</color><color=#4bc8e1ff>██</color><color=#5baed0ff>█</color><color=#28acd4ff>██████████████</color><color=#5baed0ff>█</color><color=#4bc8e1ff>████████████████████</color><color=#32c7e6ff>████</color><color=#28acd4ff>█████</color><color=#5baed0ff>█</color><color=#28acd4ff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>████</color><color=#278fafff>████</color><color=#28acd4ff>███</color><color=#278fafff>██</color><color=#28acd4ff>██████</color><color=#5baed0ff>█████</color><color=#a1b2ccff>█████</color><color=#a3a6a6ff>███████████</color><color=#566b99ff>███</color>\n<color=#566b99ff>█</color><color=#1d4d6dff>██</color><color=#15355aff>█</color><color=#1d4d6dff>████████</color><color=#12669dff>███</color><color=#278fafff>█</color><color=#28acd4ff>███████</color><color=#5baed0ff>████</color><color=#4bc8e1ff>███</color><color=#28acd4ff>██</color><color=#32c7e6ff>█████</color><color=#28acd4ff>██</color><color=#4bc8e1ff>██████████████████████</color><color=#32c7e6ff>████████</color><color=#28acd4ff>██████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>██████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#28acd4ff>████████</color><color=#5baed0ff>█████</color><color=#a1b2ccff>█████</color><color=#a3a6a6ff>███████████</color><color=#566b99ff>██</color>\n<color=#1d4d6dff>██</color><color=#15355aff>█</color><color=#1d4d6dff>███████</color><color=#12669dff>██</color><color=#278fafff>████</color><color=#28acd4ff>████████</color><color=#5baed0ff>██</color><color=#28acd4ff>█</color><color=#4bc8e1ff>███</color><color=#32c7e6ff>████████████</color><color=#4bc8e1ff>██</color><color=#32c7e6ff>█</color><color=#4bc8e1ff>██████</color><color=#32c7e6ff>███</color><color=#4bc8e1ff>███</color><color=#32c7e6ff>████████████</color><color=#28acd4ff>█████</color><color=#12669dff>██</color><color=#5baed0ff>█</color><color=#28acd4ff>██████</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#5baed0ff>██████</color><color=#a1b2ccff>███</color><color=#a3a6a6ff>█████████████</color><color=#6591a4ff>██</color>\n<color=#1d4d6dff>██</color><color=#15355aff>█</color><color=#1d4d6dff>██████</color><color=#12669dff>██</color><color=#278fafff>████</color><color=#28acd4ff>████████████</color><color=#4bc8e1ff>███</color><color=#32c7e6ff>█████████████████</color><color=#4bc8e1ff>█████████</color><color=#32c7e6ff>████████████</color><color=#28acd4ff>████</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#28acd4ff>███████</color><color=#12669dff>████████</color><color=#28acd4ff>██████</color><color=#5baed0ff>███</color><color=#6591a4ff>█████████</color><color=#a3a6a6ff>█████</color><color=#6591a4ff>██</color><color=#566870ff>████</color>\n<color=#1d4d6dff>██</color><color=#15355aff>██</color><color=#1d4d6dff>████</color><color=#12669dff>██</color><color=#278fafff>████</color><color=#28acd4ff>██████████████</color><color=#4bc8e1ff>██</color><color=#32c7e6ff>██████████████████</color><color=#4bc8e1ff>██</color><color=#28acd4ff>██</color><color=#4bc8e1ff>███</color><color=#32c7e6ff>█</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#32c7e6ff>███████</color><color=#28acd4ff>████</color><color=#278fafff>█</color><color=#12669dff>███</color><color=#5baed0ff>█</color><color=#28acd4ff>██████</color><color=#278fafff>█</color><color=#12669dff>████████</color><color=#278fafff>██</color><color=#28acd4ff>█████</color><color=#278fafff>██</color><color=#6591a4ff>███</color><color=#278fafff>███</color><color=#12669dff>██</color><color=#566b99ff>█████</color><color=#566870ff>█</color><color=#1d4d6dff>█████</color><color=#566870ff>█</color>\n<color=#1d4d6dff>██████</color><color=#12669dff>███</color><color=#278fafff>██████</color><color=#28acd4ff>█████████████</color><color=#4bc8e1ff>██</color><color=#32c7e6ff>███████████████████</color><color=#28acd4ff>███████████</color><color=#32c7e6ff>███████</color><color=#28acd4ff>███</color><color=#278fafff>█████</color><color=#28acd4ff>██████</color><color=#12669dff>██████████████████</color><color=#1d4d6dff>██████████████</color><color=#15355aff>█████</color><color=#1d4d6dff>██</color>\n<color=#566870ff>█</color><color=#1d4d6dff>██</color><color=#566870ff>█</color><color=#1d4d6dff>██</color><color=#12669dff>██</color><color=#278fafff>███</color><color=#12669dff>█</color><color=#1d4d6dff>████</color><color=#12669dff>█</color><color=#28acd4ff>███████████</color><color=#5baed0ff>█</color><color=#4bc8e1ff>██</color><color=#32c7e6ff>██</color><color=#28acd4ff>██</color><color=#32c7e6ff>█████████████</color><color=#28acd4ff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>████████</color><color=#32c7e6ff>██████</color><color=#28acd4ff>███</color><color=#5baed0ff>█████</color><color=#28acd4ff>███</color><color=#278fafff>██</color><color=#12669dff>████████████████████</color><color=#1d4d6dff>██████████████</color><color=#15355aff>███████</color>\n<color=#566870ff>█████</color><color=#1d4d6dff>██</color><color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#15355aff>███████</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>█████████</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>██</color><color=#28acd4ff>███</color><color=#32c7e6ff>█████████████</color><color=#28acd4ff>███████████</color><color=#32c7e6ff>██████</color><color=#28acd4ff>████</color><color=#5baed0ff>███</color><color=#28acd4ff>█</color><color=#278fafff>██</color><color=#12669dff>████████████████████████</color><color=#1d4d6dff>████████████</color><color=#566b99ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#15355aff>██████</color>\n<color=#1d4d6dff>█</color><color=#566870ff>█</color><color=#1d4d6dff>███</color><color=#15355aff>██████████████</color><color=#12669dff>█</color><color=#6591a4ff>███</color><color=#5baed0ff>██████</color><color=#28acd4ff>███████</color><color=#32c7e6ff>█████████████</color><color=#28acd4ff>█</color><color=#4bc8e1ff>██</color><color=#32c7e6ff>████████████</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#12669dff>██████████████████████</color><color=#1d4d6dff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>██</color><color=#12669dff>█</color><color=#1d4d6dff>██</color><color=#12669dff>███</color><color=#1d4d6dff>█</color><color=#566b99ff>██</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#1d4d6dff>█</color><color=#15355aff>██████</color>\n<color=#1d4d6dff>██</color><color=#15355aff>█████████████████</color><color=#12669dff>█</color><color=#6591a4ff>████</color><color=#5baed0ff>█████</color><color=#28acd4ff>████████</color><color=#32c7e6ff>████████████</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>█</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>██████████</color><color=#28acd4ff>████</color><color=#278fafff>███</color><color=#12669dff>█████████████████████</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#5baed0ff>██</color><color=#278fafff>█</color><color=#5baed0ff>███</color><color=#1d4d6dff>██</color><color=#6591a4ff>███</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#1d4d6dff>█</color><color=#6591a4ff>██</color><color=#a1b2ccff>█</color><color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#15355aff>██████</color>\n<color=#15355aff>███████████████████</color><color=#566b99ff>█</color><color=#6591a4ff>███</color><color=#5baed0ff>█</color><color=#6591a4ff>██</color><color=#5baed0ff>████</color><color=#28acd4ff>█████████</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>███████</color><color=#4bc8e1ff>██</color><color=#32c7e6ff>█████████</color><color=#28acd4ff>██████</color><color=#278fafff>██████</color><color=#12669dff>████████████</color><color=#566b99ff>█████</color><color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#278fafff>█</color><color=#5baed0ff>██</color><color=#278fafff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#6591a4ff>██</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#6591a4ff>███</color><color=#12669dff>█</color><color=#a1b2ccff>█</color><color=#1d4d6dff>█</color><color=#15355aff>██████</color>\n<color=#15355aff>███████</color><color=#566870ff>█</color><color=#15355aff>█</color><color=#12669dff>█</color><color=#15355aff>████████</color><color=#566b99ff>█</color><color=#6591a4ff>████████</color><color=#5baed0ff>███</color><color=#28acd4ff>█████████████████</color><color=#32c7e6ff>█</color><color=#4bc8e1ff>████</color><color=#32c7e6ff>██</color><color=#28acd4ff>████</color><color=#278fafff>███</color><color=#28acd4ff>████</color><color=#278fafff>███████</color><color=#12669dff>████████████</color><color=#566b99ff>█████</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>████████</color><color=#1d4d6dff>███████████</color><color=#6591a4ff>██</color><color=#1d4d6dff>█</color><color=#15355aff>██████</color>\n<color=#15355aff>██████</color><color=#12669dff>█████</color><color=#15355aff>█████</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█████████</color><color=#5baed0ff>██</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>██████████████████████████████████</color><color=#278fafff>████</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>███████████</color><color=#566b99ff>██████</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#12669dff>████████</color><color=#1d4d6dff>██████████</color><color=#6591a4ff>██</color><color=#1d4d6dff>█</color><color=#15355aff>██████</color>\n<color=#15355aff>█████</color><color=#12669dff>████</color><color=#15355aff>██████</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#a1b2ccff>█</color><color=#6591a4ff>██</color><color=#5baed0ff>██</color><color=#6591a4ff>████</color><color=#5baed0ff>███</color><color=#12669dff>████</color><color=#278fafff>█</color><color=#28acd4ff>██████████</color><color=#32c7e6ff>██</color><color=#28acd4ff>████████████████████████</color><color=#12669dff>██████████████</color><color=#566b99ff>█████</color><color=#278fafff>██</color><color=#28acd4ff>█</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>████████</color><color=#1d4d6dff>████████</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>██</color><color=#6591a4ff>██</color><color=#1d4d6dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>█</color>\n<color=#15355aff>████</color><color=#12669dff>███</color><color=#15355aff>███████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#a1b2ccff>██</color><color=#6591a4ff>██</color><color=#5baed0ff>██</color><color=#6591a4ff>█</color><color=#5baed0ff>█████</color><color=#12669dff>████████</color><color=#278fafff>█</color><color=#28acd4ff>████████</color><color=#32c7e6ff>████</color><color=#28acd4ff>██████████████████</color><color=#278fafff>█</color><color=#12669dff>████████████████</color><color=#566b99ff>█████</color><color=#278fafff>██</color><color=#28acd4ff>██</color><color=#32c7e6ff>█</color><color=#28acd4ff>██</color><color=#278fafff>█████</color><color=#12669dff>███</color><color=#278fafff>████</color><color=#6591a4ff>███</color><color=#a3a6a6ff>███</color><color=#6591a4ff>███</color><color=#566b99ff>█</color><color=#566870ff>█</color><color=#1d4d6dff>█</color>\n<color=#15355aff>████</color><color=#12669dff>███</color><color=#15355aff>███████</color><color=#5baed0ff>██</color><color=#6591a4ff>█</color><color=#1d4d6dff>██</color><color=#5baed0ff>███</color><color=#a1b2ccff>█</color><color=#5baed0ff>████</color><color=#278fafff>█</color><color=#12669dff>████████████</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#32c7e6ff>████</color><color=#28acd4ff>████████████████</color><color=#12669dff>████████████████████</color><color=#566b99ff>███</color><color=#278fafff>████</color><color=#32c7e6ff>██</color><color=#28acd4ff>█</color><color=#32c7e6ff>█████</color><color=#278fafff>██████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>███</color><color=#12669dff>█</color><color=#a3a6a6ff>██</color><color=#6591a4ff>███</color><color=#566b99ff>██</color><color=#566870ff>█</color>\n<color=#15355aff>████</color><color=#12669dff>█████</color><color=#15355aff>██████</color><color=#1d4d6dff>████</color><color=#5baed0ff>██████</color><color=#278fafff>█</color><color=#12669dff>███████████████████</color><color=#278fafff>█</color><color=#28acd4ff>████████████████</color><color=#12669dff>██████████████████████████</color><color=#6591a4ff>█</color><color=#278fafff>██████</color><color=#32c7e6ff>█</color><color=#12669dff>█</color><color=#32c7e6ff>███</color><color=#12669dff>█</color><color=#278fafff>█████</color><color=#6591a4ff>██</color><color=#a3a6a6ff>███</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>████</color><color=#6591a4ff>█</color><color=#566870ff>███</color>\n<color=#15355aff>████</color><color=#12669dff>██████</color><color=#15355aff>███</color><color=#1d4d6dff>█████</color><color=#12669dff>█</color><color=#5baed0ff>█████</color><color=#278fafff>█</color><color=#12669dff>███████████████████</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>████████████████████████████████████</color><color=#278fafff>███████</color><color=#12669dff>████</color><color=#32c7e6ff>█</color><color=#278fafff>████</color><color=#6591a4ff>███</color><color=#a3a6a6ff>███████</color><color=#6591a4ff>██</color><color=#566870ff>███</color>\n<color=#15355aff>████</color><color=#12669dff>█████</color><color=#15355aff>███</color><color=#1d4d6dff>██████</color><color=#12669dff>█</color><color=#5baed0ff>███</color><color=#278fafff>██</color><color=#12669dff>█████████████████████</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#278fafff>██</color><color=#12669dff>████████████████████████████████████</color><color=#278fafff>█████</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#6591a4ff>███</color><color=#278fafff>█</color><color=#32c7e6ff>█</color><color=#278fafff>██</color><color=#6591a4ff>█████</color><color=#a3a6a6ff>█████</color><color=#12669dff>█</color><color=#566870ff>█</color><color=#566b99ff>█</color><color=#566870ff>████</color>\n<color=#15355aff>████</color><color=#12669dff>█████</color><color=#15355aff>██</color><color=#1d4d6dff>██████</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#278fafff>█</color><color=#12669dff>██████</color><color=#278fafff>██</color><color=#12669dff>███████████████████</color><color=#278fafff>███</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>████████████████████████████</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#12669dff>██████</color><color=#278fafff>███████</color><color=#6591a4ff>█</color><color=#278fafff>█</color><color=#6591a4ff>█</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>█</color><color=#278fafff>█</color><color=#6591a4ff>███</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>██</color><color=#566b99ff>█</color><color=#a3a6a6ff>███</color><color=#12669dff>█</color><color=#566870ff>██████</color>\n<color=#15355aff>████</color><color=#12669dff>█████</color><color=#1d4d6dff>████████</color><color=#12669dff>███████████</color><color=#278fafff>██</color><color=#12669dff>██████████████████</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>███████████████████████████</color><color=#28acd4ff>████</color><color=#278fafff>█</color><color=#12669dff>██████</color><color=#278fafff>███████</color><color=#6591a4ff>█</color><color=#278fafff>██</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>█</color><color=#278fafff>██</color><color=#6591a4ff>█</color><color=#12669dff>█</color><color=#566b99ff>████</color><color=#566870ff>█</color><color=#a3a6a6ff>███</color><color=#566870ff>███████</color>\n<color=#15355aff>████</color><color=#12669dff>███</color><color=#566b99ff>███</color><color=#1d4d6dff>██████</color><color=#12669dff>██████████████</color><color=#278fafff>█</color><color=#12669dff>█████████████████████████████████████████████</color><color=#28acd4ff>███████</color><color=#278fafff>█</color><color=#12669dff>█████</color><color=#278fafff>█████████</color><color=#4bc8e1ff>█</color><color=#12669dff>█</color><color=#4bc8e1ff>█</color><color=#5baed0ff>█</color><color=#6591a4ff>███</color><color=#566b99ff>█</color><color=#1d4d6dff>█</color><color=#566b99ff>███</color><color=#a3a6a6ff>██</color><color=#12669dff>█</color><color=#566870ff>██</color><color=#566b99ff>█</color><color=#566870ff>█</color><color=#1d4d6dff>█</color><color=#566870ff>██</color>\n<color=#15355aff>█████</color><color=#12669dff>██</color><color=#a1b2ccff>████</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>█</color><color=#12669dff>████████████████████████████████████████████████████████████</color><color=#28acd4ff>█████████</color><color=#278fafff>██████</color><color=#6591a4ff>█</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#278fafff>███</color><color=#5baed0ff>█</color><color=#4bc8e1ff>█</color><color=#12669dff>██</color><color=#a1b2ccff>█</color><color=#5baed0ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█████</color><color=#566b99ff>█</color><color=#a3a6a6ff>██</color><color=#566b99ff>█</color><color=#566870ff>██</color><color=#566b99ff>█</color><color=#566870ff>██</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color>\n<color=#15355aff>████</color><color=#566870ff>██</color><color=#a3a6a6ff>█</color><color=#566b99ff>█</color><color=#6591a4ff>██</color><color=#a1b2ccff>██</color><color=#5baed0ff>██</color><color=#6591a4ff>█</color><color=#12669dff>██████████████████████████████████████████████████████████</color><color=#28acd4ff>███████████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>██</color><color=#6591a4ff>█</color><color=#278fafff>██</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#5baed0ff>██</color><color=#a1b2ccff>█</color><color=#12669dff>███</color><color=#a1b2ccff>█</color><color=#12669dff>█</color><color=#566b99ff>██████</color><color=#a3a6a6ff>████</color><color=#566870ff>████</color><color=#1d4d6dff>███</color><color=#566b99ff>█</color>\n<color=#1d4d6dff>████</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#566b99ff>█</color><color=#6591a4ff>███</color><color=#5baed0ff>███</color><color=#6591a4ff>█</color><color=#12669dff>███████</color><color=#278fafff>██</color><color=#12669dff>█████████████████████████████████████████████</color><color=#28acd4ff>█████████████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#6591a4ff>██</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#5baed0ff>██</color><color=#a1b2ccff>██</color><color=#12669dff>█</color><color=#e5f2fcff>█</color><color=#12669dff>█</color><color=#a1b2ccff>█</color><color=#12669dff>██</color><color=#566b99ff>████</color><color=#12669dff>████</color><color=#a3a6a6ff>█</color><color=#566870ff>██</color><color=#1d4d6dff>█</color><color=#566870ff>█</color><color=#15355aff>█</color><color=#1d4d6dff>██</color><color=#566b99ff>█</color>\n<color=#1d4d6dff>██</color><color=#15355aff>██</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>█</color><color=#566b99ff>██</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#6591a4ff>███</color><color=#5baed0ff>████</color><color=#278fafff>█</color><color=#12669dff>████</color><color=#278fafff>███</color><color=#12669dff>███████████████████████████████████████████</color><color=#28acd4ff>██████████████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#6591a4ff>█</color><color=#278fafff>██</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#5baed0ff>█</color><color=#a1b2ccff>██</color><color=#12669dff>███</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>█</color><color=#12669dff>█</color><color=#566b99ff>█████</color><color=#12669dff>████</color><color=#c5b1b1ff>█</color><color=#566b99ff>█</color><color=#566870ff>███</color><color=#15355aff>█</color><color=#1d4d6dff>██</color><color=#566b99ff>█</color>\n<color=#1d4d6dff>█</color><color=#15355aff>███</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#15355aff>██</color><color=#566870ff>█</color><color=#a3a6a6ff>██████</color><color=#6591a4ff>██</color><color=#5baed0ff>████</color><color=#278fafff>██████</color><color=#12669dff>████████████████████████████████████████████</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>███████████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>████</color><color=#12669dff>█</color><color=#28acd4ff>██</color><color=#5baed0ff>██</color><color=#12669dff>████</color><color=#5baed0ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>██████</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#c5b1b1ff>█</color><color=#a3a6a6ff>██</color><color=#566870ff>███</color><color=#15355aff>█</color><color=#1d4d6dff>██</color><color=#566b99ff>█</color>\n<color=#15355aff>█</color><color=#1d4d6dff>█</color><color=#15355aff>██</color><color=#566870ff>██</color><color=#12669dff>█</color><color=#15355aff>██</color><color=#a3a6a6ff>██████</color><color=#5baed0ff>██████</color><color=#28acd4ff>██</color><color=#278fafff>███</color><color=#12669dff>███████████████████████████████████████████</color><color=#5baed0ff>█</color><color=#12669dff>█</color><color=#e5f2fcff>████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>██████</color><color=#278fafff>██</color><color=#12669dff>██</color><color=#278fafff>███</color><color=#12669dff>█</color><color=#28acd4ff>███</color><color=#5baed0ff>█</color><color=#12669dff>███</color><color=#4bc8e1ff>█</color><color=#28acd4ff>█████████</color><color=#5baed0ff>██</color><color=#12669dff>█</color><color=#a3a6a6ff>██</color><color=#566b99ff>█</color><color=#1d4d6dff>█████</color><color=#566b99ff>█</color>\n<color=#15355aff>█████</color><color=#566b99ff>█</color><color=#12669dff>█</color><color=#15355aff>██</color><color=#566b99ff>█</color><color=#a3a6a6ff>████</color><color=#6591a4ff>█</color><color=#5baed0ff>██████</color><color=#28acd4ff>████</color><color=#278fafff>█</color><color=#12669dff>███████████████████████████</color><color=#706fcfff>██</color><color=#12669dff>████████████</color><color=#28acd4ff>█</color><color=#12669dff>█</color><color=#e5f2fcff>████████</color><color=#5baed0ff>█</color><color=#278fafff>█</color><color=#28acd4ff>███</color><color=#278fafff>█</color><color=#12669dff>██████</color><color=#278fafff>██</color><color=#28acd4ff>███</color><color=#5baed0ff>█</color><color=#4bc8e1ff>█</color><color=#12669dff>█</color><color=#4bc8e1ff>█</color><color=#278fafff>██</color><color=#28acd4ff>████</color><color=#278fafff>███</color><color=#28acd4ff>█</color><color=#6591a4ff>████</color><color=#a3a6a6ff>█</color><color=#6591a4ff>█</color><color=#566870ff>█</color><color=#1d4d6dff>███</color><color=#566870ff>█</color><color=#566b99ff>█</color>\n<color=#1d4d6dff>██</color><color=#15355aff>███</color><color=#566870ff>██</color><color=#12669dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>███</color><color=#6591a4ff>█</color><color=#5baed0ff>████████</color><color=#28acd4ff>███</color><color=#12669dff>████████████████████████</color><color=#706fcfff>██████</color><color=#5baed0ff>██</color><color=#706fcfff>█</color><color=#12669dff>████</color><color=#28acd4ff>███</color><color=#12669dff>█</color><color=#e5f2fcff>███████████</color><color=#278fafff>█</color><color=#12669dff>████████████</color><color=#28acd4ff>███</color><color=#4bc8e1ff>██</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#278fafff>███</color><color=#28acd4ff>██</color><color=#5baed0ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#a1b2ccff>█</color><color=#a3a6a6ff>█</color><color=#6591a4ff>██</color><color=#1d4d6dff>██</color><color=#566870ff>██</color><color=#1d4d6dff>█</color><color=#12669dff>█</color>\n<color=#15355aff>████</color><color=#1d4d6dff>██</color><color=#566b99ff>██</color><color=#12669dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>██</color><color=#5baed0ff>█████</color><color=#4bc8e1ff>█</color><color=#5baed0ff>███</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>████████████████████</color><color=#566b99ff>█</color><color=#706fcfff>██████</color><color=#5baed0ff>█</color><color=#a1b2ccff>███</color><color=#5baed0ff>███</color><color=#28acd4ff>███</color><color=#5baed0ff>█</color><color=#e5f2fcff>█████████████</color><color=#5baed0ff>█</color><color=#12669dff>██████████</color><color=#278fafff>██</color><color=#28acd4ff>██</color><color=#4bc8e1ff>█</color><color=#12669dff>█</color><color=#4bc8e1ff>██</color><color=#28acd4ff>█</color><color=#278fafff>██</color><color=#12669dff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#12669dff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#566b99ff>██</color><color=#6591a4ff>████</color><color=#1d4d6dff>██████</color>\n<color=#15355aff>█</color><color=#1d4d6dff>██</color><color=#15355aff>████</color><color=#566b99ff>██</color><color=#15355aff>███</color><color=#566b99ff>█</color><color=#6591a4ff>██</color><color=#5baed0ff>█████████</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#12669dff>██████████████████</color><color=#566b99ff>█</color><color=#706fcfff>██████</color><color=#a1b2ccff>█████████</color><color=#5baed0ff>███</color><color=#12669dff>█</color><color=#e5f2fcff>██████████████</color><color=#6591a4ff>█</color><color=#12669dff>██████████</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>█</color><color=#12669dff>█</color><color=#e5f2fcff>█</color><color=#12669dff>█</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>█</color><color=#28acd4ff>███████</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#6591a4ff>██</color><color=#a1b2ccff>█</color><color=#6591a4ff>██</color><color=#566b99ff>█</color><color=#1d4d6dff>█████</color><color=#12669dff>█</color>\n<color=#12669dff>██</color><color=#15355aff>██████</color><color=#566b99ff>██</color><color=#1d4d6dff>████</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#5baed0ff>██████</color><color=#278fafff>█</color><color=#12669dff>███████████</color><color=#566b99ff>█</color><color=#12669dff>██████</color><color=#566b99ff>█</color><color=#706fcfff>██████</color><color=#a1b2ccff>█████████████</color><color=#12669dff>█</color><color=#e5f2fcff>████████████████</color><color=#278fafff>█</color><color=#12669dff>███████████</color><color=#28acd4ff>███</color><color=#12669dff>█</color><color=#e5f2fcff>█</color><color=#12669dff>█</color><color=#32c7e6ff>██████</color><color=#28acd4ff>██████</color><color=#5baed0ff>██</color><color=#12669dff>█</color><color=#a1b2ccff>█</color><color=#6591a4ff>█</color><color=#1d4d6dff>███████</color>\n<color=#566b99ff>█</color><color=#15355aff>████████</color><color=#566b99ff>███████</color><color=#12669dff>████████████████</color><color=#566b99ff>███</color><color=#12669dff>███</color><color=#566b99ff>██</color><color=#706fcfff>███████</color><color=#a1b2ccff>████████████</color><color=#12669dff>█</color><color=#e5f2fcff>█████████████████</color><color=#5baed0ff>█</color><color=#12669dff>████████████</color><color=#28acd4ff>███</color><color=#4bc8e1ff>█</color><color=#5baed0ff>█</color><color=#12669dff>███████████████</color><color=#566b99ff>██</color><color=#6591a4ff>█</color><color=#1d4d6dff>███████</color>\n<color=#566b99ff>█</color><color=#15355aff>█</color><color=#1d4d6dff>███</color><color=#15355aff>████</color><color=#566b99ff>███</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>████</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>███████████</color><color=#566b99ff>████</color><color=#12669dff>█</color><color=#566b99ff>██</color><color=#706fcfff>████████</color><color=#a1b2ccff>███████████</color><color=#12669dff>█</color><color=#e5f2fcff>█████████████████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#12669dff>█████████████</color><color=#28acd4ff>███</color><color=#4bc8e1ff>█</color><color=#12669dff>████████████████</color><color=#566b99ff>█</color><color=#5baed0ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>███████</color>\n<color=#566b99ff>█</color><color=#15355aff>█</color><color=#1d4d6dff>██████</color><color=#12669dff>█</color><color=#566b99ff>███</color><color=#1d4d6dff>███</color><color=#12669dff>███████████████</color><color=#566b99ff>██████</color><color=#706fcfff>███████████</color><color=#a1b2ccff>██</color><color=#5baed0ff>██</color><color=#278fafff>█</color><color=#5baed0ff>█</color><color=#a1b2ccff>█</color><color=#12669dff>██</color><color=#e5f2fcff>█████████████████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>██</color><color=#12669dff>█████████████</color><color=#28acd4ff>███</color><color=#4bc8e1ff>█</color><color=#28acd4ff>█</color><color=#12669dff>██████████████</color><color=#566b99ff>█</color><color=#5baed0ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>████████</color>\n<color=#1d4d6dff>███████████</color><color=#15355aff>█</color><color=#1d4d6dff>█</color><color=#12669dff>███████████████</color><color=#566b99ff>█████</color><color=#706fcfff>████████████</color><color=#a1b2ccff>██</color><color=#5baed0ff>██</color><color=#28acd4ff>██</color><color=#12669dff>█</color><color=#e5f2fcff>███████████████████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>███</color><color=#12669dff>██████████████</color><color=#278fafff>██</color><color=#28acd4ff>████</color><color=#12669dff>████████████</color><color=#6591a4ff>███</color><color=#566b99ff>█</color><color=#1d4d6dff>████████</color>\n<color=#1d4d6dff>█████</color><color=#12669dff>████</color><color=#1d4d6dff>████</color><color=#12669dff>█████</color><color=#566b99ff>█</color><color=#12669dff>████████</color><color=#566b99ff>████</color><color=#706fcfff>█████████████</color><color=#5baed0ff>██</color><color=#28acd4ff>████</color><color=#4bc8e1ff>█</color><color=#e5f2fcff>█████████████████</color><color=#12669dff>█</color><color=#4bc8e1ff>█</color><color=#28acd4ff>████████████</color><color=#12669dff>███████</color><color=#278fafff>██</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>██</color><color=#28acd4ff>███</color><color=#12669dff>██████</color><color=#278fafff>█</color><color=#6591a4ff>██</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#566870ff>██</color><color=#1d4d6dff>███████</color>\n<color=#1d4d6dff>████</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█████</color><color=#1d4d6dff>██</color><color=#12669dff>████</color><color=#566b99ff>██</color><color=#12669dff>███████</color><color=#566b99ff>██</color><color=#706fcfff>█████████████</color><color=#5baed0ff>███</color><color=#28acd4ff>█</color><color=#12669dff>██</color><color=#28acd4ff>██</color><color=#4bc8e1ff>█</color><color=#12669dff>█</color><color=#e5f2fcff>███████████████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>███████████████</color><color=#12669dff>██████</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>████</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#278fafff>█</color><color=#12669dff>████</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>█</color><color=#566870ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█████</color>\n<color=#1d4d6dff>████</color><color=#12669dff>█████████████</color><color=#566b99ff>██</color><color=#12669dff>█████</color><color=#566b99ff>████</color><color=#706fcfff>█████████</color><color=#5baed0ff>███</color><color=#28acd4ff>████</color><color=#12669dff>███</color><color=#28acd4ff>██</color><color=#4bc8e1ff>█</color><color=#12669dff>█</color><color=#e5f2fcff>████████████</color><color=#12669dff>██</color><color=#5baed0ff>█</color><color=#28acd4ff>██████</color><color=#32c7e6ff>██</color><color=#28acd4ff>██████████</color><color=#12669dff>█████</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>█████</color><color=#278fafff>█</color><color=#12669dff>█████</color><color=#6591a4ff>█████</color><color=#566b99ff>█</color><color=#1d4d6dff>█████</color>\n<color=#1d4d6dff>█████</color><color=#12669dff>█████</color><color=#6591a4ff>█</color><color=#12669dff>██████</color><color=#566b99ff>██</color><color=#12669dff>████</color><color=#566b99ff>█████</color><color=#706fcfff>█████</color><color=#5baed0ff>████</color><color=#28acd4ff>████████</color><color=#12669dff>██</color><color=#28acd4ff>██</color><color=#32c7e6ff>█</color><color=#12669dff>█</color><color=#e5f2fcff>██████████</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>███████</color><color=#32c7e6ff>██████</color><color=#28acd4ff>█████████</color><color=#12669dff>████</color><color=#28acd4ff>██████</color><color=#12669dff>██</color><color=#28acd4ff>█████████</color><color=#278fafff>█</color><color=#6591a4ff>█</color><color=#5baed0ff>█</color><color=#a1b2ccff>█</color><color=#5baed0ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>███████</color>\n<color=#1d4d6dff>██████</color><color=#12669dff>███████████</color><color=#566b99ff>█████████</color><color=#706fcfff>████</color><color=#5baed0ff>██</color><color=#28acd4ff>█████</color><color=#32c7e6ff>█</color><color=#28acd4ff>████████</color><color=#12669dff>█</color><color=#28acd4ff>███</color><color=#4bc8e1ff>█</color><color=#12669dff>█</color><color=#e5f2fcff>███████</color><color=#12669dff>█</color><color=#28acd4ff>█████████</color><color=#32c7e6ff>████████</color><color=#28acd4ff>█████████</color><color=#12669dff>███</color><color=#28acd4ff>███</color><color=#32c7e6ff>████</color><color=#28acd4ff>█████████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#6591a4ff>█</color><color=#1d4d6dff>█</color><color=#6591a4ff>██</color><color=#566b99ff>██</color><color=#1d4d6dff>██████</color>\n<color=#1d4d6dff>██████</color><color=#12669dff>████████████</color><color=#566b99ff>██████████</color><color=#28acd4ff>██████</color><color=#32c7e6ff>███████</color><color=#28acd4ff>██████████</color><color=#4bc8e1ff>█</color><color=#12669dff>██</color><color=#e5f2fcff>███</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#28acd4ff>██████████</color><color=#32c7e6ff>████████</color><color=#28acd4ff>█████</color><color=#12669dff>███████</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#278fafff>██</color><color=#28acd4ff>██████</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#6591a4ff>██</color><color=#a1b2ccff>█</color><color=#6591a4ff>██</color><color=#566b99ff>█</color><color=#1d4d6dff>██████</color>\n<color=#1d4d6dff>██████</color><color=#12669dff>██</color><color=#6591a4ff>█</color><color=#12669dff>██████████</color><color=#566b99ff>█</color><color=#12669dff>██</color><color=#566b99ff>████</color><color=#278fafff>█</color><color=#28acd4ff>███████</color><color=#32c7e6ff>████</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>███</color><color=#28acd4ff>██</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>███████</color><color=#32c7e6ff>█</color><color=#4bc8e1ff>██</color><color=#5baed0ff>█</color><color=#278fafff>█</color><color=#28acd4ff>███████████</color><color=#32c7e6ff>████████</color><color=#28acd4ff>█</color><color=#12669dff>████████████</color><color=#28acd4ff>███</color><color=#32c7e6ff>█</color><color=#28acd4ff>██</color><color=#12669dff>█</color><color=#28acd4ff>██</color><color=#12669dff>██</color><color=#28acd4ff>████</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#6591a4ff>███</color><color=#a1b2ccff>█</color><color=#6591a4ff>██</color><color=#566b99ff>█</color><color=#1d4d6dff>██████</color>\n<color=#15355aff>█</color><color=#1d4d6dff>██████</color><color=#6591a4ff>█</color><color=#12669dff>██████████████</color><color=#566b99ff>██</color><color=#6591a4ff>██</color><color=#28acd4ff>████████</color><color=#32c7e6ff>████</color><color=#4bc8e1ff>███</color><color=#32c7e6ff>██</color><color=#28acd4ff>█</color><color=#12669dff>███</color><color=#28acd4ff>████████</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#28acd4ff>██████████</color><color=#32c7e6ff>███████</color><color=#28acd4ff>█</color><color=#12669dff>██████████████</color><color=#28acd4ff>████</color><color=#278fafff>██</color><color=#28acd4ff>██</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>████</color><color=#12669dff>██</color><color=#5baed0ff>█</color><color=#6591a4ff>██</color><color=#a1b2ccff>█</color><color=#566870ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>██████</color>\n<color=#1d4d6dff>██████</color><color=#566b99ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█████████</color><color=#6591a4ff>█</color><color=#12669dff>███</color><color=#6591a4ff>██</color><color=#5baed0ff>██</color><color=#28acd4ff>███████</color><color=#32c7e6ff>█████</color><color=#4bc8e1ff>████</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>███████████████</color><color=#28acd4ff>██████████</color><color=#32c7e6ff>████</color><color=#28acd4ff>██</color><color=#12669dff>██████████████</color><color=#28acd4ff>█████</color><color=#278fafff>██</color><color=#28acd4ff>█████</color><color=#278fafff>█</color><color=#28acd4ff>█</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#5baed0ff>█</color><color=#6591a4ff>█</color><color=#1d4d6dff>█</color><color=#6591a4ff>█</color><color=#a3a6a6ff>█</color><color=#1d4d6dff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>██</color><color=#15355aff>█</color><color=#1d4d6dff>███</color>\n<color=#1d4d6dff>█████</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>██</color><color=#12669dff>████████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#6591a4ff>███</color><color=#5baed0ff>██</color><color=#28acd4ff>████████</color><color=#32c7e6ff>████</color><color=#4bc8e1ff>█████</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#12669dff>████████████████</color><color=#28acd4ff>█████████</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#32c7e6ff>█</color><color=#28acd4ff>██</color><color=#12669dff>███████████████</color><color=#28acd4ff>█████</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#28acd4ff>███████</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#5baed0ff>█</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>██</color><color=#566b99ff>██</color><color=#1d4d6dff>███████</color>\n<color=#1d4d6dff>████</color><color=#12669dff>█</color><color=#6591a4ff>█</color><color=#1d4d6dff>████</color><color=#12669dff>████████</color><color=#1d4d6dff>██</color><color=#6591a4ff>████</color><color=#5baed0ff>██</color><color=#28acd4ff>██████████</color><color=#32c7e6ff>████</color><color=#4bc8e1ff>███</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#12669dff>█████████████████</color><color=#278fafff>█</color><color=#28acd4ff>██████████</color><color=#278fafff>█</color><color=#12669dff>████████████████████</color><color=#278fafff>██████</color><color=#6591a4ff>██</color><color=#278fafff>████</color><color=#6591a4ff>██</color><color=#5baed0ff>██</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>████</color><color=#15355aff>█</color><color=#1d4d6dff>███</color>\n<color=#1d4d6dff>████</color><color=#566b99ff>█</color><color=#1d4d6dff>█████</color><color=#12669dff>███</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#1d4d6dff>██</color><color=#12669dff>█</color><color=#6591a4ff>███</color><color=#5baed0ff>████</color><color=#28acd4ff>██</color><color=#278fafff>█</color><color=#12669dff>██████</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#32c7e6ff>██</color><color=#4bc8e1ff>█</color><color=#32c7e6ff>██</color><color=#28acd4ff>█</color><color=#12669dff>███████████████████</color><color=#28acd4ff>█████████</color><color=#12669dff>███████████████████</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>██</color><color=#12669dff>████</color><color=#1d4d6dff>████████████</color>\n<color=#15355aff>██</color><color=#1d4d6dff>██████████</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>██</color><color=#1d4d6dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#6591a4ff>████</color><color=#5baed0ff>█</color><color=#6591a4ff>█</color><color=#12669dff>█████████████</color><color=#28acd4ff>██</color><color=#32c7e6ff>███</color><color=#28acd4ff>█</color><color=#12669dff>████████████████████</color><color=#28acd4ff>███████</color><color=#12669dff>█████████████████████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>██</color><color=#5baed0ff>█</color><color=#278fafff>███</color><color=#12669dff>█████</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>███</color><color=#12669dff>██</color><color=#1d4d6dff>█████</color>\n<color=#15355aff>██</color><color=#1d4d6dff>███████████</color><color=#12669dff>██</color><color=#15355aff>████</color><color=#566b99ff>█</color><color=#6591a4ff>████</color><color=#12669dff>█</color><color=#1d4d6dff>██</color><color=#12669dff>██████████████</color><color=#28acd4ff>██</color><color=#32c7e6ff>█</color><color=#28acd4ff>█</color><color=#12669dff>█████████████████████</color><color=#278fafff>█</color><color=#28acd4ff>█████</color><color=#12669dff>██████████████████████</color><color=#278fafff>██</color><color=#12669dff>█</color><color=#278fafff>████</color><color=#12669dff>█████</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>██</color><color=#1d4d6dff>██████</color>\n<color=#15355aff>██</color><color=#1d4d6dff>██</color><color=#15355aff>█</color><color=#1d4d6dff>███████</color><color=#12669dff>██</color><color=#15355aff>█████</color><color=#566b99ff>█</color><color=#6591a4ff>███</color><color=#12669dff>█</color><color=#1d4d6dff>██</color><color=#12669dff>████████████████</color><color=#278fafff>█</color><color=#28acd4ff>██</color><color=#12669dff>███████████████████████</color><color=#28acd4ff>███</color><color=#12669dff>██████████████████████████</color><color=#278fafff>█</color><color=#6591a4ff>█</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#1d4d6dff>██</color><color=#6591a4ff>██</color><color=#566b99ff>███</color><color=#1d4d6dff>█</color><color=#12669dff>█</color><color=#1d4d6dff>██████</color>\n<color=#15355aff>███████</color><color=#1d4d6dff>████</color><color=#566b99ff>█</color><color=#12669dff>█</color><color=#15355aff>██████</color><color=#12669dff>█</color><color=#6591a4ff>██</color><color=#12669dff>█</color><color=#1d4d6dff>███</color><color=#12669dff>█████████████████</color><color=#28acd4ff>█</color><color=#12669dff>██████████████████████████</color><color=#278fafff>█</color><color=#12669dff>█████████████████████████</color><color=#278fafff>████</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#6591a4ff>███</color><color=#1d4d6dff>█</color><color=#566b99ff>██</color><color=#1d4d6dff>████</color><color=#12669dff>█</color><color=#1d4d6dff>██████</color>\n<color=#15355aff>█████████</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#12669dff>█</color><color=#15355aff>███████</color><color=#1d4d6dff>█</color><color=#6591a4ff>██</color><color=#1d4d6dff>████</color><color=#12669dff>█████████████████</color><color=#28acd4ff>█</color><color=#12669dff>███████████████</color><color=#278fafff>███████████</color><color=#12669dff>██████████████████████</color><color=#278fafff>██</color><color=#12669dff>███</color><color=#278fafff>███</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#12669dff>███</color><color=#6591a4ff>█</color><color=#566b99ff>███</color><color=#566870ff>██</color><color=#1d4d6dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>███████</color>\n<color=#15355aff>████████</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>█</color><color=#15355aff>█████████</color><color=#566b99ff>██</color><color=#1d4d6dff>████</color><color=#12669dff>████████████████</color><color=#278fafff>█</color><color=#12669dff>███████████</color><color=#278fafff>███</color><color=#12669dff>█</color><color=#278fafff>██████████████</color><color=#12669dff>██</color><color=#278fafff>███</color><color=#12669dff>████</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>██████</color><color=#12669dff>███</color><color=#278fafff>███</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>█</color><color=#278fafff>█</color><color=#12669dff>██</color><color=#6591a4ff>█</color><color=#12669dff>██</color><color=#6591a4ff>█</color><color=#1d4d6dff>█</color><color=#6591a4ff>██</color><color=#566b99ff>█</color><color=#1d4d6dff>██</color><color=#15355aff>█</color><color=#1d4d6dff>███████</color>\n<color=#15355aff>███████████████████</color><color=#1d4d6dff>██</color><color=#12669dff>█</color><color=#1d4d6dff>█████</color><color=#12669dff>███████████████</color><color=#278fafff>█</color><color=#12669dff>███</color><color=#278fafff>████</color><color=#12669dff>█</color><color=#278fafff>███████████████████████████████████████</color><color=#12669dff>█████████</color><color=#6591a4ff>█</color><color=#12669dff>███</color><color=#6591a4ff>█</color><color=#12669dff>█</color><color=#566b99ff>█</color><color=#1d4d6dff>█</color><color=#566b99ff>█</color><color=#6591a4ff>█</color><color=#566b99ff>█</color><color=#566870ff>█</color><color=#1d4d6dff>████</color><color=#15355aff>██</color><color=#1d4d6dff>███</color>\n<color=#15355aff>██████████████</color><color=#1d4d6dff>███████</color><color=#12669dff>█</color><color=#1d4d6dff>█</color><color=#15355aff>█</color><color=#1d4d6dff>██████</color><color=#12669dff>███████████</color><color=#278fafff>█████████████████████████████████████████████████████</color><color=#12669dff>██</color><color=#278fafff>█</color><color=#12669dff>██████</color><color=#566b99ff>█</color><color=#12669dff>██</color><color=#566b99ff>███</color><color=#566870ff>█</color><color=#1d4d6dff>███</color><color=#15355aff>███</color><color=#1d4d6dff>████</color>\n<color=#1d4d6dff>███</color><color=#15355aff>█████████</color><color=#1d4d6dff>██████████</color><color=#12669dff>█</color><color=#1d4d6dff>██████</color><color=#12669dff>███████████</color><color=#278fafff>████████████████████████████████████████████████████████</color><color=#6591a4ff>█</color><color=#278fafff>█</color><color=#12669dff>████████</color><color=#566870ff>█</color><color=#1d4d6dff>█████████████</color></size>"

MacroNewNOCMD('floony.fun', 'kohr', 'koharu', 'ea19', 
    function()
        Request.dialogRaw('kohr',
            DialogField.create("kohr").description(outputText)
        )
        coroutine.yield()
    end, 
    true
)

-- // u stupood // --
MacroNewNOCMD(
    "floony.fun", "nineplusten", 
    "What's 9+10?", "ea5f",
    function()
        local cmd = Command.create("You stupid-")

        local function addArc(startTiming, endTiming, startX, endX, startY, endY)
            cmd.add(
                Event.arc(
                    startTiming,
                    xy(startX, startY),
                    endTiming,
                    xy(endX, endY),
                    true,
                    0,
                    "s",
                    Context.currentTimingGroup
                ).save()
            )
        end

        local startTiming = Context.currentTiming + Context.beatLengthAt(Context.currentTiming, Context.currentTimingGroup) / Context.beatlineDensity
        local endTiming = Context.currentTiming + Context.beatLengthAt(Context.currentTiming, Context.currentTimingGroup) / Context.beatlineDensity

        addArc(startTiming, endTiming, 0.90, 0.80, 0.20, 0.20)
        addArc(startTiming, endTiming, 1.00, 0.90, 0.00, 0.20)
        addArc(startTiming, endTiming, 0.55, 0.75, 0.60, 0.90)
        addArc(startTiming, endTiming, 0.55, 0.55, 0.70, 0.60)
        addArc(startTiming, endTiming, 0.65, 0.65, 0.00, 0.10)
        addArc(startTiming, endTiming, 0.35, 0.30, 0.10, 0.20)
        addArc(startTiming, endTiming, 0.05, 0.05, 0.20, 0.00)
        addArc(startTiming, endTiming, 0.40, 0.35, 1.00, 1.00)
        addArc(startTiming, endTiming, 0.40, 0.40, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.05, 0.40, 0.20, 0.70)
        addArc(startTiming, endTiming, 0.70, 0.75, 0.80, 0.70)
        addArc(startTiming, endTiming, 0.00, 0.20, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.75, 0.80, 1.00, 1.00)
        addArc(startTiming, endTiming, 0.80, 0.80, 0.00, 1.00)
        addArc(startTiming, endTiming, 0.00, 0.00, 0.00, 0.25)
        addArc(startTiming, endTiming, 0.38, 0.00, 0.75, 0.25)
        addArc(startTiming, endTiming, 0.00, 0.13, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.38, 0.38, 1.00, 0.75)
        addArc(startTiming, endTiming, 0.13, 0.38, 1.00, 1.00)
        addArc(startTiming, endTiming, 0.00, 0.35, 0.00, 0.00)
        addArc(startTiming, endTiming, 0.65, 1.00, 0.00, 0.00)
        addArc(startTiming, endTiming, 0.55, 0.75, 0.70, 1.00)
        addArc(startTiming, endTiming, 0.35, 0.35, 0.00, 0.10)
        addArc(startTiming, endTiming, 0.75, 0.75, 0.00, 1.00)

        cmd.commit()
        notify("21!")
    end
)

-- // Zydemon // --
    -- code by imrich (thanks) --
MacroNewNOCMD(
    "floony.fun", "zydemon",
    "Zydemon", "ef55",
    function ()
        -- Request timing and position
        local timingRequest = TrackInput.requestTiming("Select timing")
        coroutine.yield()
        local timing = timingRequest.result.timing
        
        local position = TrackInput.requestPosition(timing, "Select grid position")
        coroutine.yield()
        local xOffset = position.result["x"] - 0.5
        local yOffset = position.result["y"] - 0.5

        local cmd = Command.create("Add zydemon")
        local zydetg = Event.createTimingGroup("name=Zydemon, noarccap, noheightindicator")
        cmd.add(zydetg.save())

        local function addArc(startX, startY, endX, endY)
            local arcEvent = Event.arc(
                timing, 
                startX + xOffset, 
                startY + yOffset,
                timing,
                endX + xOffset, 
                endY + yOffset, 
                true, 
                0, 
                "s"
            )
            cmd.add(arcEvent.save().withTimingGroup(zydetg))
        end

        -- Add Zyde Trace
        addArc(0.68, 0.54, 0.62, 0.51)
        addArc(0.32, 0.32, 0.33, 0.25)
        addArc(0.30, 0.42, 0.37, 0.46)
        addArc(0.62, 0.64, 0.66, 0.71)
        addArc(0.66, 0.71, 0.68, 0.64)
        addArc(0.60, 0.35, 0.61, 0.35)
        addArc(0.43, 0.33, 0.43, 0.33)
        addArc(0.54, 0.26, 0.65, 0.25)
        addArc(0.65, 0.25, 0.67, 0.25)
        addArc(0.38, 0.36, 0.38, 0.35)
        addArc(0.39, 0.35, 0.40, 0.35)
        addArc(0.58, 0.49, 0.61, 0.49)
        addArc(0.69, 0.56, 0.68, 0.54)
        addArc(0.28, 0.92, 0.27, 1.00)
        addArc(0.31, 0.57, 0.32, 0.65)
        addArc(0.72, 0.47, 0.70, 0.28)
        addArc(0.34, 0.72, 0.42, 0.56)
        addArc(0.58, 0.36, 0.58, 0.39)
        addArc(0.27, 0.66, 0.29, 0.59)
        addArc(0.28, 0.50, 0.31, 0.69)
        addArc(0.41, 0.04, 0.34, 0.16)
        addArc(0.43, 0.38, 0.43, 0.44)
        addArc(0.39, 0.36, 0.39, 0.36)
        addArc(0.61, 0.49, 0.70, 0.44)
        addArc(0.43, 0.92, 0.52, 0.94)
        addArc(0.33, 0.35, 0.34, 0.35)
        addArc(0.33, 0.33, 0.32, 0.33)
        addArc(0.54, 0.30, 0.54, 0.26)
        addArc(0.34, 0.16, 0.29, 0.32)
        addArc(0.62, 0.51, 0.53, 0.51)
        addArc(0.52, 0.35, 0.54, 0.34)
        addArc(0.49, 0.37, 0.50, 0.37)
        addArc(0.32, 0.36, 0.33, 0.35)
        addArc(0.34, 0.35, 0.37, 0.35)
        addArc(0.73, 1.00, 0.75, 0.82)
        addArc(0.37, 0.35, 0.37, 0.35)
        addArc(0.44, 0.25, 0.54, 0.26)
        addArc(0.34, 0.80, 0.29, 0.88)
        addArc(0.39, 0.25, 0.39, 0.34)
        addArc(0.53, 0.51, 0.62, 0.64)
        addArc(0.47, 0.34, 0.47, 0.34)
        addArc(0.39, 0.34, 0.33, 0.33)
        addArc(0.68, 0.64, 0.69, 0.56)
        addArc(0.31, 0.43, 0.32, 0.36)
        addArc(0.40, 0.50, 0.34, 0.53)
        addArc(0.36, 0.83, 0.43, 0.92)
        addArc(0.48, 0.44, 0.58, 0.49)
        addArc(0.65, 0.13, 0.58, 0.03)
        addArc(0.67, 0.77, 0.71, 0.61)
        addArc(0.33, 0.25, 0.44, 0.25)
        addArc(0.38, 0.35, 0.39, 0.35)
        addArc(0.37, 0.37, 0.37, 0.46)
        addArc(0.58, 0.03, 0.49, 0.00)
        addArc(0.34, 0.53, 0.31, 0.57)
        addArc(0.31, 0.69, 0.36, 0.83)
        addArc(0.25, 0.78, 0.27, 0.66)
        addArc(0.39, 0.35, 0.39, 0.35)
        addArc(0.46, 0.51, 0.40, 0.50)
        addArc(0.43, 0.33, 0.43, 0.33)
        addArc(0.73, 1.00, 0.73, 1.00)
        addArc(0.49, 0.37, 0.58, 0.36)
        addArc(0.71, 0.61, 0.72, 0.47)
        addArc(0.32, 0.33, 0.32, 0.32)
        addArc(0.74, 0.72, 0.71, 0.60)
        addArc(0.54, 0.34, 0.54, 0.30)
        addArc(0.39, 0.34, 0.39, 0.34)
        addArc(0.40, 0.35, 0.40, 0.35)
        addArc(0.44, 0.34, 0.44, 0.35)
        addArc(0.43, 0.37, 0.49, 0.37)
        addArc(0.37, 0.35, 0.37, 0.37)
        addArc(0.58, 0.39, 0.58, 0.49)
        addArc(0.50, 0.37, 0.50, 0.39)
        addArc(0.66, 0.80, 0.70, 0.86)
        addArc(0.47, 0.34, 0.47, 0.26)
        addArc(0.60, 0.89, 0.67, 0.77)
        addArc(0.63, 0.34, 0.66, 0.34)
        addArc(0.29, 0.32, 0.28, 0.50)
        addArc(0.63, 0.34, 0.63, 0.34)
        addArc(0.49, 0.00, 0.41, 0.04)
        addArc(0.37, 0.46, 0.38, 0.36)
        addArc(0.70, 0.86, 0.73, 1.00)
        addArc(0.50, 0.39, 0.50, 0.41)
        addArc(0.50, 0.41, 0.49, 0.44)
        addArc(0.47, 0.34, 0.52, 0.35)
        addArc(0.59, 0.49, 0.60, 0.35)
        addArc(0.42, 0.56, 0.46, 0.51)
        addArc(0.70, 0.28, 0.65, 0.13)
        addArc(0.62, 0.37, 0.62, 0.37)
        addArc(0.62, 0.32, 0.62, 0.26)
        addArc(0.62, 0.32, 0.62, 0.32)
        addArc(0.39, 0.34, 0.39, 0.34)
        addArc(0.75, 0.82, 0.74, 0.72)
        addArc(0.39, 0.34, 0.39, 0.35)
        addArc(0.27, 1.00, 0.25, 0.78)
        addArc(0.46, 0.35, 0.47, 0.34)
        addArc(0.43, 0.33, 0.44, 0.34)
        addArc(0.37, 0.46, 0.48, 0.44)
        addArc(0.32, 0.65, 0.34, 0.72)
        addArc(0.40, 0.35, 0.43, 0.33)
        addArc(0.39, 0.35, 0.39, 0.36)
        addArc(0.54, 0.35, 0.55, 0.35)
        addArc(0.39, 0.36, 0.43, 0.36)
        addArc(0.55, 0.35, 0.62, 0.32)
        addArc(0.45, 0.35, 0.46, 0.35)
        addArc(0.52, 0.94, 0.60, 0.89)
        addArc(0.44, 0.35, 0.45, 0.35)
        addArc(0.61, 0.35, 0.62, 0.37)
        addArc(0.67, 0.28, 0.67, 0.26)
        addArc(0.67, 0.30, 0.67, 0.28)
        addArc(0.66, 0.33, 0.67, 0.30)
        addArc(0.62, 0.33, 0.66, 0.33)
        addArc(0.62, 0.32, 0.62, 0.33)
        addArc(0.66, 0.35, 0.67, 0.46)
        addArc(0.43, 0.36, 0.43, 0.38)
        addArc(0.66, 0.34, 0.66, 0.35)
        addArc(0.29, 0.88, 0.28, 0.92)
        addArc(0.63, 0.34, 0.63, 0.34)
        addArc(0.62, 0.36, 0.63, 0.34)
        addArc(0.62, 0.37, 0.62, 0.36)

        -- Add hair
        cmd.add(Event.arc(timing, 0.60 + xOffset, 0.89 + yOffset, timing, 0.45 + xOffset, 0.85 + yOffset, false, 0, "s").save().withTimingGroup(zydetg))
        cmd.add(Event.arc(timing, 0.45 + xOffset, 0.85 + yOffset, timing, 0.34 + xOffset, 0.74 + yOffset, false, 0, "s").save().withTimingGroup(zydetg))
        cmd.add(Event.arc(timing, 0.34 + xOffset, 0.74 + yOffset, timing, 0.30 + xOffset, 0.60 + yOffset, false, 0, "s").save().withTimingGroup(zydetg))
        cmd.commit()
    end
)

-- // CONTEXT MACRO // --
MacroNewNOCMD(
    "floony.fun", "contextmacro", 
    "Context Info", "f009",
    function()
        -- Helper to safely convert strings, tables (XY / arrays), and nil values
        local function s(val)
            if val == nil then return "nil" end
            if type(val) == "table" then
                if val.x ~= nil and val.y ~= nil then
                    return string.format("(%s, %s)", tostring(val.x), tostring(val.y))
                end
                return table.concat(val, ", ")
            end
            if type(val) == "function" then
                return "function"
            end
            return tostring(val)
        end

        local curTime = Context.currentTiming or 0
        local curGroup = Context.currentTimingGroup or 0

        -- Evaluate Context methods using the active timing & group
        local dropRate = pcall(function() return Context.dropRate(curGroup) end) and Context.dropRate(curGroup) or "N/A"
        local beatLen  = pcall(function() return Context.beatLengthAt(curTime, curGroup) end) and Context.beatLengthAt(curTime, curGroup) or "N/A"
        local bpmAt    = pcall(function() return Context.bpmAt(curTime, curGroup) end) and Context.bpmAt(curTime, curGroup) or "N/A"
        local divAt    = pcall(function() return Context.divisorAt(curTime, curGroup) end) and Context.divisorAt(curTime, curGroup) or "N/A"
        local floorPos = pcall(function() return Context.floorPositionAt(curTime, curGroup) end) and Context.floorPositionAt(curTime, curGroup) or "N/A"

        local dialogContext = {
            DialogField.create("macrocontext")
                .description(
                    "Drop Rate: " .. s(dropRate) .. " | " ..
                    "Offset: " .. s(Context.offset) .. " | " ..
                    "Judge Density: " .. s(Context.timingPointDensityFactor) .. " | " ..
                    "Beatline Density: " .. s(Context.beatlineDensity) .. " | " ..
                    "Language: " .. s(Context.language) .. "\n" ..
                    --
                    "Base BPM: " .. s(Context.baseBpm) .. " | " ..
                    "Song Length: " .. s(Context.songLength) .. " | " ..
                    "Max Combo: " .. s(Context.maxCombo) .. " | " ..
                    "Note Count: " .. s(Context.noteCount) .. "\n\n" ..
                    --
                    "Title: " .. s(Context.title) .. " | " ..
                    "Composer: " .. s(Context.composer) .. " | " ..
                    "Charter: " .. s(Context.charter) .. " | " ..
                    "Alias: " .. s(Context.alias) .. "\n\n" ..
                    --
                    "Difficulty: " .. s(Context.difficulty) .. " | " ..
                    "Difficulty Color: " .. s(Context.difficultyColor) .. " | " ..
                    "Chart Path: " .. s(Context.chartPath) .. " | " ..
                    "Side: " .. s(Context.side) .. "\n" ..
                    --
                    "Is Light?: " .. s(Context.isLight) .. " | " ..
                    "Current Arc Color: " .. s(Context.currentArcColor) .. " | " ..
                    "Max Arc Color: " .. s(Context.maxArcColor) .. "\n" ..
                    --
                    "Arc Types: " .. s(Context.allArcTypes) .. " | " ..
                    "Current Arc Type: " .. s(Context.currentArcType) .. " | " ..
                    "Is Void Mode?: " .. s(Context.currentIsVoidMode) .. " | " ..
                    "Is Trace Mode?: " .. s(Context.currentIsTraceMode) .. "\n" ..
                    --
                    "Current Timing Group: " .. s(Context.currentTimingGroup) .. " | " ..
                    "Total Timing Groups: " .. s(Context.timingGroupCount) .. " | " ..
                    "Current Timing: " .. s(Context.currentTiming) .. "\n" ..
                    --
                    "Screen Width: " .. s(Context.screenWidth) .. " | " ..
                    "Screen Height: " .. s(Context.screenHeight) .. " | " ..
                    "Aspect Ratio: " .. s(Context.screenAspectRatio) .. " | " ..
                    "Screen Middle: " .. s(Context.screenMiddle) .. "\n" ..
                    --
                    "\n" ..
                    "Beat Length at: " .. s(beatLen) .. " | " ..
                    "BPM at: " .. s(bpmAt) .. " | " ..
                    "Divisor at: " .. s(divAt) .. " | " ..
                    "Floor Position at: " .. s(floorPos) .. 
                    --
                    "\n\n" ..
                    "Clipboard: " .. s(Context.systemClipboard) ..
                    "\n\n\n\n\n\n"
                )
        }

        DialogInput.withTitle("Macro Context Info").requestInput(dialogContext)
    end,
    true
)

--------- TESTING

-- Anchor alignment factors: { xAlign (0=Left, 0.5=Center, 1=Right), yAlign (0=Bottom, 0.5=Middle, 1=Top) }
local ALIGN_MATRIX = {
    ["Center-Middle"] = {0.5, 0.5},
    ["Bottom-Center"] = {0.5, 0.0},
    ["Top-Left"]      = {0.0, 1.0},
    ["Bottom-Left"]   = {0.0, 0.0},
    ["Top-Right"]     = {1.0, 1.0}
}

-- Standard Vector Glyphs
local FONT_BASE = {
    -- UPPERCASE
    ["A"] = {{0,0, 0.5,1}, {0.5,1, 1,0}, {0.25,0.4, 0.75,0.4}},
    ["B"] = {{0,0, 0,1}, {0,1, 0.7,1}, {0.7,1, 0.9,0.75}, {0.9,0.75, 0.7,0.5}, {0.7,0.5, 0,0.5}, {0.7,0.5, 1,0.25}, {1,0.25, 0.7,0}, {0.7,0, 0,0}},
    ["C"] = {{1,0.8, 0.3,1}, {0.3,1, 0,0.7}, {0,0.7, 0,0.3}, {0,0.3, 0.3,0}, {0.3,0, 1,0.2}},
    ["D"] = {{0,0, 0,1}, {0,1, 0.6,1}, {0.6,1, 1,0.6}, {1,0.6, 1,0.4}, {1,0.4, 0.6,0}, {0.6,0, 0,0}},
    ["E"] = {{1,1, 0,1}, {0,1, 0,0}, {0,0, 1,0}, {0,0.5, 0.7,0.5}},
    ["F"] = {{1,1, 0,1}, {0,1, 0,0}, {0,0.5, 0.7,0.5}},
    ["G"] = {{1,0.8, 0.3,1}, {0.3,1, 0,0.7}, {0,0.7, 0,0.3}, {0,0.3, 0.3,0}, {0.3,0, 1,0}, {1,0, 1,0.4}, {1,0.4, 0.5,0.4}},
    ["H"] = {{0,0, 0,1}, {1,0, 1,1}, {0,0.5, 1,0.5}},
    ["I"] = {{0.2,1, 0.8,1}, {0.5,1, 0.5,0}, {0.2,0, 0.8,0}},
    ["J"] = {{0.2,1, 0.8,1}, {0.6,1, 0.6,0.3}, {0.6,0.3, 0.3,0}, {0.3,0, 0,0.3}},
    ["K"] = {{0,0, 0,1}, {1,1, 0,0.5}, {0,0.5, 1,0}},
    ["L"] = {{0,1, 0,0}, {0,0, 1,0}},
    ["M"] = {{0,0, 0,1}, {0,1, 0.5,0.4}, {0.5,0.4, 1,1}, {1,1, 1,0}},
    ["N"] = {{0,0, 0,1}, {0,1, 1,0}, {1,0, 1,1}},
    ["O"] = {{0.3,1, 0.7,1}, {0.7,1, 1,0.7}, {1,0.7, 1,0.3}, {1,0.3, 0.7,0}, {0.7,0, 0.3,0}, {0.3,0, 0,0.3}, {0,0.3, 0,0.7}, {0,0.7, 0.3,1}},
    ["P"] = {{0,0, 0,1}, {0,1, 0.7,1}, {0.7,1, 1,0.8}, {1,0.8, 0.7,0.5}, {0.7,0.5, 0,0.5}},
    ["Q"] = {{0.3,1, 0.7,1}, {0.7,1, 1,0.7}, {1,0.7, 1,0.3}, {1,0.3, 0.7,0}, {0.7,0, 0.3,0}, {0.3,0, 0,0.3}, {0,0.3, 0,0.7}, {0,0.7, 0.3,1}, {0.5,0.3, 1,-0.2}},
    ["R"] = {{0,0, 0,1}, {0,1, 0.7,1}, {0.7,1, 1,0.8}, {1,0.8, 0.7,0.5}, {0.7,0.5, 0,0.5}, {0.5,0.5, 1,0}},
    ["S"] = {{1,0.9, 0.3,1}, {0.3,1, 0,0.7}, {0,0.7, 1,0.3}, {1,0.3, 0.7,0}, {0.7,0, 0,0.1}},
    ["T"] = {{0,1, 1,1}, {0.5,1, 0.5,0}},
    ["U"] = {{0,1, 0,0.3}, {0,0.3, 0.3,0}, {0.3,0, 0.7,0}, {0.7,0, 1,0.3}, {1,0.3, 1,1}},
    ["V"] = {{0,1, 0.5,0}, {0.5,0, 1,1}},
    ["W"] = {{0,1, 0.2,0}, {0.2,0, 0.5,0.6}, {0.5,0.6, 0.8,0}, {0.8,0, 1,1}},
    ["X"] = {{0,0, 1,1}, {0,1, 1,0}},
    ["Y"] = {{0,1, 0.5,0.5}, {1,1, 0.5,0.5}, {0.5,0.5, 0.5,0}},
    ["Z"] = {{0,1, 1,1}, {1,1, 0,0}, {0,0, 1,0}},

    -- LOWERCASE
    ["a"] = {{0,0.3, 0.3,0.6}, {0.3,0.6, 0.7,0.6}, {0.7,0.6, 0.8,0.3}, {0.8,0.3, 0.8,0}, {0.8,0.3, 0,0.3}, {0,0.3, 0,0.1}, {0,0.1, 0.3,0}, {0.3,0, 0.8,0}},
    ["b"] = {{0,1, 0,0}, {0,0.3, 0.3,0.6}, {0.3,0.6, 0.7,0.6}, {0.7,0.6, 0.8,0.3}, {0.8,0.3, 0.7,0}, {0.7,0, 0,0}},
    ["c"] = {{0.8,0.5, 0.3,0.6}, {0.3,0.6, 0,0.3}, {0,0.3, 0.3,0}, {0.3,0, 0.8,0.1}},
    ["d"] = {{0.8,1, 0.8,0}, {0.8,0.3, 0.5,0.6}, {0.5,0.6, 0.1,0.6}, {0.1,0.6, 0,0.3}, {0,0.3, 0.1,0}, {0.1,0, 0.8,0}},
    ["e"] = {{0,0.3, 0.8,0.3}, {0.8,0.3, 0.8,0.5}, {0.8,0.5, 0.4,0.6}, {0.4,0.6, 0,0.3}, {0,0.3, 0.4,0}, {0.4,0, 0.8,0.1}},
    ["f"] = {{0.3,0, 0.3,0.8}, {0.3,0.8, 0.6,1}, {0.6,1, 0.8,1}, {0.1,0.5, 0.6,0.5}},
    ["g"] = {{0.8,0.6, 0.3,0.6}, {0.3,0.6, 0,0.4}, {0,0.4, 0.3,0}, {0.3,0, 0.8,0}, {0.8,0.6, 0.8,-0.2}, {0.8,-0.2, 0.4,-0.4}, {0.4,-0.4, 0,-0.2}},
    ["h"] = {{0,1, 0,0}, {0,0.4, 0.3,0.6}, {0.3,0.6, 0.7,0.6}, {0.7,0.6, 0.8,0.4}, {0.8,0.4, 0.8,0}},
    ["i"] = {{0.4,0.6, 0.4,0}, {0.4,0.8, 0.4,0.9}},
    ["j"] = {{0.6,0.6, 0.6,-0.2}, {0.6,-0.2, 0.3,-0.4}, {0.3,-0.4, 0,-0.2}, {0.6,0.8, 0.6,0.9}},
    ["k"] = {{0,1, 0,0}, {0.7,0.6, 0,0.2}, {0,0.2, 0.7,0}},
    ["l"] = {{0.4,1, 0.4,0.1}, {0.4,0.1, 0.7,0}},
    ["m"] = {{0,0.6, 0,0}, {0,0.4, 0.2,0.6}, {0.2,0.6, 0.4,0.4}, {0.4,0.4, 0.4,0}, {0.4,0.4, 0.6,0.6}, {0.6,0.6, 0.8,0.4}, {0.8,0.4, 0.8,0}},
    ["n"] = {{0,0.6, 0,0}, {0,0.4, 0.3,0.6}, {0.3,0.6, 0.7,0.6}, {0.7,0.6, 0.8,0.4}, {0.8,0.4, 0.8,0}},
    ["o"] = {{0.3,0.6, 0.7,0.6}, {0.7,0.6, 0.8,0.3}, {0.8,0.3, 0.7,0}, {0.7,0, 0.3,0}, {0.3,0, 0,0.3}, {0,0.3, 0.3,0.6}},
    ["p"] = {{0,0.6, 0,-0.4}, {0,0.4, 0.3,0.6}, {0.3,0.6, 0.7,0.6}, {0.7,0.6, 0.8,0.3}, {0.8,0.3, 0.7,0}, {0.7,0, 0,0}},
    ["q"] = {{0.8,0.6, 0.8,-0.4}, {0.8,0.3, 0.5,0.6}, {0.5,0.6, 0.1,0.6}, {0.1,0.6, 0,0.3}, {0,0.3, 0.1,0}, {0.1,0, 0.8,0}},
    ["r"] = {{0,0.6, 0,0}, {0,0.3, 0.3,0.6}, {0.3,0.6, 0.7,0.6}},
    ["s"] = {{0.8,0.5, 0.2,0.6}, {0.2,0.6, 0,0.4}, {0,0.4, 0.8,0.2}, {0.8,0.2, 0.6,0}, {0.6,0, 0,0.1}},
    ["t"] = {{0.3,0.9, 0.3,0.1}, {0.3,0.1, 0.6,0}, {0.1,0.6, 0.6,0.6}},
    ["u"] = {{0,0.6, 0,0.2}, {0,0.2, 0.3,0}, {0.3,0, 0.7,0}, {0.7,0, 0.8,0.2}, {0.8,0.6, 0.8,0}},
    ["v"] = {{0,0.6, 0.4,0}, {0.4,0, 0.8,0.6}},
    ["w"] = {{0,0.6, 0.2,0}, {0.2,0, 0.4,0.4}, {0.4,0.4, 0.6,0}, {0.6,0, 0.8,0.6}},
    ["x"] = {{0,0, 0.8,0.6}, {0,0.6, 0.8,0}},
    ["y"] = {{0,0.6, 0.4,0}, {0.8,0.6, 0.4,0}, {0.4,0, 0.2,-0.4}, {0.2,-0.4, 0,-0.3}},
    ["z"] = {{0,0.6, 0.8,0.6}, {0.8,0.6, 0,0}, {0,0, 0.8,0}},

    -- NUMBERS & SYMBOLS
    ["0"] = {{0.3,1, 0.7,1}, {0.7,1, 1,0.7}, {1,0.7, 1,0.3}, {1,0.3, 0.7,0}, {0.7,0, 0.3,0}, {0.3,0, 0,0.3}, {0,0.3, 0,0.7}, {0,0.7, 0.3,1}, {0.2,0.2, 0.8,0.8}},
    ["1"] = {{0.2,0.7, 0.5,1}, {0.5,1, 0.5,0}, {0.2,0, 0.8,0}},
    ["2"] = {{0,0.8, 0.3,1}, {0.3,1, 0.7,1}, {0.7,1, 1,0.7}, {1,0.7, 0,0}, {0,0, 1,0}},
    ["3"] = {{0,0.8, 0.3,1}, {0.3,1, 0.7,1}, {0.7,1, 1,0.7}, {1,0.7, 0.5,0.5}, {0.5,0.5, 1,0.3}, {1,0.3, 0.7,0}, {0.7,0, 0,0.2}},
    ["4"] = {{0.8,0, 0.8,1}, {0.8,1, 0,0.3}, {0,0.3, 1,0.3}},
    ["5"] = {{1,1, 0,1}, {0,1, 0,0.5}, {0,0.5, 0.7,0.5}, {0.7,0.5, 1,0.3}, {1,0.3, 0.7,0}, {0.7,0, 0,0}},
    ["6"] = {{0.8,1, 0.3,1}, {0.3,1, 0,0.6}, {0,0.6, 0,0.3}, {0,0.3, 0.4,0}, {0.4,0, 0.8,0}, {0.8,0, 1,0.3}, {1,0.3, 0.7,0.5}, {0.7,0.5, 0,0.5}},
    ["7"] = {{0,1, 1,1}, {1,1, 0.3,0}},
    ["8"] = {{0.3,1, 0.7,1}, {0.7,1, 1,0.75}, {1,0.75, 0,0.25}, {0,0.25, 0.3,0}, {0.3,0, 0.7,0}, {0.7,0, 1,0.25}, {1,0.25, 0,0.75}, {0,0.75, 0.3,1}},
    ["9"] = {{1,0.5, 0.3,0.5}, {0.3,0.5, 0,0.7}, {0,0.7, 0.2,1}, {0.2,1, 1,0.7}, {1,0.7, 1,0.3}, {1,0.3, 0.7,0}},
    ["!"] = {{0.5,1, 0.5,0.3}, {0.5,0.1, 0.5,0}},
    ["?"] = {{0,0.8, 0.3,1}, {0.3,1, 0.7,1}, {0.7,1, 1,0.7}, {1,0.7, 0.5,0.4}, {0.5,0.4, 0.5,0.25}, {0.5,0.1, 0.5,0}},
    ["-"] = {{0.2,0.5, 0.8,0.5}},
    ["+"] = {{0.2,0.5, 0.8,0.5}, {0.5,0.2, 0.5,0.8}},
    ["="] = {{0.2,0.6, 0.8,0.6}, {0.2,0.4, 0.8,0.4}},
    ["."] = {{0.4,0, 0.6,0}, {0.6,0, 0.6,0.15}, {0.6,0.15, 0.4,0.15}, {0.4,0.15, 0.4,0}},
    [":"] = {{0.4,0.7, 0.6,0.7}, {0.4,0.2, 0.6,0.2}},
    ["_"] = {{0,0, 1,0}}
}

-- LED Digital Clock Glyphs
local FONT_DIGITAL = {
    ["0"] = {{0,1, 1,1}, {1,1, 1,0}, {1,0, 0,0}, {0,0, 0,1}},
    ["1"] = {{0.8,1, 0.8,0}},
    ["2"] = {{0,1, 1,1}, {1,1, 1,0.5}, {1,0.5, 0,0.5}, {0,0.5, 0,0}, {0,0, 1,0}},
    ["3"] = {{0,1, 1,1}, {1,1, 1,0}, {0,0.5, 1,0.5}, {0,0, 1,0}},
    ["4"] = {{0,1, 0,0.5}, {0,0.5, 1,0.5}, {1,1, 1,0}},
    ["5"] = {{0,1, 1,1}, {0,1, 0,0.5}, {0,0.5, 1,0.5}, {1,0.5, 1,0}, {0,0, 1,0}},
    ["6"] = {{0,1, 1,1}, {0,1, 0,0}, {0,0, 1,0}, {1,0, 1,0.5}, {0,0.5, 1,0.5}},
    ["7"] = {{0,1, 1,1}, {1,1, 1,0}},
    ["8"] = {{0,1, 1,1}, {1,1, 1,0}, {1,0, 0,0}, {0,0, 0,1}, {0,0.5, 1,0.5}},
    ["9"] = {{0,1, 1,1}, {0,1, 0,0.5}, {0,0.5, 1,0.5}, {1,1, 1,0}, {0,0, 1,0}},
    [":"] = {{0.4,0.75, 0.6,0.75}, {0.6,0.75, 0.6,0.65}, {0.6,0.65, 0.4,0.65}, {0.4,0.65, 0.4,0.75},
             {0.4,0.35, 0.6,0.35}, {0.6,0.35, 0.6,0.25}, {0.6,0.25, 0.4,0.25}, {0.4,0.25, 0.4,0.35}},
    ["-"] = {{0,0.5, 1,0.5}},
    ["."] = {{0.4,0, 0.6,0}, {0.6,0, 0.6,0.15}, {0.6,0.15, 0.4,0.15}, {0.4,0.15, 0.4,0}},
    ["A"] = {{0,1, 1,1}, {0,1, 0,0}, {1,1, 1,0}, {0,0.5, 1,0.5}},
    ["B"] = {{0,1, 0.7,1}, {0.7,1, 1,0.75}, {1,0.75, 0.7,0.5}, {0.7,0.5, 0,0.5}, {0,1, 0,0}, {0.7,0.5, 1,0.25}, {1,0.25, 0.7,0}, {0.7,0, 0,0}},
    ["C"] = {{0,1, 1,1}, {0,1, 0,0}, {0,0, 1,0}},
    ["D"] = {{0,1, 0.7,1}, {0.7,1, 1,0.5}, {1,0.5, 0.7,0}, {0.7,0, 0,0}, {0,1, 0,0}},
    ["E"] = {{0,1, 1,1}, {0,1, 0,0}, {0,0, 1,0}, {0,0.5, 0.8,0.5}},
    ["F"] = {{0,1, 1,1}, {0,1, 0,0}, {0,0.5, 0.8,0.5}},
    ["G"] = {{0,1, 1,1}, {0,1, 0,0}, {0,0, 1,0}, {1,0, 1,0.5}, {0.5,0.5, 1,0.5}},
    ["H"] = {{0,1, 0,0}, {1,1, 1,0}, {0,0.5, 1,0.5}},
    ["I"] = {{0,1, 1,1}, {0.5,1, 0.5,0}, {0,0, 1,0}},
    ["J"] = {{1,1, 1,0}, {1,0, 0,0}, {0,0, 0,0.4}},
    ["K"] = {{0,1, 0,0}, {0,0.5, 1,1}, {0,0.5, 1,0}},
    ["L"] = {{0,1, 0,0}, {0,0, 1,0}},
    ["M"] = {{0,1, 0,0}, {0,1, 0.5,0.5}, {0.5,0.5, 1,1}, {1,1, 1,0}},
    ["N"] = {{0,1, 0,0}, {0,1, 1,0}, {1,1, 1,0}},
    ["O"] = {{0,1, 1,1}, {1,1, 1,0}, {1,0, 0,0}, {0,0, 0,1}},
    ["P"] = {{0,1, 1,1}, {0,1, 0,0}, {1,1, 1,0.5}, {0,0.5, 1,0.5}},
    ["Q"] = {{0,1, 1,1}, {1,1, 1,0}, {1,0, 0,0}, {0,0, 0,1}, {0.5,0.5, 1,0}},
    ["R"] = {{0,1, 1,1}, {0,1, 0,0}, {1,1, 1,0.5}, {0,0.5, 1,0.5}, {0.5,0.5, 1,0}},
    ["S"] = {{0,1, 1,1}, {0,1, 0,0.5}, {0,0.5, 1,0.5}, {1,0.5, 1,0}, {0,0, 1,0}},
    ["T"] = {{0,1, 1,1}, {0.5,1, 0.5,0}},
    ["U"] = {{0,1, 0,0}, {1,1, 1,0}, {0,0, 1,0}},
    ["V"] = {{0,1, 0,0.5}, {0,0.5, 0.5,0}, {0.5,0, 1,0.5}, {1,0.5, 1,1}},
    ["W"] = {{0,1, 0,0}, {0,0, 0.5,0.5}, {0.5,0.5, 1,0}, {1,0, 1,1}},
    ["X"] = {{0,1, 1,0}, {0,0, 1,1}},
    ["Y"] = {{0,1, 0.5,0.5}, {1,1, 0.5,0.5}, {0.5,0.5, 0.5,0}},
    ["Z"] = {{0,1, 1,1}, {1,1, 0,0}, {0,0, 1,0}}
}

local function transformPoint(x, y, style)
    if style == "Futuristic" then
        return x + (y * 0.22), y
    elseif style == "Fancy (Serifs & Swash Curls)" then
        return x + (y * 0.28), y + math.sin(x * math.pi) * 0.05
    elseif style == "Funny (Comic/Derp)" then
        local jX = (math.random() - 0.5) * 0.12
        local jY = (math.random() - 0.5) * 0.12
        return x + jX, (y * (0.8 + math.random() * 0.3)) + jY
    end
    return x, y
end

local function drawSwashCurl(cmd, p, timing, duration, color, tg, scale)
    local r = scale * 0.12
    local p1 = p + xy(-r, r)
    local p2 = p + xy(0, r * 1.5)
    cmd.add(Event.arc(timing, p, timing + duration, p1, true, color, "s", tg).save())
    cmd.add(Event.arc(timing, p1, timing + duration, p2, true, color, "s", tg).save())
end

local function getGlyphLines(dict, char)
    local upper = string.upper(char)
    return dict[char] or dict[upper] or FONT_BASE[char] or FONT_BASE[upper]
end

MacroNew(
    "floony.fun", "trace_text", 
    "Text to Trace", "e0bf",
    function(cmd)
        local timing, anchorPos = Request.timeAndPosition("Select spawn timing", "Select anchor position")

        local dialogFields = {
            DialogField.create("text")
                .setLabel("Text Content")
                .setHint("e.g., Hello or 12:34\\nWORLD")
                .setTooltip("The text to render as traces. Type '\\n' to add a line break.")
                .defaultTo("12:34\\nCLOCK")
                .textField(FieldConstraint.create().any()),

            DialogField.create("style")
                .setLabel("Font Style")
                .setHint("Pick a visual look")
                .setTooltip("Choose between LED Digital Clock, Clean Modern, Cyber Futuristic, Calligraphic Fancy, or Comic Derp.")
                .dropdownMenu("Digital (7-Segment Clock)", "Modern", "Futuristic", "Fancy (Serifs & Swash Curls)", "Funny (Comic/Derp)"),

            DialogField.create("anchor")
                .setLabel("Anchor Position")
                .setHint("Alignment reference point")
                .setTooltip("Which point of the text box aligns directly with where you tapped.")
                .dropdownMenu("Center-Middle", "Bottom-Center", "Top-Left", "Bottom-Left", "Top-Right"),

            DialogField.create("scale")
                .setLabel("Font Size")
                .setHint("Height of one line (default: 0.4)")
                .setTooltip("How tall each line of text will be on screen.")
                .defaultTo("0.4")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("lineSpacing")
                .setLabel("Line Gap")
                .setHint("Gap between lines (default: 0.3)")
                .setTooltip("The vertical space between lines when writing multiple lines.")
                .defaultTo("0.3")
                .textField(FieldConstraint.create().float().gEqual(0)),

            DialogField.create("duration")
                .setLabel("Duration (ms)")
                .setHint("0 = static shape, >0 = moving trace")
                .setTooltip("How long trace lines last. Leave at 0 for standard vector artwork.")
                .defaultTo("0")
                .textField(FieldConstraint.create().integer().gEqual(0)),

            DialogField.create("color")
                .setLabel("Color Slot")
                .setHint("0 to 7")
                .setTooltip("Arc color index assigned to the text traces.")
                .defaultTo("0")
                .textField(FieldConstraint.create().integer().gEqual(0).lEqual(7)),

            DialogField.create("drawBox")
                .setLabel("Show Alignment Box")
                .setHint("Draw border frame")
                .setTooltip("Draws a temporary rectangular trace box around your text to verify alignment.")
                .checkbox()
        }

        local dialogRequest = DialogInput.withTitle("Text to Trace Generator").requestInput(dialogFields)
        coroutine.yield()

        local rawText = string.gsub(dialogRequest.result["text"] or "12:34\\nCLOCK", "\\n", "\n")
        local fontStyle = dialogRequest.result["style"] or "Digital (7-Segment Clock)"
        local anchorType = dialogRequest.result["anchor"] or "Center-Middle"
        local scale = tonumber(dialogRequest.result["scale"]) or 0.4
        local lineSpacingMult = tonumber(dialogRequest.result["lineSpacing"]) or 0.3
        local duration = tonumber(dialogRequest.result["duration"]) or 0
        local color = tonumber(dialogRequest.result["color"]) or 0
        local drawBox = dialogRequest.result["drawBox"]
        local tg = Context.currentTimingGroup

        local charWidth = scale * 0.75
        local charSpacing = scale * 0.25
        local lineGap = scale * lineSpacingMult
        local activeFontDict = (fontStyle == "Digital (7-Segment Clock)") and FONT_DIGITAL or FONT_BASE

        local lineLayouts, maxLineWidth = {}, 0
        for lineStr in string.gmatch(rawText .. "\n", "(.-)\n") do
            local lineWidth = 0
            for i = 1, #lineStr do
                local char = lineStr:sub(i, i)
                lineWidth = lineWidth + ((char == " ") and (charWidth * 0.5) or (charWidth + charSpacing))
            end
            if #lineStr > 0 then lineWidth = lineWidth - charSpacing end

            table.insert(lineLayouts, { str = lineStr, width = lineWidth })
            if lineWidth > maxLineWidth then maxLineWidth = lineWidth end
        end

        local totalHeight = (#lineLayouts * scale) + ((#lineLayouts - 1) * lineGap)

        local align = ALIGN_MATRIX[anchorType] or {0.5, 0.5}
        local originX = anchorPos.x - (maxLineWidth * align[1])
        local originY = anchorPos.y - (totalHeight * align[2])

        if drawBox then
            local pad = scale * 0.15
            local x1, x2 = originX - pad, originX + maxLineWidth + pad
            local y1, y2 = originY - pad, originY + totalHeight + pad
            local boxPoints = { xy(x1, y1), xy(x2, y1), xy(x2, y2), xy(x1, y2) }

            for i = 1, 4 do
                local pA = boxPoints[i]
                local pB = boxPoints[(i % 4) + 1]
                cmd.add(Event.arc(timing, pA, timing + duration, pB, true, 3, "s", tg).save())
            end
        end

        for lineIdx, layout in ipairs(lineLayouts) do
            local lineStr = layout.str
            local lineY = originY + (#lineLayouts - lineIdx) * (scale + lineGap)
            local currentCharX = originX + (maxLineWidth - layout.width) * align[1]

            for i = 1, #lineStr do
                local char = lineStr:sub(i, i)

                if char == " " then
                    currentCharX = currentCharX + (charWidth * 0.5)
                else
                    local lines = getGlyphLines(activeFontDict, char)
                    if lines then
                        for seqIdx, line in ipairs(lines) do
                            local tx1, ty1 = transformPoint(line[1], line[2], fontStyle)
                            local tx2, ty2 = transformPoint(line[3], line[4], fontStyle)

                            local p1 = xy(currentCharX + (tx1 * charWidth), lineY + (ty1 * scale))
                            local p2 = xy(currentCharX + (tx2 * charWidth), lineY + (ty2 * scale))

                            cmd.add(Event.arc(timing, p1, timing + duration, p2, true, color, "s", tg).save())

                            if fontStyle == "Fancy (Serifs & Swash Curls)" and (seqIdx == 1 or seqIdx == #lines) then
                                drawSwashCurl(cmd, p1, timing, duration, color, tg, scale)
                            end
                        end
                    end
                    currentCharX = currentCharX + charWidth + charSpacing
                end
            end
        end
    end
)

MacroNew(
    "floony.fun", "arctap_pop",
    "ArcTap Pop Rings", "e5d6",
    function(cmd)
        local rawSel = Event.getCurrentSelection(EventSelectionConstraint.create().arctap())
        local arctaps = table.icollapse(rawSel, "arctap")

        if #arctaps == 0 then
            notify("Please select at least one ArcTap.")
            return false
        end

        local dialogFields = {
            DialogField.create("spikes")
                .setLabel("Spike Count")
                .defaultTo("4")
                .textField(FieldConstraint.create().integer().gEqual(3).lEqual(12)),
            DialogField.create("radius")
                .setLabel("Spike Distance")
                .defaultTo("0.15")
                .textField(FieldConstraint.create().float()),
            DialogField.create("duration")
                .setLabel("Duration (ms)")
                .defaultTo("30")
                .textField(FieldConstraint.create().integer().gEqual(0))
        }

        local dialogRequest = DialogInput.withTitle("ArcTap Pop Rings").requestInput(dialogFields)
        coroutine.yield()

        local spikeCount = tonumber(dialogRequest.result["spikes"]) or 4
        local radius = tonumber(dialogRequest.result["radius"]) or 0.15
        local duration = tonumber(dialogRequest.result["duration"]) or 30

        for _, tap in ipairs(arctaps) do
            local arc = tap.arc
            if arc then
                local centerPos = arc.positionAt(tap.timing)
                local stepAngle = (2 * math.pi) / spikeCount

                for i = 0, spikeCount - 1 do
                    local angle = i * stepAngle
                    local dx = math.cos(angle) * radius
                    local dy = math.sin(angle) * radius

                    local spikeStart = centerPos
                    local spikeEnd = centerPos + xy(dx, dy)

                    local spike = Event.arc(
                        tap.timing, spikeStart,
                        tap.timing + duration, spikeEnd,
                        true, 0, "s", tap.timingGroup
                    )
                    cmd.add(spike.save())
                end
            end
        end
    end
)

-- // MORE FUN DECO MACRO // --
FolderNew('floony.fun', 'floony.morefun', 'ea4b', '- The funny (Adv) -')
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------


MacroNew(
    "floony.morefun", "matrix_rain",
    "Matrix Rain", "e65f",
    function(cmd)
        local tStart, tEnd = Request.timeRange()

        local dialogFields = {
            DialogField.create("columns")
                .setLabel("Columns")
                .setTooltip("Number of falling rain streams")
                .defaultTo("12")
                .textField(FieldConstraint.create().integer().gEqual(1)),
            DialogField.create("dropLength")
                .setLabel("Drop Duration (ms)")
                .setTooltip("How fast each code drop falls")
                .defaultTo("300")
                .textField(FieldConstraint.create().integer().gEqual(50)),
            DialogField.create("density")
                .setLabel("Spawn Interval (ms)")
                .defaultTo("100")
                .textField(FieldConstraint.create().integer().gEqual(20))
        }

        local dialogRequest = DialogInput.withTitle("Matrix Code Waterfall").requestInput(dialogFields)
        coroutine.yield()

        local columns = tonumber(dialogRequest.result["columns"]) or 12
        local dropLen = tonumber(dialogRequest.result["dropLength"]) or 300
        local interval = tonumber(dialogRequest.result["density"]) or 100

        -- Setup Matrix TG
        local tgName = "$floony.matrix"
        local matrixTG = nil
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.name == tgName then matrixTG = group; break end
        end

        if not matrixTG then
            matrixTG = Event.createTimingGroup('name="' .. tgName .. '", noinput')
            cmd.add(matrixTG.save())
        end

        local colWidth = 2.0 / columns

        for t = tStart, tEnd - interval, interval do
            local colIdx = math.random(0, columns - 1)
            local posX = -0.5 + (colIdx * colWidth) + math.randomf(0, colWidth * 0.5)
            local startY = math.randomf(2, 3)
            local endY = math.randomf(-0.2, 0.2)

            -- Green/Cyan color indexes (2 = green, 3 = yellow/green)
            local color = math.random() < 0.8 and 2 or 3

            local rainDrop = Event.arc(
                t, xy(posX, startY),
                t + dropLen, xy(posX, endY),
                true, color, "s"
            )
            cmd.add(rainDrop.save().withTimingGroup(matrixTG))
        end
    end
)

MacroNew(
    "floony.morefun", "particle_ring",
    "Orbiting Particle Ring", "e577",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local centerPos = Request.position(tStart, "Select center origin for particle orbit")

        local dialogFields = {
            DialogField.create("count")
                .setLabel("Particle Count")
                .defaultTo("6")
                .textField(FieldConstraint.create().integer().gEqual(1).lEqual(16)),
            DialogField.create("radius")
                .setLabel("Orbit Radius")
                .defaultTo("0.3")
                .textField(FieldConstraint.create().float().greater(0)),
            DialogField.create("revsPerSec")
                .setLabel("Revolutions / Sec")
                .defaultTo("1.0")
                .textField(FieldConstraint.create().float()),
            DialogField.create("stepRes")
                .setLabel("Step Resolution (ms)")
                .defaultTo("40")
                .textField(FieldConstraint.create().integer().gEqual(10)),
            DialogField.create("color")
                .setLabel("Color Index")
                .defaultTo("0")
                .textField(FieldConstraint.create().integer().gEqual(0).lEqual(7))
        }

        local dialogRequest = DialogInput.withTitle("Orbiting Particle Ring").requestInput(dialogFields)
        coroutine.yield()

        local count = tonumber(dialogRequest.result["count"]) or 6
        local radius = tonumber(dialogRequest.result["radius"]) or 0.3
        local revsPerSec = tonumber(dialogRequest.result["revsPerSec"]) or 1.0
        local step = tonumber(dialogRequest.result["stepRes"]) or 40
        local color = tonumber(dialogRequest.result["color"]) or 0

        -- Setup Orbit TG
        local tgName = "$floony.orbit"
        local orbitTG = nil
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.name == tgName then orbitTG = group; break end
        end

        if not orbitTG then
            orbitTG = Event.createTimingGroup('name="' .. tgName .. '", noinput')
            cmd.add(orbitTG.save())
        end

        local stepAngleOffset = (2 * math.pi) / count
        local radPerMs = (revsPerSec * 2 * math.pi) / 1000

        for t = tStart, tEnd - step, step do
            local baseAngle1 = (t - tStart) * radPerMs
            local baseAngle2 = ((t + step) - tStart) * radPerMs

            for i = 0, count - 1 do
                local phi1 = baseAngle1 + (i * stepAngleOffset)
                local phi2 = baseAngle2 + (i * stepAngleOffset)

                local p1 = centerPos + xy(math.cos(phi1) * radius, math.sin(phi1) * radius)
                local p2 = centerPos + xy(math.cos(phi2) * radius, math.sin(phi2) * radius)

                local particleArc = Event.arc(
                    t, p1,
                    t + step, p2,
                    true, color, "s"
                )
                cmd.add(particleArc.save().withTimingGroup(orbitTG))
            end
        end
    end
)

MacroNew(
    "floony.morefun", "metronome_arm",
    "Swinging Metronome Arm", "eba7",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local pivot = Request.position(tStart, "Select metronome base pivot point")
        local tg = Context.currentTimingGroup
        local beatLen = Context.beatLengthAt(tStart, tg)

        local dialogRequest = DialogInput.withTitle("Swinging Metronome Arm").requestInput({
            DialogField.create("armLength")
                .setLabel("Arm Length")
                .setTooltip("Length of the swinging metronome arm.")
                .defaultTo("0.6")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("maxAngle")
                .setLabel("Max Swing Angle (Degrees)")
                .setTooltip("Maximum swing tilt angle on each side.")
                .defaultTo("45")
                .textField(FieldConstraint.create().float().greater(0))
        })
        coroutine.yield()

        local armLen = tonumber(dialogRequest.result["armLength"]) or 0.6
        local maxAngleRad = math.rad(tonumber(dialogRequest.result["maxAngle"]) or 45)
        local stepMs = 30

        for t = tStart, tEnd - stepMs, stepMs do
            local beatProgress = ((t - tStart) % (beatLen * 2)) / (beatLen * 2)
            local currentAngle = math.sin(beatProgress * 2 * math.pi) * maxAngleRad

            local tipPos = pivot + xy(math.sin(currentAngle) * armLen, math.cos(currentAngle) * armLen)
            cmd.add(Event.arc(t, pivot, t + stepMs, tipPos, true, 0, "s", tg).save())
        end
    end
)

MacroNew(
    "floony.morefun", "dna_helix",
    "DNA Double Helix", "e577",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("DNA Double Helix").requestInput({
            DialogField.create("rotations")
                .setLabel("Full Helix Turns")
                .setTooltip("How many times the strands twist around each other.")
                .defaultTo("3")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("radius")
                .setLabel("Strand Distance Radius")
                .setTooltip("Width of the spiraling helix tube.")
                .defaultTo("0.3")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("rungs")
                .setLabel("Base Rung Count")
                .setTooltip("Number of connecting cross-links between the two strands.")
                .defaultTo("12")
                .textField(FieldConstraint.create().integer().gEqual(2))
        })
        coroutine.yield()

        local turns = tonumber(dialogRequest.result["rotations"]) or 3.0
        local radius = tonumber(dialogRequest.result["radius"]) or 0.3
        local rungCount = tonumber(dialogRequest.result["rungs"]) or 12
        local dur = tEnd - tStart
        local stepMs = 20

        -- Generate intertwined dual strands
        for t = tStart, tEnd - stepMs, stepMs do
            local p1 = (t - tStart) / dur
            local p2 = ((t + stepMs) - tStart) / dur

            local a1_A = p1 * (turns * 2 * math.pi)
            local a2_A = p2 * (turns * 2 * math.pi)
            local a1_B = a1_A + math.pi
            local a2_B = a2_A + math.pi

            local xCenter = math.lerp(0.0, 1.0, p1)
            local xCenterNext = math.lerp(0.0, 1.0, p2)

            local posA1 = xy(xCenter + math.cos(a1_A) * radius, 0.5 + math.sin(a1_A) * radius)
            local posA2 = xy(xCenterNext + math.cos(a2_A) * radius, 0.5 + math.sin(a2_A) * radius)
            local posB1 = xy(xCenter + math.cos(a1_B) * radius, 0.5 + math.sin(a1_B) * radius)
            local posB2 = xy(xCenterNext + math.cos(a2_B) * radius, 0.5 + math.sin(a2_B) * radius)

            cmd.add(Event.arc(t, posA1, t + stepMs, posA2, true, 0, "s", tg).save())
            cmd.add(Event.arc(t, posB1, t + stepMs, posB2, true, 1, "s", tg).save())
        end

        -- Generate connecting rungs
        local rungInterval = dur / rungCount
        for i = 0, rungCount do
            local tRung = tStart + (i * rungInterval)
            local p = (tRung - tStart) / dur
            local angle = p * (turns * 2 * math.pi)
            local xCenter = math.lerp(0.0, 1.0, p)

            local pA = xy(xCenter + math.cos(angle) * radius, 0.5 + math.sin(angle) * radius)
            local pB = xy(xCenter + math.cos(angle + math.pi) * radius, 0.5 + math.sin(angle + math.pi) * radius)

            cmd.add(Event.arc(tRung, pA, tRung + 30, pB, true, 2, "s", tg).save())
        end
    end
)

MacroNew(
    "floony.morefun", "radar_sweep",
    "Radar Sweep Scanner", "e65f",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local center = Request.position(tStart, "Select radar center position")
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Radar Sweep Scanner").requestInput({
            DialogField.create("radius")
                .setLabel("Radar Dish Radius")
                .setTooltip("Radius of the circular radar beam sweep.")
                .defaultTo("0.6")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("revs")
                .setLabel("Revolutions Count")
                .setTooltip("How many 360-degree sweeps to perform across the time range.")
                .defaultTo("2")
                .textField(FieldConstraint.create().integer().gEqual(1))
        })
        coroutine.yield()

        local radius = tonumber(dialogRequest.result["radius"]) or 0.6
        local revs = tonumber(dialogRequest.result["revs"]) or 2
        local stepMs = 30
        local totalDur = tEnd - tStart

        for t = tStart, tEnd - stepMs, stepMs do
            local progress = (t - tStart) / totalDur
            local angle = progress * (revs * 2 * math.pi)

            local beamEnd = center + xy(math.cos(angle) * radius, math.sin(angle) * radius)
            cmd.add(Event.arc(t, center, t + stepMs, beamEnd, true, 2, "s", tg).save())
        end
    end
)

MacroNew(
    "floony.morefun", "synth_sun",
    "Synthwave Sun Horizon", "e244",
    function(cmd)
        local tStart = Request.time("Select sun spawn timing")
        local center = Request.position(tStart, "Select sun center position")
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Synthwave Sun Horizon").requestInput({
            DialogField.create("sunRadius")
                .setLabel("Sun Radius")
                .setTooltip("Overall radius of the vector sun.")
                .defaultTo("0.4")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("cutouts")
                .setLabel("Cutout Bars Count")
                .setTooltip("Number of horizontal stripe gaps in the sun.")
                .defaultTo("5")
                .textField(FieldConstraint.create().integer().gEqual(2).lEqual(10)),

            DialogField.create("duration")
                .setLabel("Display Duration (ms)")
                .setTooltip("How long the sun remains visible.")
                .defaultTo("500")
                .textField(FieldConstraint.create().integer().gEqual(50))
        })
        coroutine.yield()

        local radius = tonumber(dialogRequest.result["sunRadius"]) or 0.4
        local cutouts = tonumber(dialogRequest.result["cutouts"]) or 5
        local dur = tonumber(dialogRequest.result["duration"]) or 500

        -- Top half circular arc
        local samples = 12
        for i = 0, samples - 1 do
            local a1 = (i / samples) * math.pi
            local a2 = ((i + 1) / samples) * math.pi

            local p1 = center + xy(math.cos(a1) * radius, math.sin(a1) * radius)
            local p2 = center + xy(math.cos(a2) * radius, math.sin(a2) * radius)

            cmd.add(Event.arc(tStart, p1, tStart + dur, p2, true, 3, "s", tg).save())
        end

        -- Lower horizontal cutout bars
        for k = 1, cutouts do
            local yOffset = -(k / (cutouts + 1)) * radius
            local barWidth = math.sqrt(math.max(0, (radius ^ 2) - (yOffset ^ 2)))

            local p1 = center + xy(-barWidth, yOffset)
            local p2 = center + xy(barWidth, yOffset)

            cmd.add(Event.arc(tStart, p1, tStart + dur, p2, true, 3, "s", tg).save())
        end
    end
)

MacroNew(
    "floony.morefun", "clock_gears",
    "Analog Chrono Clock", "e0bf",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local center = Request.position(tStart, "Select clock center position")
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Analog Chrono Clock").requestInput({
            DialogField.create("clockRadius")
                .setLabel("Clock Face Radius")
                .setTooltip("Overall radius of the clock face.")
                .defaultTo("0.4")
                .textField(FieldConstraint.create().float().greater(0))
        })
        coroutine.yield()

        local radius = tonumber(dialogRequest.result["clockRadius"]) or 0.4
        local dur = tEnd - tStart
        local stepMs = 30

        -- Draw 12 hour tick marks
        for h = 0, 11 do
            local angle = (h / 12) * (2 * math.pi)
            local p1 = center + xy(math.cos(angle) * (radius * 0.85), math.sin(angle) * (radius * 0.85))
            local p2 = center + xy(math.cos(angle) * radius, math.sin(angle) * radius)

            cmd.add(Event.arc(tStart, p1, tEnd, p2, true, 0, "s", tg).save())
        end

        -- Animated second and minute hands
        for t = tStart, tEnd - stepMs, stepMs do
            local progress = (t - tStart) / dur
            local secAngle = progress * (2 * math.pi * 2) -- 2 full revolutions
            local minAngle = progress * (2 * math.pi * 0.25)

            local pSec = center + xy(math.sin(secAngle) * (radius * 0.8), math.cos(secAngle) * (radius * 0.8))
            local pMin = center + xy(math.sin(minAngle) * (radius * 0.5), math.cos(minAngle) * (radius * 0.5))

            cmd.add(Event.arc(t, center, t + stepMs, pSec, true, 1, "s", tg).save())
            cmd.add(Event.arc(t, center, t + stepMs, pMin, true, 2, "s", tg).save())
        end
    end
)

MacroNew(
    "floony.morefun", "waveform_display",
    "Oscilloscope Waveform", "eba7",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Oscilloscope Waveform").requestInput({
            DialogField.create("frequency")
                .setLabel("Wave Frequency")
                .setTooltip("How many wave peaks cross the screen.")
                .defaultTo("4")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("amplitude")
                .setLabel("Wave Height")
                .setTooltip("Peak height of the waveform.")
                .defaultTo("0.3")
                .textField(FieldConstraint.create().float().greater(0))
        })
        coroutine.yield()

        local freq = tonumber(dialogRequest.result["frequency"]) or 4.0
        local amp = tonumber(dialogRequest.result["amplitude"]) or 0.3
        local stepMs = 40
        local dur = tEnd - tStart

        for t = tStart, tEnd - stepMs, stepMs do
            local phase = ((t - tStart) / dur) * (math.pi * 4)
            local samples = 16

            for i = 0, samples - 1 do
                local x1 = math.lerp(-0.5, 1.5, i / samples)
                local x2 = math.lerp(-0.5, 1.5, (i + 1) / samples)

                local y1 = 0.5 + math.sin(phase + ((i / samples) * freq * 2 * math.pi)) * amp
                local y2 = 0.5 + math.sin(phase + (((i + 1) / samples) * freq * 2 * math.pi)) * amp

                cmd.add(Event.arc(t, xy(x1, y1), t + stepMs, xy(x2, y2), true, 2, "s", tg).save())
            end
        end
    end
)

MacroNew(
    "floony.morefun", "pong_bounce",
    "Pong Breakout Game", "e3fc",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Pong Breakout Game").requestInput({
            DialogField.create("paddleWidth")
                .setLabel("Paddle Width")
                .setTooltip("Width of the moving player paddle.")
                .defaultTo("0.3")
                .textField(FieldConstraint.create().float().greater(0))
        })
        coroutine.yield()

        local padW = tonumber(dialogRequest.result["paddleWidth"]) or 0.3
        local stepMs = 30

        local ballPos = xy(0.5, 0.8)
        local ballVel = xy(0.02, -0.025)

        -- Helper to replace non-existent math.clamp in standard Lua
        local function clamp(val, minVal, maxVal)
            return math.min(math.max(val, minVal), maxVal)
        end

        for t = tStart, tEnd - stepMs, stepMs do
            local nextPos = ballPos + ballVel

            -- Wall collisions
            if nextPos.x <= -0.5 or nextPos.x >= 1.5 then ballVel = xy(-ballVel.x, ballVel.y) end
            if nextPos.y >= 1.2 then ballVel = xy(ballVel.x, -ballVel.y) end

            -- Floor paddle bounce collision
            if nextPos.y <= 0.0 then
                ballVel = xy(ballVel.x, math.abs(ballVel.y))
            end

            nextPos = xy(clamp(ballPos.x + ballVel.x, -0.5, 1.5), clamp(ballPos.y + ballVel.y, 0.0, 1.2))

            -- Render bouncing ball trace
            cmd.add(Event.arc(t, ballPos, t + stepMs, nextPos, true, 1, "s", tg).save())

            -- Render tracking paddle at floor level
            local padX1 = nextPos.x - (padW * 0.5)
            local padX2 = nextPos.x + (padW * 0.5)
            cmd.add(Event.arc(t, xy(padX1, 0.0), t + stepMs, xy(padX2, 0.0), true, 0, "s", tg).save())

            ballPos = nextPos
        end
    end
)

MacroNew(
    "floony.morefun", "wireframe_cube",
    "3D Wireframe Rotating Cube", "e577",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local center = Request.position(tStart, "Select cube center origin")
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("3D Wireframe Rotating Cube").requestInput({
            DialogField.create("size")
                .setLabel("Cube Size")
                .setTooltip("Overall scale of the 3D cube.")
                .defaultTo("0.3")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("rotSpeed")
                .setLabel("Rotation Speed")
                .setTooltip("Speed of the 3D spin animation.")
                .defaultTo("1.5")
                .textField(FieldConstraint.create().float())
        })
        coroutine.yield()

        local scale = tonumber(dialogRequest.result["size"]) or 0.3
        local rotSpeed = tonumber(dialogRequest.result["rotSpeed"]) or 1.5
        local stepMs = 30

        -- 8 vertices of a unit cube (-1 to 1)
        local vertices = {
            {-1, -1, -1}, { 1, -1, -1}, { 1,  1, -1}, {-1,  1, -1},
            {-1, -1,  1}, { 1, -1,  1}, { 1,  1,  1}, {-1,  1,  1}
        }

        -- 12 connecting edges between vertices
        local edges = {
            {1,2}, {2,3}, {3,4}, {4,1},
            {5,6}, {6,7}, {7,8}, {8,5},
            {1,5}, {2,6}, {3,7}, {4,8}
        }

        -- 3D to 2D Perspective Projection Helper
        local function project3D(v, angleX, angleY)
            -- Rotate Y
            local x1 = v[1] * math.cos(angleY) + v[3] * math.sin(angleY)
            local z1 = -v[1] * math.sin(angleY) + v[3] * math.cos(angleY)
            -- Rotate X
            local y2 = v[2] * math.cos(angleX) - z1 * math.sin(angleX)
            local z2 = v[2] * math.sin(angleX) + z1 * math.cos(angleX)

            local dist = 3.0 -- Camera distance
            local projX = center.x + (x1 * scale) / (1 + z2 / dist)
            local projY = center.y + (y2 * scale) / (1 + z2 / dist)
            return xy(projX, projY)
        end

        for t = tStart, tEnd - stepMs, stepMs do
            local angle = ((t - tStart) / 1000) * rotSpeed
            local angleX = angle * 0.7
            local angleY = angle * 1.1

            for _, edge in ipairs(edges) do
                local p1 = project3D(vertices[edge[1]], angleX, angleY)
                local p2 = project3D(vertices[edge[2]], angleX, angleY)

                cmd.add(Event.arc(t, p1, t + stepMs, p2, true, 0, "s", tg).save())
            end
        end
    end
)

MacroNew(
    "floony.morefun", "neon_horizon",
    "Neon Horizon Grid", "ebaa",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Neon Horizon Grid").requestInput({
            DialogField.create("fanLines")
                .setLabel("Perspective Fan Lines")
                .setTooltip("Number of vertical perspective lines radiating from horizon.")
                .defaultTo("8")
                .textField(FieldConstraint.create().integer().gEqual(2).lEqual(16))
        })
        coroutine.yield()

        local fanCount = tonumber(dialogRequest.result["fanLines"]) or 8
        local horizonY = 0.75
        local floorY = -0.3

        -- Static perspective longitudinal lines
        for i = 0, fanCount do
            local p = i / fanCount
            local xFloor = math.lerp(-1.5, 2.5, p)
            local xHorizon = math.lerp(0.1, 0.9, p)

            cmd.add(Event.arc(tStart, xy(xFloor, floorY), tEnd, xy(xHorizon, horizonY), true, 1, "s", tg).save())
        end

        -- Animated scrolling horizontal grid bars
        local barCycleMs = 300
        local stepMs = 30

        for t = tStart, tEnd - stepMs, stepMs do
            local progress = ((t - tStart) % barCycleMs) / barCycleMs
            local curY = math.lerp(horizonY, floorY, progress ^ 2)

            local leftX = math.lerp(0.1, -1.5, progress)
            local rightX = math.lerp(0.9, 2.5, progress)

            cmd.add(Event.arc(t, xy(leftX, curY), t + stepMs, xy(rightX, curY), true, 0, "s", tg).save())
        end
    end
)

MacroNew(
    "floony.morefun", "digital_timer",
    "Vector 7-Segment Digital Clock", "e0bf",
    function(cmd)
        local tStart = Request.time("Select timer start timing")
        local pos = Request.position(tStart, "Select timer top-left position")

        local dialogRequest = DialogInput.withTitle("Vector Digital Timer").requestInput({
            DialogField.create("seconds")
                .setLabel("Countdown Seconds")
                .setTooltip("How many seconds to count down.")
                .defaultTo("5")
                .textField(FieldConstraint.create().integer().gEqual(1).lEqual(9))
        })
        coroutine.yield()

        local totalSec = tonumber(dialogRequest.result["seconds"]) or 5

        -- Create or reuse a dedicated Timing Group
        local tgName = "$floony.timer"
        local timerTG = nil
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.name == tgName then timerTG = group; break end
        end

        if not timerTG then
            timerTG = Event.createTimingGroup('name="' .. tgName .. '", noinput')
            cmd.add(timerTG.save())
        end

        -- 7-segment lines definition for digits 0-9
        local segmentMap = {
            [0] = {1,2,3,4,5,6},    [1] = {2,3},          [2] = {1,2,7,5,4},
            [3] = {1,2,7,3,4},      [4] = {6,7,2,3},      [5] = {1,6,7,3,4},
            [6] = {1,6,5,4,3,7},    [7] = {1,2,3},        [8] = {1,2,3,4,5,6,7},
            [9] = {1,2,3,4,6,7}
        }

        local w, h = 0.2, 0.35
        local segs = {
            { xy(0, h), xy(w, h) },     -- 1: Top
            { xy(w, h), xy(w, h*0.5) }, -- 2: Top-Right
            { xy(w, h*0.5), xy(w, 0) }, -- 3: Bottom-Right
            { xy(0, 0), xy(w, 0) },     -- 4: Bottom
            { xy(0, 0), xy(0, h*0.5) }, -- 5: Bottom-Left
            { xy(0, h*0.5), xy(0, h) }, -- 6: Top-Left
            { xy(0, h*0.5), xy(w, h*0.5) } -- 7: Middle
        }

        for sec = totalSec, 0, -1 do
            local secStart = tStart + ((totalSec - sec) * 1000)
            local secEnd = secStart + 950
            local activeSegments = segmentMap[sec] or segmentMap[0]

            -- Freeze current digit in place
            cmd.add(Event.timing(secStart, 0.01, 999, 0).save().withTimingGroup(timerTG))

            -- Draw digit traces inside the dedicated Timing Group
            for _, segIdx in ipairs(activeSegments) do
                local line = segs[segIdx]
                local p1 = pos + line[1]
                local p2 = pos + line[2]

                cmd.add(Event.arc(secStart, p1, secEnd, p2, true, 2, "s", 0).save().withTimingGroup(timerTG))
            end

            -- High-speed BPM burst to clear digit before the next one appears
            cmd.add(Event.timing(secEnd, 999999, 999, 0).save().withTimingGroup(timerTG))
        end

        -- Restore normal song tempo inside the timer group at the end
        local tFinal = tStart + ((totalSec + 1) * 1000)
        local normalBpm = Context.bpmAt(tFinal, Context.currentTimingGroup)
        cmd.add(Event.timing(tFinal, normalBpm, Context.beatlineDensity, 0).save().withTimingGroup(timerTG))
    end
)

MacroNew(
    "floony.morefun", "glitch_tear",
    "Glitch Video Slice Tearing", "ec1c",
    function(cmd)
        local rawSel = Event.getCurrentSelection(EventSelectionConstraint.create().arc())
        local selectedArcs = table.icollapse(rawSel, "arc")

        if #selectedArcs == 0 then
            notify("Please select at least one arc.")
            return false
        end

        local dialogRequest = DialogInput.withTitle("Glitch Video Slice Tearing").requestInput({
            DialogField.create("slices")
                .setLabel("Slice Count")
                .setTooltip("How many horizontal slice layers to split the arc into.")
                .defaultTo("6")
                .textField(FieldConstraint.create().integer().gEqual(2).lEqual(20)),

            DialogField.create("maxShift")
                .setLabel("Max Shift Offset")
                .setTooltip("Maximum horizontal displacement distance.")
                .defaultTo("0.25")
                .textField(FieldConstraint.create().float().greater(0))
        })
        coroutine.yield()

        local sliceCount = tonumber(dialogRequest.result["slices"]) or 6
        local maxShift = tonumber(dialogRequest.result["maxShift"]) or 0.25

        for _, arc in ipairs(selectedArcs) do
            local tStart, tEnd = arc.timing, arc.endTiming
            local totalDur = tEnd - tStart

            if totalDur > sliceCount then
                cmd.add(arc.delete())
                local stepTime = totalDur / sliceCount

                for i = 0, sliceCount - 1 do
                    local t1 = tStart + (i * stepTime)
                    local t2 = tStart + ((i + 1) * stepTime)

                    local p1 = arc.positionAt(t1)
                    local p2 = arc.positionAt(t2)

                    -- Apply horizontal glitch tear shift
                    local shiftX = math.randomf(-maxShift, maxShift)
                    local shiftedP1 = p1 + xy(shiftX, 0)
                    local shiftedP2 = p2 + xy(shiftX, 0)

                    local segArc = Event.arc(t1, shiftedP1, t2, shiftedP2, arc.isVoid, arc.color, "s", arc.timingGroup)
                    cmd.add(segArc.save())
                end
            end
        end
    end
)

MacroNew(
    "floony.morefun", "tunnel_wave",
    "Perspective Tunnel Wave", "eba7",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Perspective Tunnel Wave").requestInput({
            DialogField.create("ringWaves")
                .setLabel("Expanding Rings")
                .setTooltip("Number of expanding ring waves over time.")
                .defaultTo("6")
                .textField(FieldConstraint.create().integer().gEqual(2).lEqual(20)),

            DialogField.create("expandTime")
                .setLabel("Ring Travel Time (ms)")
                .setTooltip("How long each ring takes to expand to screen bounds.")
                .defaultTo("350")
                .textField(FieldConstraint.create().integer().gEqual(100))
        })
        coroutine.yield()

        local waves = tonumber(dialogRequest.result["ringWaves"]) or 6
        local travelMs = tonumber(dialogRequest.result["expandTime"]) or 350
        local center = xy(0.5, 0.5)
        local totalDur = tEnd - tStart
        local interval = totalDur / waves

        for w = 0, waves - 1 do
            local wStart = tStart + (w * interval)
            local wEnd = math.min(tEnd, wStart + travelMs)

            local minScale, maxScale = 0.05, 1.2
            local stepMs = 30

            for t = wStart, wEnd - stepMs, stepMs do
                local p1_ratio = (t - wStart) / travelMs
                local p2_ratio = ((t + stepMs) - wStart) / travelMs

                local scale1 = math.lerp(minScale, maxScale, p1_ratio ^ 2)
                local scale2 = math.lerp(minScale, maxScale, p2_ratio ^ 2)

                local r1_p1 = center + xy(-scale1, -scale1 * 0.6)
                local r1_p2 = center + xy( scale1, -scale1 * 0.6)
                local r1_p3 = center + xy( scale1,  scale1 * 0.6)
                local r1_p4 = center + xy(-scale1,  scale1 * 0.6)

                local r2_p1 = center + xy(-scale2, -scale2 * 0.6)
                local r2_p2 = center + xy( scale2, -scale2 * 0.6)
                local r2_p3 = center + xy( scale2,  scale2 * 0.6)
                local r2_p4 = center + xy(-scale2,  scale2 * 0.6)

                cmd.add(Event.arc(t, r1_p1, t + stepMs, r2_p2, true, 0, "s", tg).save())
                cmd.add(Event.arc(t, r1_p2, t + stepMs, r2_p3, true, 0, "s", tg).save())
                cmd.add(Event.arc(t, r1_p3, t + stepMs, r2_p4, true, 0, "s", tg).save())
                cmd.add(Event.arc(t, r1_p4, t + stepMs, r2_p1, true, 0, "s", tg).save())
            end
        end
    end
)

MacroNew(
    "floony.morefun", "satellite_orbit",
    "Orbiting Satellites", "e577",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local planetPos = Request.position(tStart, "Select central planet origin")
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Orbiting Satellites").requestInput({
            DialogField.create("satellites")
                .setLabel("Satellite Count")
                .setTooltip("Number of orbiting satellite bodies.")
                .defaultTo("4")
                .textField(FieldConstraint.create().integer().gEqual(1).lEqual(10))
        })
        coroutine.yield()

        local satCount = tonumber(dialogRequest.result["satellites"]) or 4
        local stepMs = 30

        -- Center Planet Sphere Outline
        local planetR = 0.15
        for i = 0, 7 do
            local a1 = (i / 8) * (2 * math.pi)
            local a2 = ((i + 1) / 8) * (2 * math.pi)
            local p1 = planetPos + xy(math.cos(a1) * planetR, math.sin(a1) * planetR)
            local p2 = planetPos + xy(math.cos(a2) * planetR, math.sin(a2) * planetR)
            cmd.add(Event.arc(tStart, p1, tEnd, p2, true, 0, "s", tg).save())
        end

        -- Orbiting Satellites
        for s = 1, satCount do
            local orbitRadius = 0.25 + (s * 0.12)
            local speedMult = 2.0 / s
            local startPhase = (s / satCount) * (2 * math.pi)

            for t = tStart, tEnd - stepMs, stepMs do
                local elapsedSec = (t - tStart) / 1000
                local angle1 = startPhase + (elapsedSec * speedMult * math.pi)
                local angle2 = startPhase + ((elapsedSec + (stepMs / 1000)) * speedMult * math.pi)

                local p1 = planetPos + xy(math.cos(angle1) * orbitRadius, math.sin(angle1) * (orbitRadius * 0.4))
                local p2 = planetPos + xy(math.cos(angle2) * orbitRadius, math.sin(angle2) * (orbitRadius * 0.4))

                cmd.add(Event.arc(t, p1, t + stepMs, p2, true, 1, "s", tg).save())
            end
        end
    end
)

MacroNew(
    "floony.morefun", "audio_spectrum",
    "Audio Equalizer Spectrum", "e3ea",
    function(cmd)
        local tStart, tEnd = Request.timeRange()
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Audio Equalizer Spectrum").requestInput({
            DialogField.create("bars")
                .setLabel("Bar Count")
                .setTooltip("Number of spectrum equalizer bars across the screen.")
                .defaultTo("10")
                .textField(FieldConstraint.create().integer().gEqual(2).lEqual(20)),

            DialogField.create("maxHeight")
                .setLabel("Max Bar Height")
                .setTooltip("Maximum vertical height peak for the bars.")
                .defaultTo("0.5")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("baseY")
                .setLabel("Floor Baseline (Y)")
                .setTooltip("Y position where the bottom of the bars sit.")
                .defaultTo("0.0")
                .textField(FieldConstraint.create().float())
        })
        coroutine.yield()

        local bars = tonumber(dialogRequest.result["bars"]) or 10
        local maxH = tonumber(dialogRequest.result["maxHeight"]) or 0.5
        local baseY = tonumber(dialogRequest.result["baseY"]) or 0.0
        local stepMs = 40

        local totalWidth = 2.0
        local barSpacing = totalWidth / bars
        local startX = -0.5 + (barSpacing * 0.5)

        for t = tStart, tEnd - stepMs, stepMs do
            local timeFactor = (t - tStart) / 150

            for b = 0, bars - 1 do
                local posX = startX + (b * barSpacing)
                -- Multi-sine combination for organic bouncing
                local bounce = math.abs(math.sin(timeFactor + b * 0.8) * math.cos(timeFactor * 0.5 + b * 0.3))
                local barHeight = math.max(0.05, bounce * maxH)

                local p1 = xy(posX, baseY)
                local p2 = xy(posX, baseY + barHeight)

                cmd.add(Event.arc(t, p1, t + stepMs, p2, true, (b % 2 == 0) and 0 or 1, "s", tg).save())
            end
        end
    end
)

MacroNew(
    "floony.morefun", "sci_fi_reticle",
    "Sci-Fi Targeting Reticle", "e65f",
    function(cmd)
        local tStart = Request.time("Select target lock timing")
        local center = Request.position(tStart, "Select target center position")
        local tg = Context.currentTimingGroup

        local dialogRequest = DialogInput.withTitle("Sci-Fi Targeting Reticle").requestInput({
            DialogField.create("radius")
                .setLabel("Reticle Radius")
                .setTooltip("Outer ring radius of the HUD reticle.")
                .defaultTo("0.35")
                .textField(FieldConstraint.create().float().greater(0)),

            DialogField.create("duration")
                .setLabel("Lock Duration (ms)")
                .setTooltip("How long the crosshair locks onto the target.")
                .defaultTo("400")
                .textField(FieldConstraint.create().integer().gEqual(50))
        })
        coroutine.yield()

        local radius = tonumber(dialogRequest.result["radius"]) or 0.35
        local dur = tonumber(dialogRequest.result["duration"]) or 400

        -- Center Crosshair (+)
        cmd.add(Event.arc(tStart, center - xy(0.1, 0), tStart + dur, center + xy(0.1, 0), true, 0, "s", tg).save())
        cmd.add(Event.arc(tStart, center - xy(0, 0.1), tStart + dur, center + xy(0, 0.1), true, 0, "s", tg).save())

        -- Segmented Ring (4 Arcs)
        local segments = 4
        for i = 0, segments - 1 do
            local a1 = (i / segments) * (2 * math.pi) + 0.15
            local a2 = ((i + 1) / segments) * (2 * math.pi) - 0.15

            local p1 = center + xy(math.cos(a1) * radius, math.sin(a1) * radius)
            local p2 = center + xy(math.cos(a2) * radius, math.sin(a2) * radius)

            cmd.add(Event.arc(tStart, p1, tStart + dur, p2, true, 2, "s", tg).save())
        end

        -- Outer Corner Brackets
        local corners = { xy(-1, -1), xy(1, -1), xy(1, 1), xy(-1, 1) }
        local cornerSize = 0.08
        local bracketRadius = radius * 1.25

        for _, c in ipairs(corners) do
            local cOrigin = center + xy(c.x * bracketRadius, c.y * bracketRadius)
            local cArmX = cOrigin + xy(-c.x * cornerSize, 0)
            local cArmY = cOrigin + xy(0, -c.y * cornerSize)

            cmd.add(Event.arc(tStart, cOrigin, tStart + dur, cArmX, true, 3, "s", tg).save())
            cmd.add(Event.arc(tStart, cOrigin, tStart + dur, cArmY, true, 3, "s", tg).save())
        end
    end
)

MacroNew(
    "floony.morefun", "audio_eq",
    "Audio EQ Spectrum", "e3ea",
    function(cmd)
        local tStart, tEnd = Request.timeRange()

        local dialogFields = {
            DialogField.create("bars")
                .setLabel("Bar Count")
                .defaultTo("10")
                .textField(FieldConstraint.create().integer().gEqual(2).lEqual(20)),
            DialogField.create("maxHeight")
                .setLabel("Max Height")
                .defaultTo("0.4")
                .textField(FieldConstraint.create().float().greater(0)),
            DialogField.create("step")
                .setLabel("Step Resolution (ms)")
                .defaultTo("60")
                .textField(FieldConstraint.create().integer().gEqual(20)),
            DialogField.create("posY")
                .setLabel("Base Y Position")
                .defaultTo("1.0")
                .textField(FieldConstraint.create().float())
        }

        local dialogRequest = DialogInput.withTitle("Audio EQ Visualizer").requestInput(dialogFields)
        coroutine.yield()

        local barCount = tonumber(dialogRequest.result["bars"]) or 10
        local maxHeight = tonumber(dialogRequest.result["maxHeight"]) or 0.4
        local step = tonumber(dialogRequest.result["step"]) or 60
        local baseY = tonumber(dialogRequest.result["posY"]) or 1.0

        -- Setup EQ TG
        local tgName = "$floony.eq"
        local eqTG = nil
        for i = 1, Context.timingGroupCount - 1 do
            local group = Event.getTimingGroup(i)
            if group.name == tgName then eqTG = group; break end
        end

        if not eqTG then
            eqTG = Event.createTimingGroup('name="' .. tgName .. '", noinput')
            cmd.add(eqTG.save())
        end

        local totalWidth = 1.6
        local barSpacing = totalWidth / barCount
        local startX = -0.3

        for t = tStart, tEnd - step, step do
            local phase = (t - tStart) / 200

            for i = 0, barCount - 1 do
                local posX = startX + (i * barSpacing)
                
                -- Sine wave mix for dynamic equalizer bouncing
                local h1 = math.abs(math.sin(phase + i * 0.7)) * maxHeight
                local h2 = math.abs(math.sin((phase + (step / 200)) + i * 0.7)) * maxHeight

                local p1_start = xy(posX, baseY)
                local p1_end = xy(posX, baseY + h1)

                local p2_start = xy(posX, baseY)
                local p2_end = xy(posX, baseY + h2)

                local eqBar = Event.arc(
                    t, p1_end,
                    t + step, p2_end,
                    true, 2, "s"
                )
                cmd.add(eqBar.save().withTimingGroup(eqTG))
            end
        end
    end
)