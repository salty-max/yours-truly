// typography.ts: French's no-break spaces, the front matter and tokens left alone (bun test).
import { expect, test } from "bun:test";
import { typeset, typesetLetter } from "./typography";

const N = "\u00a0";

test("a no-break space before : ? ! and %, inside « »", () => {
  expect(typeset("Je dirai : pas encore ! Vraiment ?")).toBe(`Je dirai${N}: pas encore${N}! Vraiment${N}?`);
  expect(typeset("« Une journée éprouvante »")).toBe(`«${N}Une journée éprouvante${N}»`);
  expect(typeset("Je l'ai fait !!")).toBe(`Je l'ai fait${N}!!`);
  expect(typeset("%s : %d sur %d")).toBe(`%s${N}: %d sur %d`);
  expect(typeset("50 % de plus, 20%, %d%%")).toBe(`50${N}% de plus, 20${N}%, %d%%`);
});

test("a token's colon is no punctuation, and a token's end takes the space", () => {
  expect(typeset("Merci, $gmon gars:ma fille;.")).toBe("Merci, $gmon gars:ma fille;.");
  expect(typeset("$gMon cher:Ma chère; $N !")).toBe(`$gMon cher:Ma chère; $N${N}!`);
  expect(typeset("Hé, $ggamin:gamine;!")).toBe(`Hé, $ggamin:gamine;${N}!`);
});

test("the front matter keeps its colons, the letter is typeset, the client's ’ kept", () => {
  const letter = "---\nid: 1\nquest: 166\n---\n\n## Letter\n\n$N,\n\nJ'ai dû lui répondre : pas encore. Comté-de-l’Or !\n";
  expect(typesetLetter(letter)).toBe(
    `---\nid: 1\nquest: 166\n---\n\n## Letter\n\n$N,\n\nJ'ai dû lui répondre${N}: pas encore. Comté-de-l’Or${N}!\n`,
  );
});

test("idempotent", () => {
  const once = typeset("Bien le bonjour, $N ! « oui » : non ?");
  expect(typeset(once)).toBe(once);
});
