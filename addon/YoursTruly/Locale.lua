-- The reader's language. The client loads its own Text_<locale>.lua next (the
-- TOCs name Text_[TextLocale].lua; scripts/locales.ts writes them from
-- i18n/), which hands its words to ns.translate: English stays wherever it
-- says nothing. The writers' and the quests' names are the game's, by their
-- ids, in the client's language: never translated here.
local _, ns = ...
local K = ns.kit

-- (is n the "one" form? English, German, Spanish: 1; French: 0 and 1)
local PLURALS = {
  one = function(n) return n == 1 end,
  fr = function(n) return n == 0 or n == 1 end,
  none = function() return false end,
}

function ns.translate(t)
  for english, word in pairs(t.words or {}) do
    K.L[english] = word
  end
  if t.plural and PLURALS[t.plural] then K.isOne = PLURALS[t.plural] end
end

-- The game this is: Forever's client is a modern one (interface 1.60, 16001).
local build = select(4, GetBuildInfo())
ns.forever = build >= 16000 and build < 17000

-- The game's own names in the reader's language (its Text file, from
-- wow-data's databases): this game's writers and quests by id. A name the
-- language lacks is missing: the book names it another way.
function ns.names(t)
  local game = ns.forever and "forever" or "classic"
  local mine = t[game] or {}
  ns.npcNames = mine.npcs or {}
  ns.questNames = mine.quests or {}
end

-- A line written to the reader, agreed to them: "$gCher:Chère;" (the game's
-- own tokens, French above all) as the character is a man or a woman.
function ns.agree(text)
  if not text then return text end
  local female = UnitSex and UnitSex("player") == 3
  return (text:gsub("%$g([^:;]*):([^;]*);", function(masc, fem) return female and fem or masc end))
end
