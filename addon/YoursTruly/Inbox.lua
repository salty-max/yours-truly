-- The letters in the game's own inbox: a strip of rows hanging from the mail
-- window's foot, one row for each letter waiting at the mailbox (the
-- backlog's bundle one row), drawn in the mail rows' own look: the envelope's
-- seal, the writer, the place. A click opens it in the panel beside the mail
-- window (Panel.lua). A real mail can't be made by an addon (the mailbox is the
-- server's, no API puts a message in it), so these are never mail: they can't
-- be taken, deleted or returned, and the row's tooltip says so.
--
-- Nothing of the game's is moved or replaced: the strip is a frame of ours, a
-- child of InboxFrame (so it goes with the Send Mail tab and the mailbox
-- closing), standing under MailFrame because the window has no room inside
-- (its rows fill it down to the page buttons, 7 of 45 pixels). Not above it:
-- on Classic Era the player's and the target's frames stand there, which a
-- strip would hide and take the clicks of. Both clients keep the names it
-- hangs from: InboxFrame, its pageNum, and an Update (Classic Era: the global
-- InboxFrame_Update, Forever: InboxFrame:Update, the paging's buttons calling
-- it), hooked with hooksecurefunc so the game's own code and a mail addon's
-- run unchanged. The strip shows on the first page only, two rows at most (a
-- third and more: "N more letters" opening the panel's queue), fewer where the
-- screen's foot leaves no room.
--
-- Where the strip can't stand (no InboxFrame, a mailbox addon that hides the
-- game's window, no room under it, the inbox left on a later page) the panel
-- stands by itself as before (ns.atMailbox, the mailbox's visit).
local _, ns = ...
local L = ns.kit.L

local ROW_W, ROW_H = 305, 45
local PAD, GAP = 13, 8 -- (the rows' left, as the game's: the strip's gap under the window's foot)
local MAX_ROWS = 2

local strip
local rows = {}

local function mailShown()
  return MailFrame and MailFrame:IsVisible() and (MailFrame:GetAlpha() or 1) > 0 and InboxFrame ~= nil
end

-- How many rows the screen's foot leaves room for under the window.
local function room()
  local foot = MailFrame.GetBottom and MailFrame:GetBottom()
  if not foot then return MAX_ROWS end
  return math.max(0, math.min(MAX_ROWS, math.floor((foot - GAP - 8) / ROW_H)))
end

-- The strip can stand: the game's window is up and the screen has room.
function ns.inboxServes() return mailShown() and room() > 0 end

local function page() return InboxFrame and InboxFrame.pageNum or 1 end

local function row(i)
  if rows[i] then return rows[i] end
  local b = CreateFrame("Button", "YoursTrulyInboxRow" .. i, strip)
  b:SetSize(ROW_W, ROW_H)
  b:SetPoint("TOPLEFT", PAD, -(GAP + (i - 1) * ROW_H))
  b:RegisterForClicks("LeftButtonUp")
  local left = b:CreateTexture(nil, "BACKGROUND")
  left:SetTexture("Interface\\MailFrame\\MailItemBorder")
  left:SetTexCoord(0, 0.1640625, 0, 0.75)
  left:SetSize(42, 48)
  left:SetPoint("TOPLEFT")
  local right = b:CreateTexture(nil, "BACKGROUND")
  right:SetTexture("Interface\\MailFrame\\MailItemBorder")
  right:SetTexCoord(0.1640625, 1, 0, 0.75)
  right:SetSize(263, 48)
  right:SetPoint("TOPRIGHT")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(37, 37)
  b.icon:SetPoint("TOPLEFT", 4, -3)
  b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  b.name:SetSize(250, 16)
  b.name:SetJustifyH("LEFT")
  b.name:SetPoint("TOPLEFT", 47, -4)
  b.subject = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  b.subject:SetSize(250, 18)
  b.subject:SetJustifyH("LEFT")
  b.subject:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, 0)
  local lit = b:CreateTexture(nil, "HIGHLIGHT")
  lit:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  lit:SetBlendMode("ADD")
  lit:SetPoint("TOPLEFT", 4, -3)
  lit:SetSize(37, 37)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.name:GetText() or "")
    GameTooltip:AddLine(L["Not real mail: it can't be taken, deleted or returned."], 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN then PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN) end
    if self.open then self.open() end
  end)
  rows[i] = b
  return b
