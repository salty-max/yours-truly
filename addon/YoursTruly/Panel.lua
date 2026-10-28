-- The panel beside the mail window, the game's inbox with our content in it
-- (28 October 2026, the user's call). It is laid out as the inbox lays itself
-- out, from Blizzard's own MailFrame.xml (Classic Era): the window's grey
-- stone and inset, the inbox's paper (Interface\MailFrame\UI-MailFrameBG,
-- 320 by 356 in the top left of its 512 square), a row as MailItemTemplate
-- draws one (MailItemBorder, the slot, GameFontNormal over
-- GameFontHighlightSmall), the pager and the button 114 above the foot
-- (Forever's MailFrame.xml, the same paper and rows: its pager at the foot). Shown
-- when a mailbox opens and a letter waits there for this character (never
-- empty), hidden when it closes.
--
-- The list, as the inbox lists mail: a row for each (the seal in its slot, the
-- writer, the place it was written), a page of seven, Prev and Next with
-- "Open all" between them (it breaks every seal at once). A click
-- on a row breaks that seal (the game's page sound) and the letter opens in
-- the panel, in the mail's own face (MailTextFontNormal, dark brown),
-- scrolling over the paper as the game's reader does, the chain it answers
-- and its zone's count under it; Back returns to the list. The panel is as
-- big as the mail window beside it (the longest letters scroll).
--
-- The backlog (letters earned before the addon, Core: ns.backlog) is in the
-- list too, all of it at the first mailbox: no bundle, rows and the one
-- button (the user's call, 28 October 2026). Fresh letters wait for the next
-- mailbox.
--
-- Docked to the mail window: beside the open letter (OpenMailFrame) when one
-- is open, else where that would stand (beside the inbox). A mailbox addon
-- that hides the game's mail window: the panel stands on its own instead,
-- movable, where the player last left it. No other addon's code is touched.
local _, ns = ...
local K, L = ns.kit, ns.kit.L

local W, H = 384, 512 -- (the mail window's own size, read again when the panel is built)
local INK = { 0.18, 0.12, 0.06 }
local FADED = { 0.40, 0.30, 0.20 }
local TEXT_W = 276 -- (the paper's width, less its margins)

local panel, current, page = nil, nil, 1
local PER = 7 -- (the inbox's page)
ns.panelParts = {} -- (for the tests)

-- What the panel holds: each letter waiting at the mailbox.
local queue = ns.waiting

-- The mail's own face for a letter's words where the client has it, else the books'
-- display face; plain: the game's own text face, as the inbox's words are.
local function ink(parent, size, colour, plain)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  if size == 15 and MailTextFontNormal and not plain then
    fs:SetFontObject(MailTextFontNormal)
  else
    fs:SetFont(plain and K.BODY_FONT or K.TITLE_FONT, size, "")
  end
  fs:SetTextColor(unpack(colour or INK))
  fs:SetShadowOffset(0, 0)
  fs:SetJustifyH("LEFT")
  fs:SetSpacing(3)
  return fs
end

-- The window's title: the addon's name over the list, "A letter" over a letter.
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
    -- (the old art stops short of its frame's right edge: against the art)
    -- (the inbox's frame is the mail window's own, whole: its insets are MailFrame's)
    local src = beside == InboxFrame and MailFrame or beside
    local right = src.GetHitRectInsets and select(2, src:GetHitRectInsets()) or 0
    panel:SetPoint("TOPLEFT", beside, "TOPRIGHT", -(right or 0), 0)
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
local show, list

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
  local window = K.gameWindow("YoursTrulyPanel", L["A letter"], ns.ICON)
  panel = window or K.dialog("YoursTrulyPanel", L["A letter"])
  -- the body the mail window's own grey stone (the kit darkens it: the inbox
  -- beside is not dark), read off the game's window where it can be
  if window and type(window.Bg) == "table" and window.Bg.SetTexture then
    local mail = MailFrame and type(MailFrame.Bg) == "table" and MailFrame.Bg
    local atlas = mail and mail.GetAtlas and mail:GetAtlas()
    local stone = mail and mail.GetTexture and mail:GetTexture()
    if atlas and window.Bg.SetAtlas then
      window.Bg:SetAtlas(atlas)
    else
      window.Bg:SetTexture(stone or "Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
    end
  end
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

  -- Everything below is laid out as the game's inbox lays out its own
  -- (Blizzard's MailFrame.xml, Classic Era), in its coordinates, from the
  -- panel's top left: the window's inset at (4, -58), the paper at (7, -62)
  -- 320 by 356 (the file's 512 square holds it in its top left corner), the
  -- rows 305 by 45 from (13, -70), the pager's row 114 above the foot.
  if type(panel.Inset) == "table" and panel.Inset.SetPoint then
    panel.Inset:Show()
    panel.Inset:SetPoint("TOPLEFT", 4, -58)
  else
    local frame = K.panel(panel)
    frame:SetPoint("TOPLEFT", 4, -58)
    frame:SetPoint("BOTTOMRIGHT", -6, 4)
  end
  local sheet = CreateFrame("Frame", nil, panel)
  sheet:SetAllPoints()
  local paper = sheet:CreateTexture(nil, "BACKGROUND")
  paper:SetTexture("Interface\\MailFrame\\UI-MailFrameBG")
  paper:SetTexCoord(0, 320 / 512, 0, 356 / 512)
  paper:SetSize(320, 356)
  paper:SetPoint("TOPLEFT", 7, -62)

  -- the letter, scrolling over it
  local scroll = K.scrollArea(sheet, TEXT_W, "YoursTrulyPanelScroll")
  scroll:SetPoint("TOPLEFT", 21, -76)
  scroll:SetPoint("TOPRIGHT", sheet, "TOPLEFT", 297, -76)
  scroll:SetPoint("BOTTOM", sheet, "BOTTOM", 0, 60)
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
  local footer = ink(c, 11, FADED, true)
  footer:SetWidth(TEXT_W)

  -- the list: a row each, as MailItemTemplate draws one
  local rows = {}
  for i = 1, PER do
    local row = CreateFrame("Button", nil, sheet)
    row:SetSize(305, 45)
    row:SetPoint("TOPLEFT", 13, -70 - (i - 1) * 45)
    -- (its border and separator: one file, the slot's bevel and the row's rule)
    local edge = row:CreateTexture(nil, "BACKGROUND")
    edge:SetTexture("Interface\\MailFrame\\MailItemBorder")
    edge:SetSize(42, 48)
    edge:SetPoint("TOPLEFT")
    edge:SetTexCoord(0, 0.1640625, 0, 0.75)
    local rule = row:CreateTexture(nil, "BACKGROUND")
    rule:SetTexture("Interface\\MailFrame\\MailItemBorder")
    rule:SetSize(263, 48)
    rule:SetPoint("TOPRIGHT")
    rule:SetTexCoord(0.1640625, 1, 0, 0.75)
    local bar = row:CreateTexture(nil, "BACKGROUND")
    bar:SetSize(322, 2)
    bar:SetPoint("TOP", row, "BOTTOM", 0, 2)
    bar:SetColorTexture(0.33, 0.16, 0, 0.3)
    -- (the button: its empty slot, 64 on 37, gold as an unread one; the seal in it)
    local slot = row:CreateTexture(nil, "BACKGROUND")
    slot:SetTexture("Interface\\Buttons\\UI-EmptySlot-White")
    slot:SetSize(64, 64)
    slot:SetPoint("CENTER", row, "TOPLEFT", 22.5, -21.5)
    slot:SetVertexColor(1, 0.82, 0)
    local seal = row:CreateTexture(nil, "ARTWORK")
    seal:SetTexture(ns.SEAL)
    seal:SetSize(36, 36)
    seal:SetPoint("TOPLEFT", 4, -3)
    local light = row:CreateTexture(nil, "HIGHLIGHT")
    light:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    light:SetBlendMode("ADD")
    light:SetSize(37, 37)
    light:SetPoint("TOPLEFT", 4, -3)
    -- (the sender in the game's gold, the subject under it in its small white)
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetSize(200, 16)
    row.name:SetJustifyH("LEFT")
    row.name:SetPoint("TOPLEFT", 47, -4)
    row.sub = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.sub:SetSize(248, 18)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetJustifyV("TOP")
    row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, 0)
    row:SetScript("OnClick", function(self)
      if self.id then ns.openInPanel(self.id) end
    end)
    row:Hide()
    rows[i] = row
  end

  -- the pager and the button, as the inbox puts them (a row 114 above the foot)
  -- (Forever's inbox puts them at the foot instead: its Prev at (14, 10) of the
  -- window's bottom left, its Next at (-14, 10) of its bottom right, the
  -- button's centre 26 above the middle of the foot)
  local function arrow(text, art, anchor, x, side)
    local b = CreateFrame("Button", nil, sheet)
    b:SetSize(32, 32)
    if ns.forever then
      b:SetPoint(anchor, panel, anchor, side == "LEFT" and 14 or -14, 10)
    else
      b:SetPoint("CENTER", panel, anchor, x, 114)
    end
    b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Down")
    b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local fs = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetText(text)
    if side == "LEFT" then
      fs:SetJustifyH("LEFT")
      fs:SetPoint("LEFT", b, "RIGHT")
    else
      fs:SetJustifyH("RIGHT")
      fs:SetPoint("RIGHT", b, "LEFT")
    end
    return b
  end
  local prev = arrow(L["Prev"], "PrevPage", "BOTTOMLEFT", 30, "LEFT")
  local nextPage = arrow(L["Next"], "NextPage", ns.forever and "BOTTOMRIGHT" or "BOTTOMLEFT", 305, "RIGHT")
  prev:SetScript("OnClick", function()
    page = page - 1
    list()
  end)
  nextPage:SetScript("OnClick", function()
    page = page + 1
    list()
  end)
  local footX, footY = -21, 114
  if ns.forever then
    footX, footY = 0, 26
  end
  local openAll = K.button(sheet, L["Open all"], 120)
  openAll:SetPoint("CENTER", panel, "BOTTOM", footX, footY)
  openAll:SetScript("OnClick", function()
    for _, id in ipairs(ns.waiting()) do
      ns.read(id)
    end
    list()
  end)
  -- the letter open: back to the list, where the button stands
  local back = K.button(sheet, L["Back"], 120)
  back:SetPoint("CENTER", panel, "BOTTOM", footX, footY)
  back:SetScript("OnClick", function() list() end)
  back:Hide()

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
  P.rows, P.prev, P.next, P.openAll, P.back = rows, prev, nextPage, openAll, back
  P.sheet = sheet
end

-- The list: each letter waiting, a page at a time.
-- Nothing left to list: the panel closes.
list = function()
  local P = ns.panelParts
  current = nil
  local q = queue()
  if #q == 0 then return panel:Hide() end
  local pages = math.ceil(#q / PER)
  page = math.max(1, math.min(page, pages))
  title("Yours Truly")
  P.scroll:Hide()
  P.back:Hide()
  for i, row in ipairs(P.rows) do
    local id = q[(page - 1) * PER + i]
    row.id = id
    row:SetShown(id ~= nil)
    if id then
      row.name:SetText(ns.writer(id))
      row.sub:SetText(ns.place(id))
    end
  end
  P.prev:Show()
  P.next:Show()
  P.prev:SetEnabled(page > 1)
  P.next:SetEnabled(page < pages)
  P.openAll:Show()
  P.openAll:SetEnabled(#ns.waiting() > 0)
end

-- A letter opened from its row: the seal broken (the game's page sound) and
-- its words in the panel.
function ns.openInPanel(id)
  if PlaySound and SOUNDKIT and SOUNDKIT.IG_ABILITY_PAGE_TURN then PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN) end
  ns.read(id)
  show(id)
end

-- A letter in the panel, its words.
show = function(id)
  local P = ns.panelParts
  current = id
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
  title(L["A letter"])
  for _, row in ipairs(P.rows) do
    row:Hide()
  end
  P.prev:Hide()
  P.next:Hide()
  P.openAll:Hide()
  P.back:Show()
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

-- At a mailbox: the list of what waits there.
function ns.showPanel()
  local q = queue()
  if #q == 0 then return end
  if not panel then build() end
  dock()
  page = 1
  list()
  panel:Show()
end

function ns.hidePanel()
  if panel then panel:Hide() end
end

-- (the letter the panel shows: for the tests)
function ns.panelLetter() return panel and panel:IsShown() and (current or "list") or nil end
