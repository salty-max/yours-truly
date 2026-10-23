-- Yours Truly's settings, each character's own (its profile, "Name - Realm",
-- the kit's: Kit.lua), all kept in YoursTrulySettings so that one character
-- can take another's: chosen among this game's characters, or brought by a
-- code (/yourstruly export, /yourstruly import CODE). Their page in the game's
-- Options (AddOns tab): /yourstruly settings, or a right-click on the minimap
-- button; the welcome page (Welcome.lua) offers them too.
--
--   YoursTrulySettings.profiles["Name - Realm"] = { minimapHidden,
--     minimapAngle, welcomed, panelX, panelY (where the mailbox panel stands
--     when no game mail window shows: a mailbox addon's) }
local _, ns = ...
local K = ns.kit
local L = K.L

-- (minimapAngle: the button's place around the minimap, in degrees, 120 on
-- the upper left, above Goodwill's (140), Mealbook's (165) and the siblings'
-- (200 to 250); welcomed and the panel's place: never copied)
local DEFAULTS = {
  minimapHidden = false,
  minimapAngle = 120,
  welcomed = false,
  panelX = false,
  panelY = false,
}
local SHARED = { "minimapHidden", "minimapAngle" }

-- The profiles: a code "YT1:h0:a120".
local P = K.profiles({
  saved = function()
    if type(YoursTrulySettings) ~= "table" then YoursTrulySettings = {} end
    return YoursTrulySettings
  end,
  defaults = DEFAULTS,
  shared = SHARED,
  letters = { minimapHidden = "h", minimapAngle = "a" },
  tag = "YT1",
  changed = function(key)
    if key == "minimapHidden" or key == "minimapAngle" then
      if ns.updateMinimapButton then ns.updateMinimapButton() end
    end
  end,
})
ns.profiles = P

function ns.loadProfile() P:load() end
function ns.option(key) return P:get(key) end
function ns.setOption(key, value) P:set(key, value) end

local category

function ns.createSettingsPanel()
  if category or not (Settings and Settings.RegisterVerticalLayoutCategory) then return end
  category = Settings.RegisterVerticalLayoutCategory("Yours Truly")

  local setting = Settings.RegisterProxySetting(
    category,
    "YOURSTRULY_MINIMAP",
    Settings.VarType.Boolean,
    L["Minimap button"],
    true,
    function() return not ns.option("minimapHidden") end,
    function(value) ns.setOption("minimapHidden", not value) end
  )
  Settings.CreateCheckbox(category, setting, L["The letters by the minimap: click to open the book, drag to move it."])

  -- Another character's settings (of this game), for this one.
  K.copySetting(
    category,
    "YOURSTRULY_COPYFROM",
    P,
    L["Another character's choices, for this one (of this game: Classic and Forever keep their own). From elsewhere: /yourstruly export there, then /yourstruly import CODE here."],
    function(other) print(ns.PREFIX .. L["%s's settings copied."]:format(other)) end
  )

  Settings.RegisterAddOnCategory(category)
end

function ns.openSettings()
  if category then Settings.OpenToCategory(category:GetID()) end
  return category ~= nil
end
