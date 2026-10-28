-- The panel beside the mail window: shown when a mailbox opens and a letter
-- waits there for this character (never empty), hidden when it closes. A
-- letter comes sealed: its seal, its writer, the place it was written. A click
-- breaks the seal (the game's own page sound) and the letter opens on the mail
-- reader's own paper (Interface\Stationery\StationeryTest1 and 2, drawn
-- 252 + 50 wide: the second's last 14 columns are see-through, cut so the
-- paper reaches the window's edge; stretched to the sheet: stacked, they
-- show a seam), filling the window's body under its title, in the mail's own face
-- (MailTextFontNormal: Morpheus 15, dark brown), scrolling over the paper as
-- the game's reader does. Taller than the game's reader (its 256 pixels of
-- paper hold a third of a letter): as big as the mail window beside it
-- (the longest letters scroll), the right margin clear of the paper's torn edge. Under it, small:
-- the chain it answers and its zone's count. "Next letter" when another waits.
--
-- The backlog's bundle (Core: ns.bundle) comes first when there is one: the
-- same seal, "N letters from the road behind you, tied with string". A click
-- unties it: the letters go into the book, sealed, the panel closes and the
-- book opens on the first of them (the user's call, 27 October 2026: no page
-- in between). Fresh letters wait for the next mailbox.
--
-- Docked to the mail window: beside the open letter (OpenMailFrame) when one
-- is open, else where that would stand (beside the inbox). A mailbox addon
-- that hides the game's mail window: the panel stands on its own instead,
-- movable, where the player last left it. No other addon's code is touched.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

