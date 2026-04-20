-- Author: floofer++ (Improved by James / Exiony)
-- Version: (Refer to changelog.lua)

-- addFolderWithIcon(nil, "floony", "f1c4", "Floofer's <size=75%>(with Exiony's)</size> macros") [old name]
addFolderWithIcon(nil, "floony", "f1c4", "Floony's <size=75%>(ultimate)</size> macro")

local floonyModules = {}

-- Main related modules
floonyModules.main = {
    "floony.main.segmentation",
    "floony.main.effect",
    "floony.main.create",
    "floony.main.modification",
    "floony.main.special",
}

-- Other related modules
floonyModules.other = {
    "floony.other.selection",
    "floony.other.fun",
    "floony.other.information",
    "floony.other.misc.changelog",
}

for _, categoryModules in pairs(floonyModules) do
    for _, module in ipairs(categoryModules) do
        require(module)
    end
end
