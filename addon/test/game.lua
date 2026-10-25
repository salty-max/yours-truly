-- A small game for Yours Truly's tests (the kit's game, wowmock.lua: frames, events and timers,
-- as Goodwill's): the quests the character has done and turns in, a mailbox
-- (the game's mail window, its inbox and its open letter; MAIL_SHOW and
-- MAIL_CLOSED), the mail's face, the client's area names, the character's
-- side, race, class and sex. FOREVER=1 plays Forever's client, LOCALE=frFR a
-- French one.
local G = dofile("addon/test/wowmock.lua")
local state, FOREVER, LOCALE, obj = G.state, G.FOREVER, G.LOCALE, G.obj

-- ── quests ───────────────────────────────────────────────────────────────────
-- state.done[quest]: turned in (G.turnIn flags it, then QUEST_TURNED_IN, or
-- the event first, as the game may tell it).
state.done = {}
C_QuestLog = { IsQuestFlaggedCompleted = function(id) return state.done[id] == true end }
function G.turnIn(quest, flagFirst)
  if flagFirst ~= false then state.done[quest] = true end
  G.fire("QUEST_TURNED_IN", quest, 0, 0)
  state.done[quest] = true
end

-- ── the mailbox ──────────────────────────────────────────────────────────────
-- The game's mail window (its inbox: where an open letter stands beside it),
-- and the open letter's window. G.mailbox(true) opens it, false closes it.
-- state.noMailFrame: a mailbox addon that keeps the game's window hidden.
MailFrame = CreateFrame("Frame", "MailFrame", UIParent, "ButtonFrameTemplate")
InboxFrame = CreateFrame("Frame", "InboxFrame", MailFrame)
InboxFrame.shown = true
OpenMailFrame = CreateFrame("Frame", "OpenMailFrame", UIParent, "ButtonFrameTemplate")
function G.mailbox(open)
  if open then
    if not state.noMailFrame then MailFrame:Show() end
    G.fire("MAIL_SHOW")
    G.advance(0.01)
  else
    OpenMailFrame:Hide()
    MailFrame:Hide()
    G.fire("MAIL_CLOSED")
  end
end
-- the mail's face (MailTextFontNormal), the game's sounds
MailTextFontNormal = { GetFont = function() return "Fonts\\MORPHEUS.TTF", 15, "" end }
SOUNDKIT.IG_ABILITY_PAGE_TURN = 830
-- the class's name for a woman (French: Guerrière)
LOCALIZED_CLASS_NAMES_FEMALE = { WARRIOR = LOCALE == "frFR" and "Guerrière" or "Warrior" }

-- ── the addon ────────────────────────────────────────────────────────────────
G.load("YoursTruly")
return G
