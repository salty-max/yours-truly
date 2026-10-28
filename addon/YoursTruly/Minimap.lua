-- The book's button on the minimap (the kit's: Kit.lua): click to open the
-- book, right-click for its settings, drag to move it around the minimap.
-- Its place (and whether it shows) is kept with this character's settings
-- (Settings.lua). The game's own mail icon while a letter waits for a mailbox
-- (the user's call, 28 October 2026: it lifts the plan's "no notice before the
-- mailbox"): one due in the post, delivered and unread, or a bundle.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

local M, badge

local function pending() return #ns.due() > 0 or #ns.waiting() > 0 or #ns.bundle() > 0 end

-- The game's own mail icon: Classic Era's MiniMapMailFrame, Forever's in the
-- minimap's indicator row. The game shows it for real mail and hides it again
-- on its UPDATE_PENDING_MAIL event: we hook that event's handler and show it
-- also while a letter waits, never hiding it while real mail does (its state
-- wins), and its tooltip gets a line of ours. The frame and its code are the
-- game's, only shown and hidden. Where the icon isn't to be found, or another
-- addon keeps it hidden, our own small icon on the book's button stands in.
local hooked
local function gameIcon()
  local f = _G.MiniMapMailFrame
  if not f and _G.MinimapCluster and type(MinimapCluster.IndicatorFrame) == "table" then
    f = MinimapCluster.IndicatorFrame.MailFrame
  end
  if type(f) == "table" and f.Show and f.IsShown then return f end
end

local function sync()
  local f = gameIcon()
  local want, real = pending(), HasNewMail and HasNewMail()
  if f and not real then
    if want and not f:IsShown() then
      f:Show()
      if type(f.MailIcon) == "table" then f.MailIcon:SetShown(true) end
      local parent = f.GetParent and f:GetParent()
      if parent and parent.Layout then parent:Layout() end
    elseif not want and f:IsShown() then
      f:Hide()
    end
  end
  if badge then badge:SetShown(want and not (f and f:IsShown())) end
end

local function hookIcon()
  local f = gameIcon()
  if hooked or not f or not f.HookScript then return end
  hooked = true
  f:HookScript("OnEvent", function() sync() end)
  f:HookScript("OnEnter", function()
    if pending() and GameTooltip:IsOwned(f) then
      GameTooltip:AddLine(L["A letter waits at the mailbox."], 1, 1, 1)
      GameTooltip:Show()
    end
  end)
end

local function refresh()
  hookIcon()
  sync()
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
function ns.mailBadgeShown() return (badge ~= nil and badge:IsShown()) or (gameIcon() ~= nil and gameIcon():IsShown()) end
