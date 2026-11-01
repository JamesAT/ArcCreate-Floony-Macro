require 'floony.lib.macroUtil'
require 'floony.lib.favorites'
require 'floony.lib.utils'

------------------------------------\
-- // SETTINGS SUMMARY // --        |
------------------------------------/
-- One place to see every setting the macros remember, and to put them all back to their defaults.
-- (Settings are saved with ArcCreate's `Persistent`, so they survive reloads.)

local function onoff(b)
    return string.richcolor(b and 'On' or 'Off', Colors.status(b))
end

--- Check that ArcCreate's Persistent storage really keeps a value (write it, read it back).
local function persistenceWorks()
    if not (Persistent and Persistent.set and Persistent.get) then return false end
    local ok = pcall(Persistent.set, 'floony.probe', 1)
    if not ok then return false end
    local ok2, value = pcall(Persistent.get, 'floony.probe', 0)
    return ok2 and value == 1
end

local function buildText()
    local S = FloonySettings
    local lines = {}

    -- One block for every module that called registerSettings(...)
    for _, section in ipairs(Floony.settingSections) do
        lines[#lines + 1] = '<b>' .. section.title .. '</b>'

        local ok, body = pcall(function()
            if section.describe then return section.describe(S) end
            -- No description given: list every key with its value.
            local auto = {}
            for key in pairs(section.defaults) do
                auto[#auto + 1] = string.format('%s: %s', key, tostring(S[key]))
            end
            table.sort(auto)
            return auto
        end)

        if ok and type(body) == 'table' then
            for _, line in ipairs(body) do lines[#lines + 1] = '  ' .. line end
        else
            lines[#lines + 1] = '  (could not be shown)'
        end
        lines[#lines + 1] = ''
    end

    -- Still written by hand until special.lua registers its own settings (then delete this block).
    lines[#lines + 1] = '<b>Favorites</b>'
    lines[#lines + 1] = string.format('  Pinned: %d', #Favorites.load())
    lines[#lines + 1] = ''

    if persistenceWorks() then
        lines[#lines + 1] = 'Saving: ' .. string.richcolor('working', Colors.enable) .. ' (settings survive reloads)'
    else
        lines[#lines + 1] = 'Saving: ' .. string.richcolor('not available', Colors.disable) .. ' (settings reset on reload)'
    end

    return table.concat(lines, '\n')
end

MacroNewNOCMD(
    'floony', 'floony.settings_summary',
    'Settings Summary', 'e8b8',
    function()
        local req = DialogInput.withTitle('Floony Settings').requestInput({
            DialogField.create('summary')
                .description(buildText()),

            DialogField.create('reset')
                .setLabel('Reset all\nto defaults')
                .setTooltip('Tick and confirm to put every setting above back to its default value. Favorites are not touched.')
                .checkbox(),
        })

        coroutine.yield()

        local reset = req.result['reset']
        if reset == true or tostring(reset) == 'true' then
            resetSettings()
            notify('All settings were reset to their defaults.')
        end
    end,
    true -- looking at settings should not replace the "last macro"
)
