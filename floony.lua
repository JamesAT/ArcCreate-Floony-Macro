-- Original Author: floofer++ 
-- Improved by James / Exiony... and unfortuanetly, with the help of claude.ai... my skill is really insufficient for the complexity of the codes.
-- so uh... if anyone can rewrite the code using their own skill, I would really appreciated it!

-- Version: (Refer to changelog.lua)

require 'floony.lib.macroUtil'
require 'floony.lib.favorites'

-- ALWAYS-ON FAVORITES: macro ids that always get a one-click shortcut in the Favorites folder.
-- Example: local PERMANENT_FAVORITES = { 'brr', 'filtersel', 'gradual' }
-- (Pinned favorites are separate: run a macro, then use Favorites > Pin Last Macro. See "How Favorites Work".)
local PERMANENT_FAVORITES = { }

FolderNew(nil, "floony", "f1c4", "Floony's <size=75%>(ultimate)</size> macros")

Floony.loadErrors = {}
Floony.modules = {}

-- THE ORDER OF THIS LIST IS THE MENU ORDER
-- Move a line up or down to move the folder in the menu.
local floonyModules = {
    "floony.other.selection",
    "floony.main.segmentation",
    "floony.main.modification",
    "floony.main.create",
    "floony.main.effect",
    "floony.main.special",
    "floony.other.fun",
    "floony.other.information",
    "floony.other.misc.changelog",
    "floony.other.summary",
}

-- Registered before the modules so it is the very first entry of the menu.
MacroNewNOCMD(
    "floony", "floony.repeatlast",
    "Repeat Last Macro", "e040",
    function()
        local last = Floony.lastRun
        if not last then
            notifyWarn("No macro has been run yet.")
            return
        end

        notify("Repeating: " .. last.name)
        return last.run()
    end,
    true -- never record itself
)

-- Favorites folder: created now so it is the 2nd entry of the menu, filled once every macro is known.
Favorites.createFolder()

-- A module that fails to load no longer takes the whole macros down with it.
for _, module in ipairs(floonyModules) do
    local ok, err = pcall(require, module)
    if ok then
        Floony.modules[#Floony.modules + 1] = module
    else
        Floony.loadErrors[#Floony.loadErrors + 1] = { module = module, err = tostring(err) }
        notifyError("Floony: failed to load " .. module .. "\n" .. tostring(err))
    end
end

-- Now that every macro is registered, the shortcuts can be built (names and icons are known).
do
    local ok, err = pcall(Favorites.build, PERMANENT_FAVORITES)
    if not ok then
        Floony.loadErrors[#Floony.loadErrors + 1] = { module = 'favorites', err = tostring(err) }
        notifyError('Floony: Favorites failed to build\n' .. tostring(err))
    end
end

-- // ABOUT / STATUS // --
local statusTitle = string.format("v%s <size=75%%>(loaded: %d/%d)</size>", tostring(Floony.version), #Floony.modules, #floonyModules)

MacroNewNOCMD(
    "floony", "floony.about",
    statusTitle, "e88e",
    function()
        local formattedLines = {
            "<b>Floony's macros</b> v" .. tostring(Floony.version),
            string.format("Loaded modules: %d / %d", #Floony.modules, #floonyModules),
        }

        local plainLines = {
            "Floony's macros v" .. tostring(Floony.version),
            string.format("Loaded modules: %d / %d", #Floony.modules, #floonyModules),
        }

        if Floony.lastRun then
            local lastMacroName = tostring(Floony.lastRun.name):gsub('<[^>]+>', '')
            formattedLines[#formattedLines + 1] = "Last macro: <b>" .. lastMacroName .. "</b>"
            plainLines[#plainLines + 1] = "Last macro: " .. lastMacroName
        else
            formattedLines[#formattedLines + 1] = "Last macro: <i>(None)</i>"
            plainLines[#plainLines + 1] = "Last macro: (None)"
        end

        local hasErrors = #Floony.loadErrors > 0

        if hasErrors then
            formattedLines[#formattedLines + 1] = "\n" .. string.richcolor("Failed to load:", Colors.disable or "#FF7070")
            plainLines[#plainLines + 1] = "\nFailed to load:"
            for _, e in ipairs(Floony.loadErrors) do
                formattedLines[#formattedLines + 1] = string.format("- <b>%s</b>: %s", e.module, e.err)
                plainLines[#plainLines + 1] = string.format("- %s: %s", e.module, e.err)
            end
        end

        local fields = {
            DialogField.create("info")
                .description(table.concat(formattedLines, "\n"))
        }

        if hasErrors then
            fields[#fields + 1] = DialogField.create("copy")
                .setLabel("Copy error log\nto clipboard")
                .setTooltip("Tick and confirm to copy error logs and status report to your clipboard.")
                .checkbox()
        end

        local r = Request.dialogRaw("About Floony", table.unpack(fields))
        if not r then return end

        if hasErrors then
            local shouldCopy = r["copy"] == true or tostring(r["copy"]) == "true"
            if shouldCopy then
                Context.systemClipboard = table.concat(plainLines, "\n")
                notify("Error report copied to clipboard!")
            end
        end
    end,
    true
)