end

local function build()
  strip = CreateFrame("Frame", "YoursTrulyInbox", InboxFrame)
  strip:SetFrameLevel(InboxFrame:GetFrameLevel() + 5)
  strip:EnableMouse(true)
  strip:Hide()
  local bg = strip:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.16, 0.11, 0.07, 0.96)
  for _, e in ipairs({
    { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
    { "TOPLEFT", "BOTTOMLEFT", 1, nil },
    { "TOPRIGHT", "BOTTOMRIGHT", 1, nil },
  }) do
    local t = strip:CreateTexture(nil, "BORDER")
    t:SetColorTexture(0.42, 0.35, 0.23, 1)
    t:SetPoint(e[1])
    t:SetPoint(e[2])
    if e[3] then t:SetWidth(e[3]) end
    if e[4] then t:SetHeight(e[4]) end
  end
end

-- One row's words: a letter, or the rest of the queue.
local function fill(b, id, more)
  b.icon:SetTexture(ns.SEAL)
  if id == "bundle" then
    local n = #ns.bundle()
    b.name:SetText(L["From the road behind you"])
    b.subject:SetText(ns.kit.plural(n, "%d letter", "%d letters"):format(n))
    b.open = function() ns.showPanel(id) end
  elseif more then
    b.name:SetText(ns.kit.plural(more, "%d more letter waits.", "%d more letters wait."):format(more))
    b.subject:SetText(L["Next letter"])
    b.open = function() ns.showPanel(id) end
  else
    b.name:SetText(ns.writer(id))
    b.subject:SetText(ns.place(id))
    -- (the seal broken at the click: the letter opens at once)
    b.open = function() ns.showPanel(id, true) end
  end
  b:Show()
end

-- The strip as the queue stands: called at the mailbox, when the inbox pages
-- or is updated, and after a letter is read or a bundle untied.
function ns.refreshInbox()
  if not strip then
    if not InboxFrame then return end
    build()
  end
  local q = ns.queue and ns.queue() or {}
  local n = math.min(#q > MAX_ROWS and MAX_ROWS or #q, room())
  if n == 0 or page() ~= 1 or not mailShown() then
    strip:Hide()
    return
  end
  strip:ClearAllPoints()
  strip:SetPoint("TOPLEFT", MailFrame, "BOTTOMLEFT", 0, 8 - GAP)
  strip:SetSize(PAD * 2 + ROW_W, GAP + n * ROW_H + 4)
  for i = 1, MAX_ROWS do
    if i > n then
      if rows[i] then rows[i]:Hide() end
    elseif i == MAX_ROWS and #q > MAX_ROWS then
      fill(row(i), q[i], #q - MAX_ROWS + 1)
    else
      fill(row(i), q[i])
    end
  end
  strip:Show()
end

-- (the game's inbox redrawn: paging, a mail taken, new mail)
local hooked
local function hook()
  if hooked or not InboxFrame or not hooksecurefunc then return end
  hooked = true
  if InboxFrame.Update then
    hooksecurefunc(InboxFrame, "Update", ns.refreshInbox)
  elseif InboxFrame_Update then
    hooksecurefunc("InboxFrame_Update", ns.refreshInbox)
  end
  if InboxFrame.HookScript then InboxFrame:HookScript("OnShow", ns.refreshInbox) end
end

-- A letter read or a bundle untied: the strip follows.
for _, name in ipairs({ "read", "untie" }) do
  local f = ns[name]
  ns[name] = function(...)
    local out = f(...)
    ns.refreshInbox()
    return out
  end
end

-- The mailbox opened: hang the hooks (the game's window is loaded by now) and
-- draw the strip, or tell the visit that the panel must stand alone.
function ns.atMailbox()
  hook()
  ns.refreshInbox()
  -- (served only if a strip is up: the inbox left on page 2 shows none, and
  -- the panel must then stand by itself, or the letter comes with nothing seen)
  return ns.inboxServes() and strip ~= nil and strip:IsShown()
end

-- (the window hides with the mailbox, the strip a child of it: this is for a
-- mail addon that keeps the frame up)
ns.on("MAIL_CLOSED", function()
  if strip then strip:Hide() end
end)

-- (the strip and its rows: for the tests)
function ns.inboxRows()
  if not strip then ns.refreshInbox() end
  rows.strip = strip
  return rows
end
