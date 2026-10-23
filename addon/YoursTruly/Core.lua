-- Yours Truly: the letters this character has earned (a chain's last quest
-- turned in posts its writer's letter), the post they wait in (fifteen
-- minutes of play, counted here), the mailbox that delivers them (the next
-- one opened, one letter a visit, two when more than three wait), the seal
-- broken; the events every file listens to (ns.on); /yourstruly. The panel
-- beside the mail window (Panel.lua) and the book (Book.lua and its tabs)
-- show them.
--
--   YoursTrulyChar (SavedVariablesPerCharacter), whose book: guid
--     played                      seconds of play counted while Yours Truly
--                                 was on (the game's own RequestTimePlayed
--                                 prints to the chat: never that)
--     letters[id] = { posted,     the played second it went in the post
--                     at, level,  when, and the character's level then
--                     backlog,    true: found done at a login, not turned in
--                     delivered,  when it reached a mailbox
--                     read }      when its seal was broken
--     milestones[id] = { at, level, retro }   (Achievements.lua)
--   YoursTrulySettings (SavedVariables): each character's settings, the kit's
--     profiles (Settings.lua: the minimap button)
--
-- Every record by id: a letter by its id (letters/<zone>/<writer>.md), its
-- quests, writer and place by theirs; their names are the game's, in the
-- client's language, when shown.
local _, ns = ...
local L, D = ns.kit.L, ns.data
ns.PREFIX = "|cffe8a08aYours Truly:|r "
-- The addon's mark (its logo: the book's and the panel's portrait, the
-- minimap button, the welcome page, the banners); its wax seal cut round
-- (Media/Seal, assets/README.md): a letter still sealed, on its envelope and in
-- the book; a letter read: the game's open letter.
ns.ICON = "Interface\\AddOns\\YoursTruly\\Media\\Logo"
ns.SEAL = "Interface\\AddOns\\YoursTruly\\Media\\Seal"
ns.ICON_READ = "Interface\\Icons\\INV_Letter_15"
-- (a letter's time in the post, in seconds played)
ns.POST = 15 * 60

local char
function ns.book() return char end

-- ── events ───────────────────────────────────────────────────────────────────
-- Every file listens through ns.on (an event a client doesn't know is never
-- heard). Nothing is heard before the login.
local frame = CreateFrame("Frame")
local listeners = {}

-- (one listener's error is reported, and the others still hear the event)
local function run(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then geterrorhandler()(err) end
end

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then run(ns.login) end
  if not char then return end
  for _, fn in ipairs(listeners[event] or {}) do
    run(fn, ...)
  end
end)
frame:RegisterEvent("PLAYER_LOGIN")

function ns.on(event, fn)
  if not listeners[event] then
    listeners[event] = {}
    pcall(frame.RegisterEvent, frame, event)
  end
  table.insert(listeners[event], fn)
end

-- ── the clock ────────────────────────────────────────────────────────────────
-- The time played, as Yours Truly counts it: every frame's seconds while the
-- character is logged in.
frame:SetScript("OnUpdate", function(_, elapsed)
  if char then char.played = char.played + elapsed end
end)

-- ── the letters ──────────────────────────────────────────────────────────────
-- The character's side, as the data writes it (A, H; N: both).
function ns.side() return UnitFactionGroup("player") == "Horde" and "H" or "A" end
-- A letter this character may receive: this game's (the data holds it), its
-- side's or both sides'.
function ns.mine(id)
  local l = D.letters[id]
  return l ~= nil and (l.side == "N" or l.side == ns.side())
end
-- Every letter this character may receive, by id.
function ns.letters()
  local out = {}
  for id in pairs(D.letters) do
    if ns.mine(id) then table.insert(out, id) end
  end
  table.sort(out)
  return out
end

-- A quest done, as the game keeps it.
function ns.done(quest)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(quest) == true end
  if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(quest) == true end
  return false
end

-- Every quest of the letter turned in (just: one the game is turning in now,
-- which it may not have flagged yet).
local function earned(l, just)
  for _, q in ipairs(l.quests) do
    if q ~= just and not ns.done(q) then return false end
  end
  return true
end

function ns.record(id) return char and char.letters[id] end

-- Into the post.
function ns.post(id, backlog)
  if char.letters[id] then return end
  char.letters[id] =
    { posted = math.floor(char.played), at = time(), level = UnitLevel("player"), backlog = backlog or nil }
  if ns.onChange then ns.onChange() end
end

-- The letters earned before (the addon newly on, or off for a while): every
-- one posted at once, delivered by the same rule, in the chains' order.
function ns.catchUp()
  for _, id in ipairs(ns.letters()) do
    if not char.letters[id] and earned(D.letters[id]) then ns.post(id, true) end
  end
end

-- A quest turned in: the letter it completes goes in the post.
ns.on("QUEST_TURNED_IN", function(quest)
  for _, id in ipairs(ns.letters()) do
    if not char.letters[id] then
      local l = D.letters[id]
      for _, q in ipairs(l.quests) do
        if q == quest then
          if earned(l, quest) then ns.post(id) end
          break
        end
      end
    end
  end
end)

-- (the oldest first: the post's order, then the chain's level, then the id)
local function older(a, b)
  local ra, rb = char.letters[a], char.letters[b]
  if ra.posted ~= rb.posted then return ra.posted < rb.posted end
  local la, lb = D.letters[a].level or 0, D.letters[b].level or 0
  if la ~= lb then return la < lb end
  return a < b
end

-- In the post, their time up: the next mailbox may deliver them, oldest first.
function ns.due()
  local out = {}
  for id, r in pairs(char.letters) do
    if D.letters[id] and not r.delivered and char.played - r.posted >= ns.POST then table.insert(out, id) end
  end
  table.sort(out, older)
  return out
end
-- Still in the post, their time not up (nothing says they're there).
function ns.inThePost()
  local n = 0
  for id, r in pairs(char.letters) do
    if D.letters[id] and not r.delivered then n = n + 1 end
  end
  return n
end
-- Delivered, the seal unbroken: the oldest delivered first.
function ns.waiting()
  local out = {}
  for id, r in pairs(char.letters) do
    if D.letters[id] and r.delivered and not r.read then table.insert(out, id) end
  end
  table.sort(out, function(a, b)
    local da, db = char.letters[a].delivered, char.letters[b].delivered
    if da ~= db then return da < db end
    return older(a, b)
  end)
  return out
end
-- Delivered, newest first: the book's letters.
function ns.received()
  local out = {}
  for id, r in pairs(char.letters) do
    if D.letters[id] and r.delivered then table.insert(out, id) end
  end
  table.sort(out, function(a, b)
    local da, db = char.letters[a].delivered, char.letters[b].delivered
    if da ~= db then return da > db end
    return older(b, a)
  end)
  return out
end
function ns.readCount()
  local n = 0
  for id, r in pairs(char.letters) do
    if D.letters[id] and r.read then n = n + 1 end
  end
  return n
end

-- A mailbox opened: one letter of those due, two when more than three are.
function ns.deliver()
  local due = ns.due()
  local n = #due > 3 and 2 or math.min(#due, 1)
  for i = 1, n do
    char.letters[due[i]].delivered = time()
  end
  return n
end

-- The seal broken.
function ns.read(id)
  local r = char.letters[id]
  if not r or r.read then return end
  r.delivered = r.delivered or time()
  r.read = time()
  if ns.checkMilestones then ns.checkMilestones() end
  if ns.onChange then ns.onChange() end
end

-- ── the mailbox ──────────────────────────────────────────────────────────────
-- A visit: from the mailbox opened to the mailbox closed (MAIL_SHOW may come
-- again within it). The panel a moment later: the game opens its mail window
-- on an event of its own (the interaction manager's), in no order against
-- this one, and the panel docks to it.
local visiting = false
ns.on("MAIL_SHOW", function()
  if visiting then return end
  visiting = true
  ns.deliver()
  C_Timer.After(0, function()
    if visiting and #ns.waiting() > 0 and ns.showPanel then ns.showPanel() end
  end)
  if ns.onChange then ns.onChange() end
end)
ns.on("MAIL_CLOSED", function()
  visiting = false
  if ns.hidePanel then ns.hidePanel() end
end)

-- ── a letter's words ─────────────────────────────────────────────────────────
-- As this client's language writes it (Letters_<locale>): Classic Era's
-- names swapped in there, agreed to the reader, the game's tokens filled.
local function swapped(text)
  if ns.forever or not ns.classicNames then return text end
  for forever, classic in pairs(ns.classicNames) do
    text = text:gsub(forever:gsub("%p", "%%%0"), (classic:gsub("%%", "%%%%")))
  end
  return text
end
local function filled(text)
  local name = UnitName("player")
  local class, classFile = UnitClass("player")
  if UnitSex("player") == 3 and LOCALIZED_CLASS_NAMES_FEMALE and classFile then
    class = LOCALIZED_CLASS_NAMES_FEMALE[classFile] or class
  end
  local race = UnitRace("player")
  return (text:gsub("%$([NCR])", { N = name or "", C = class or "", R = race or "" }))
end
local function fit(text) return filled(ns.agree(swapped(text))) end

-- { greeting, body = { ... }, signoff, ps = { ... } }, or nil.
function ns.letter(id)
  local t = ns.letterTexts and ns.letterTexts[id]
  if not t then return nil end
  local body, ps = {}, {}
  for i, p in ipairs(t.body) do
    body[i] = fit(p)
  end
  for i, p in ipairs(t.ps or {}) do
    ps[i] = fit(p)
  end
  return { greeting = fit(t.greeting), body = body, signoff = fit(t.signoff), ps = ps }
end

-- The writer's name, the game's (a letter's writer always has one in English,
-- the build refuses one without; a language lacking it: "a friend", never an
-- English name in its place, the family's rule).
function ns.writer(id)
  local l = D.letters[id]
  return l and ns.npcNames and ns.npcNames[l.npc] or L["A friend"]
end
-- A place's name, the client's (an area id).
function ns.areaName(area)
  local name = area and C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(area)
  return type(name) == "string" and name ~= "" and name or nil
end
function ns.place(id)
  local l = D.letters[id]
  return l and ns.areaName(l.place) or ""
end
-- The chain a letter answers: its last quest's name (nil: this language lacks it).
function ns.chain(id)
  local l = D.letters[id]
  local q = l and l.quests[#l.quests]
  return q and ns.questNames and ns.questNames[q] or nil
end
-- A zone's count: the letters it has sent this character, and all it could.
function ns.zoneCount(zone)
  local got, all = 0, 0
  for _, id in ipairs(ns.letters()) do
    if D.letters[id].zone == zone then
      all = all + 1
      local r = char.letters[id]
      if r and r.delivered then got = got + 1 end
    end
  end
  return got, all
end
-- "Westfall: 1 of 2", once the zone has written (never before: no one
-- else's name or number is given away).
function ns.zoneLine(id)
  local l = D.letters[id]
  local got, all = ns.zoneCount(l.zone)
  if got == 0 then return nil end
  return L["%s: %d of %d"]:format(ns.areaName(l.zone) or "", got, all)
end

-- ── the login ────────────────────────────────────────────────────────────────
local function newBook(guid) return { guid = guid, played = 0, letters = {}, milestones = {} } end

function ns.login()
  local guid = UnitGUID("player")
  if type(YoursTrulyChar) ~= "table" or YoursTrulyChar.guid ~= guid then YoursTrulyChar = newBook(guid) end
  char = YoursTrulyChar
  char.played = tonumber(char.played) or 0
  char.letters, char.milestones = char.letters or {}, char.milestones or {}
  ns.loadProfile()
  if ns.createMinimapButton then ns.createMinimapButton() end
  if ns.createSettingsPanel then ns.createSettingsPanel() end
  ns.catchUp()
  if ns.checkMilestones then ns.checkMilestones(true) end
  ns.loggedIn = true
end

-- ── /yourstruly ──────────────────────────────────────────────────────────────
SLASH_YOURSTRULY1 = "/yourstruly"
SlashCmdList.YOURSTRULY = function(msg)
  local raw = strtrim(msg or "") -- (a code's letters as typed)
  msg = raw:lower()
  if msg == "achievements" then
    if ns.openMilestones then ns.openMilestones() end
  elseif msg == "minimap" then
    ns.setOption("minimapHidden", not ns.option("minimapHidden"))
  elseif msg == "settings" then
    if not ns.openSettings() then print(ns.PREFIX .. L["The game's Options have no page for addons here."]) end
  elseif msg == "welcome" then
    if ns.showWelcome then ns.showWelcome() end
  elseif msg == "export" then
    if ns.showWelcome then ns.showWelcome("export") end
  elseif msg:match("^import%s") then
    if ns.profiles:import(raw:match("^%a+%s+(.+)$")) then
      print(ns.PREFIX .. L["Settings imported for this character."])
    else
      print(ns.PREFIX .. L["That isn't a Yours Truly settings code."])
    end
  elseif ns.toggle then
    ns.toggle()
  end
end
