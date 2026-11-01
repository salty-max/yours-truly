/**
 * French typography in Yours Truly's French (the family's Q1, 31 October 2026,
 * as the client writes it): a no-break space (U+00A0) before : ? ! and a
 * percent sign, and inside « ». Over each letter's text (what follows its
 * "## Letter" heading, never the front matter, whose colons are YAML's) and
 * the values of words.json (terms.ts checks those too). Apostrophes are left
 * as they are: a Forever name keeps the client's ’ (classic-names.json
 * matches it). Goodwill's typography.ts, the same rules. Idempotent.
 *
 *   bun scripts/typography.ts           fix them
 *   bun scripts/typography.ts --check   fail if one is left (the check runs it)
 */
import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";

const ROOT = new URL("..", import.meta.url).pathname;
const FR = join(ROOT, "i18n/frFR");
const NBSP = "\u00a0";

/** One string's French typography (a format blank's "%s" is no percent sign). */
export function typeset(s: string): string {
  return s
    .replace(/[ \t]+([:?!])(?![\p{L}\d])/gmu, `${NBSP}$1`)
    .replace(/([\p{L}\d)%;»…])([:?!])(?=\s|$|\\n)/gmu, `$1${NBSP}$2`)
    .replace(/(\d)[ \t]*%(?![sdif%$\d.])/g, `$1${NBSP}%`)
    .replace(/[ \t]+%%/g, `${NBSP}%%`)
    .replace(/«[ \t\u00a0]*/g, `«${NBSP}`)
    .replace(/[ \t\u00a0]*»/g, `${NBSP}»`);
}

/** A letter's file: the front matter as it is, the text after "## Letter" typeset. */
export function typesetLetter(text: string): string {
  const at = text.indexOf("\n## Letter\n");
  if (at < 0) return text;
  const head = text.slice(0, at + "\n## Letter\n".length);
  return head + typeset(text.slice(head.length));
}

const letters = (dir: string): string[] =>
  readdirSync(dir).flatMap((f) => {
    const p = join(dir, f);
    return statSync(p).isDirectory() ? letters(p) : f.endsWith(".md") ? [p] : [];
  });

/** Each file's new text: a letter's, or words.json's values (never its keys, which are English). */
function fixed(file: string): string {
  const text = readFileSync(file, "utf8");
  if (file.endsWith(".md")) return typesetLetter(text);
  const words: Record<string, string> = JSON.parse(text);
  return `${JSON.stringify(Object.fromEntries(Object.entries(words).map(([k, v]) => [k, typeset(v)])), null, 2)}\n`;
}

if (import.meta.main) {
  const files = [...letters(join(FR, "letters")), join(FR, "words.json")];
  const left = files.filter((f) => fixed(f) !== readFileSync(f, "utf8"));
  if (process.argv.includes("--check")) {
    if (left.length) {
      console.error(
        `✗ French typography (a no-break space before : ? ! %, inside « »): run bun scripts/typography.ts\n  ${left.map((f) => relative(ROOT, f)).join("\n  ")}`,
      );
      process.exit(1);
    }
  } else {
    for (const f of left) writeFileSync(f, fixed(f));
    console.log(`✓ French typography: ${left.length} files fixed of ${files.length}`);
  }
}
