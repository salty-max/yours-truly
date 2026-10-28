-- The book's button on the minimap (the kit's: Kit.lua): click to open the
-- book, right-click for its settings, drag to move it around the minimap.
-- Its place (and whether it shows) is kept with this character's settings
-- (Settings.lua). The game's mail icon on its corner while a letter waits for a
-- mailbox (the user's call, 28 October 2026: it lifts the plan's "no notice
-- before the mailbox"): one due in the post, delivered and unread, or a bundle.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

local M, badge

local function pending() return #ns.due() > 0 or #ns.waiting() > 0 or #ns.bundle() > 0 end

local function refresh()
  if badge then badge:SetShown(pending()) end
end
ns.refreshMail = refresh

function ns.createMinimapButton()
  if M then return end
  M = K.minimapButton({
    name = "YoursTrulyMinimapButton",
    icon = ns.ICON,
    crop = true,
    title = "Yours Truly",
    lines = function()
      local n = #ns.received()
      local out = { K.plural(n, "%d letter received", "%d letters received"):format(n) }
      if pending() then table.insert(out, L["A letter waits at the mailbox."]) end
      return out
    end,
    click = function() ns.toggle() end,
    rightClick = function() ns.openSettings() end,
    get = ns.option,
    set = ns.setOption,
  })
  if M.button then
    badge = M.button:CreateTexture(nil, "OVERLAY")
    badge:SetTexture("Interface\\Icons\\INV_Letter_15")
    badge:SetSize(16, 16)
    badge:SetPoint("BOTTOMRIGHT", 2, -2)
    badge:Hide()
    -- (the post's clock runs in play time: looked at every half minute)
    local function tick()
      refresh()
      C_Timer.After(30, tick)
    end
    tick()
  end
end

function ns.updateMinimapButton()
  if M then M:update() end
  refresh()
end

-- (for the tests)
function ns.mailBadgeShown() return badge ~= nil and badge:IsShown() end