local W, H = 384, 512 -- (the mail window's own size, read again when the panel is built)
local PAPER = { "Interface\\Stationery\\StationeryTest1", "Interface\\Stationery\\StationeryTest2" }
local INK = { 0.18, 0.12, 0.06 }
local FADED = { 0.40, 0.30, 0.20 }
local EDGE = 3 -- (the window's frame, its lip about 1.5 wide: the paper reaches it, short of its top under the portrait)
local SHEET_W, TEXT_W
local BAR = 36 -- (the sheet's foot: a button, a line, over the paper)

local panel, current
local BUNDLE = "bundle"
ns.panelParts = {} -- (for the tests)

-- What the panel holds: the bundle first, if there is one, then each letter
-- waiting at the mailbox.
local function queue()
  local q = ns.waiting()
  if #ns.bundle() > 0 then table.insert(q, 1, BUNDLE) end
  return q
end

-- The mail's own face where the client has it, else the books' display face.
local function ink(parent, size, colour)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  if size == 15 and MailTextFontNormal then
    fs:SetFontObject(MailTextFontNormal)
  else
    fs:SetFont(K.TITLE_FONT, size, "")
  end
  fs:SetTextColor(unpack(colour or INK))
  fs:SetShadowOffset(0, 0)
  fs:SetJustifyH("LEFT")
  fs:SetSpacing(3)
  return fs
end

-- The bundle untied: the panel closed, the book open on its first letter.
local function untie()
  local first = ns.bundle()[1]
  ns.untie()
  panel:Hide()
  if first and ns.openLetter then ns.openLetter(first) end
end

-- The window's title: "A letter", "A bundle of letters" while the bundle shows.
local function title(text)
  if panel.SetTitle then
    panel:SetTitle(text)
  elseif type(panel.TitleText) == "table" and panel.TitleText.SetText then
    panel.TitleText:SetText(text)
  end
end

-- ── where it stands ──────────────────────────────────────────────────────────
local function dock()
  panel:ClearAllPoints()
  -- (a mailbox addon may hide the game's window without closing it: parented
  -- to a hidden frame, or made transparent)
  if MailFrame and MailFrame:IsVisible() and (MailFrame:GetAlpha() or 1) > 0 then
    panel.docked = true
    local beside = (OpenMailFrame and OpenMailFrame:IsShown() and OpenMailFrame) or InboxFrame or MailFrame
    panel:SetPoint("TOPLEFT", beside, "TOPRIGHT", 0, 0)
  else
    panel.docked = false
    local x, y = ns.option("panelX"), ns.option("panelY")
    if x and y then
      panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
      panel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end
  end
end

-- ── the panel ────────────────────────────────────────────────────────────────
local show

local function build()
  -- as big as the mail window it stands beside
  if MailFrame and MailFrame.GetWidth and MailFrame:GetWidth() > 200 then
    W, H = MailFrame:GetWidth(), MailFrame:GetHeight()
    -- (the old art doesn't fill the frame: its hit rect is the window you see)
    if MailFrame.GetHitRectInsets then
      local l, r, t, b = MailFrame:GetHitRectInsets()
      W, H = W - (l or 0) - (r or 0), H - (t or 0) - (b or 0)
    end
    W, H = math.floor(W + 0.5), math.floor(H + 0.5)
  end
  SHEET_W = W - 2 * EDGE
  TEXT_W = SHEET_W - 18 - 44
  local window = K.gameWindow("YoursTrulyPanel", L["A letter"], ns.ICON)
  panel = window or K.dialog("YoursTrulyPanel", L["A letter"])
  panel:SetSize(W, H)
  panel:SetToplevel(true)
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function(self)
    if not self.docked then self:StartMoving() end
  end)
  panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if not self.docked then
      ns.setOption("panelX", math.floor(self:GetLeft() + 0.5))
      ns.setOption("panelY", math.floor(self:GetTop() + 0.5))
    end
  end)
  table.insert(UISpecialFrames, "YoursTrulyPanel")
  panel:Hide()

  -- the paper
  local sheet = CreateFrame("Frame", nil, panel)
  sheet:SetPoint("TOPLEFT", EDGE, -64)
  sheet:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
  -- The paper reaches up under the title bar, but not under the portrait:
  -- two clipped windows onto one sheet of paper, the main one right of the
  -- portrait, a short one below it (the empty band the portrait left).
  local PORTRAIT_W, TITLE_H = 66, 36
  local reach = 64 - TITLE_H
  local paper = CreateFrame("Frame", nil, panel)
  paper:SetPoint("TOPLEFT", EDGE, -TITLE_H)
  paper:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
  -- (the sheet's content above the paper: raised before its children exist)
  sheet:SetFrameLevel(paper:GetFrameLevel() + 2)
  local function clip(x0, x1, top)
    local c = CreateFrame("Frame", nil, paper)
    c:SetPoint("TOPLEFT", paper, "TOPLEFT", x0, -top)
    c:SetPoint("BOTTOMRIGHT", paper, x1 and "BOTTOMLEFT" or "BOTTOMRIGHT", x1 or 0, 0)
    if c.SetClipsChildren then c:SetClipsChildren(true) end
    local left = c:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(PAPER[1])
    left:SetPoint("TOPLEFT", paper, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", paper, "BOTTOMLEFT")
    left:SetWidth(math.floor(SHEET_W * 252 / 302 + 0.5))
    local right = c:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(PAPER[2])
    right:SetTexCoord(0, 50 / 64, 0, 1)
    right:SetPoint("TOPLEFT", left, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", paper, "BOTTOMRIGHT")
  end
  clip(PORTRAIT_W - EDGE, nil, 0)
  clip(0, PORTRAIT_W - EDGE, reach)
  -- (a client lacking clipping: the paper stays below the portrait as before)
  if not paper.SetClipsChildren then
    paper:ClearAllPoints()
    paper:SetPoint("TOPLEFT", EDGE, -64)
    paper:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
  end

  -- the letter, scrolling over it
  local scroll = K.scrollArea(sheet, TEXT_W, "YoursTrulyPanelScroll")
  scroll:SetPoint("TOPLEFT", 18, -14)
  scroll:SetPoint("BOTTOMRIGHT", -44, BAR + 4)
  scroll.thumb:SetColorTexture(INK[1], INK[2], INK[3], 0.35)
  local c = scroll.child
  local place = ink(c, 15)
  place:SetWidth(TEXT_W)
  place:SetJustifyH("RIGHT")
  local main = ink(c, 15)
  main:SetWidth(TEXT_W)
  local signoff = ink(c, 15)
  signoff:SetWidth(TEXT_W)
  signoff:SetJustifyH("RIGHT")
  local ps = ink(c, 15)
  ps:SetWidth(TEXT_W)
  local footer = ink(c, 11, FADED)
  footer:SetWidth(TEXT_W)

  -- the envelope: a click breaks the seal
  local envelope = CreateFrame("Button", "YoursTrulyEnvelope", sheet)
  envelope:SetAllPoints()
  -- (the logo's wax seal, on the paper as a seal is)
  local seal = envelope:CreateTexture(nil, "ARTWORK")
  seal:SetTexture(ns.SEAL)
  seal:SetSize(72, 72)
  seal:SetPoint("CENTER", 0, 70)
  local from = ink(envelope, 13, FADED)
  from:SetPoint("TOP", seal, "BOTTOM", 0, -20)
  from:SetWidth(TEXT_W)
  from:SetJustifyH("CENTER")
  from:SetText(L["A letter from"])
  local writer = ink(envelope, 22)
  writer:SetPoint("TOP", from, "BOTTOM", 0, -6)
  writer:SetWidth(TEXT_W)
  writer:SetJustifyH("CENTER")
  local where = ink(envelope, 15, FADED)
  where:SetPoint("TOP", writer, "BOTTOM", 0, -6)
  where:SetWidth(TEXT_W)
  where:SetJustifyH("CENTER")
  local hint = ink(envelope, 12, FADED)
  hint:SetPoint("BOTTOM", envelope, "BOTTOM", 0, BAR + 14)
  hint:SetWidth(TEXT_W)
  hint:SetJustifyH("CENTER")
  hint:SetText(L["Click to break the seal."])
  envelope:SetScript("OnClick", function()
    if not current then return end
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN then PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN) end
    if current == BUNDLE then return untie() end
    ns.read(current)
    show(current)
  end)

  -- the next one, at the paper's foot (over the envelope: its own click)
  local nextButton = K.button(panel, L["Next letter"], 120)
  nextButton:SetFrameLevel(envelope:GetFrameLevel() + 2)
  nextButton:SetPoint("BOTTOMRIGHT", -(EDGE + 44), EDGE + 8)
  local foot = CreateFrame("Frame", nil, panel)
  foot:SetAllPoints(sheet)
  foot:SetFrameLevel(envelope:GetFrameLevel() + 1)
  local waitingLine = ink(foot, 11, FADED)
  waitingLine:SetPoint("BOTTOMLEFT", EDGE + 18, EDGE + 13)
  -- (the one after this one in the panel, round to the first)
  nextButton:SetScript("OnClick", function()
    local q = queue()
    for i, id in ipairs(q) do
      if id == current then
        local after = q[i % #q + 1]
        if after ~= current then show(after) end
        return
      end
    end
    if q[1] then show(q[1]) end
  end)

  -- (the mail window shown late, a letter opened beside it: the panel moves)
  for _, f in ipairs({ MailFrame, OpenMailFrame }) do
    if f and f.HookScript then
      f:HookScript("OnShow", function()
        if panel:IsShown() then dock() end
      end)
      f:HookScript("OnHide", function()
        if panel:IsShown() then dock() end
      end)
    end
  end

  local P = ns.panelParts
  P.panel, P.scroll, P.place, P.main, P.signoff, P.ps, P.footer = panel, scroll, place, main, signoff, ps, footer
  P.envelope, P.writer, P.where, P.next, P.waiting = envelope, writer, where, nextButton, waitingLine
  P.from, P.hint, P.sheet, P.paper = from, hint, sheet, paper
end

-- A letter in the panel: sealed (its envelope) or open (its words).
show = function(id)
  local P = ns.panelParts
  current = id
  local q = queue()
  local others, rest = 0, 0 -- (letters besides this one, and anything besides it)
  for _, w in ipairs(q) do
    if w ~= id then
      rest = rest + 1
      if w ~= BUNDLE then others = others + 1 end
    end
  end
  P.next:SetShown(rest > 0)
  P.waiting:SetText(
    others > 0 and ns.kit.plural(others, "%d more letter waits.", "%d more letters wait."):format(others) or ""
  )
  local y = 0
  local function lay(fs, text, gap)
    fs:ClearAllPoints()
    if not text or text == "" then
      fs:Hide()
      return
    end
    fs:SetText(text)
    fs:SetPoint("TOPLEFT", P.scroll.child, "TOPLEFT", 0, -y)
    fs:Show()
    y = y + fs:GetStringHeight() + gap
  end
  title(id == BUNDLE and L["A bundle of letters"] or L["A letter"])
  if id == BUNDLE then
    local n = #ns.bundle()
    P.scroll:Hide()
    P.envelope:Show()
    P.from:SetText(L["From the road behind you"])
    P.writer:SetText(ns.kit.plural(n, "%d letter", "%d letters"):format(n))
    P.where:SetText(L["tied with string"])
    P.hint:SetText(L["Click to untie them."])
    return
  end
  P.from:SetText(L["A letter from"])
  P.hint:SetText(L["Click to break the seal."])
  local r = ns.record(id)
  if not (r and r.read) then
    P.scroll:Hide()
    P.envelope:Show()
    P.writer:SetText(ns.writer(id))
    P.where:SetText(ns.place(id))
    return
  end
  P.envelope:Hide()
  P.scroll:Show()
  local t = ns.letter(id)
  if not t then return end
  lay(P.place, ns.place(id), 14)
  lay(P.main, t.greeting .. "\n\n" .. table.concat(t.body, "\n\n"), 14)
  lay(P.signoff, t.signoff, 16)
  lay(P.ps, table.concat(t.ps, "\n\n"), 16)
  -- (either may be missing: a language without the quest's name, a zone's
  -- count before it has written)
  local under = {}
  for _, part in ipairs({ ns.chain(id) or false, ns.zoneLine(id) or false }) do
    if part then table.insert(under, part) end
  end
  lay(P.footer, table.concat(under, "  -  "), 4)
  P.scroll.child:SetHeight(y + 8)
  P.scroll:ScrollTo(0)
end

-- At a mailbox: the bundle if there is one, else the oldest letter waiting, sealed.
function ns.showPanel()
  local q = queue()
  if #q == 0 then return end
  if not panel then build() end
  dock()
  show(q[1])
  panel:Show()
end

function ns.hidePanel()
  if panel then panel:Hide() end
end

-- (the letter the panel shows: for the tests)
function ns.panelLetter() return panel and panel:IsShown() and current or nil end
