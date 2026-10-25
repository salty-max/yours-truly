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
  minimapAngle = K.MINIMAP_ANGLES.YoursTruly,
  achievementToast = true,
  welcomed = false,
  panelX = false,
  panelY = false,
}
local SHARED = { "minimapHidden", "minimapAngle", "achievementToast" }

-- The profiles: a code "YT1:h0:a115:v1".
local P = K.profiles({
  saved = function()
    if type(YoursTrulySettings) ~= "table" then YoursTrulySettings = {} end
    return YoursTrulySettings
  end,
  defaults = DEFAULTS,
  shared = SHARED,
  letters = { minimapHidden = "h", minimapAngle = "a", achievementToast = "v" },
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

-- The page in the game's Options (the kit's: K.options).
local O

function ns.createSettingsPanel()
  if O then return end
  O = K.options({
    title = "Yours Truly",
    key = "YOURSTRULY",
    get = ns.option,
    set = ns.setOption,
    defaults = DEFAULTS,
    profiles = P,
    slash = "/yourstruly",
    prefix = ns.PREFIX,
  })
  O:check(
    "achievementToast",
    L["Alert for achievements"],
    L["Show each achievement earned in the game's achievement alert. A click on it opens the achievements."]
  )
  O:check(
    "minimapHidden",
    L["Minimap button"],
    L["The letters by the minimap: click to open the book, drag to move it."],
    true
  )
  O:copy()
  O:done()
end

function ns.openSettings() return O ~= nil and O:open() end
