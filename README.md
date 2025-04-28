# CopyScore

A tiny, **pure‑Bash** utility that answers the question:

> *“How much of Repo B was copied from Repo A?”*

CopyScore walks both directories, compares every **text** file line‑by‑line, and prints:

* **Per‑file similarity %**  
* **Weighted (line‑level) similarity %**  
* **Average of file similarities %**

Designed for **macOS’ default Bash 3.2** — no Homebrew, Python, or GNU coreutils required. It also runs on any POSIX shell with standard utilities (`find`, `awk`, `sort`, `comm`, …).

---

## Why this exists

When evaluating open‑source reuse, most diff tools highlight *differences*. CopyScore flips the lens and shows a **quantitative similarity score** you can drop into an email, slide deck, or diligence report.

---

## Quick start

```bash
# 1. clone
$ git clone https://github.com/jacobshea/copyscore.git
$ cd copyscore

# 2. make executable
$ chmod +x copyscore.sh

# 3. compare two repos (defaults to every text file)
$ ./copyscore.sh path/to/original path/to/suspect
```

Example output:

```
Comparing folders:
  Original: /Users/jacob/repo_original
  Suspect:  /Users/jacob/repo_suspect

File‑by‑file comparison:
------------------------
package.json                  → 74%  
src/lib/utils.ts              → 95%  
src/components/ui/button.vue  → 100%

Summary:
---------
Average file similarity:   91%
Line‑weighted similarity:  94%
```

---

## CLI options

| Flag | Purpose | Example |
|------|---------|---------|
| *(none)* | Scan **all text files** (default) | `./copyscore.sh repoA repoB` |
| `-e ts,vue,md` | Comma‑separated extension list &rarr; restrict scan | `-e ts,vue` |
| `-x node_modules,tests` | Ignore paths whose **relative** prefix matches | `-x node_modules -x .git` |
| `-t 80` | Only report files ≥ 80 % similar | – |
| `-o report.csv` | Save per‑file results to CSV | – |
| `-j report.json` | Save per‑file results to JSON | – |

### Examples

```bash
# Only TS/Vue files, skip node_modules, CSV + JSON exports
./copyscore.sh -e ts,vue -x node_modules -o stats.csv -j stats.json repoA repoB

# Show just the really‑close matches (≥90 %)
./copyscore.sh -t 90 repoA repoB
```

---

## Features

* **All‑text default** – zero flags gives you the whole picture.  
  Add `-e` to narrow if you know which languages matter.
* **Pure Bash (3.2‑safe)** – runs on fresh macOS without brew install sprawl.
* **Whitespace‑agnostic & order‑independent** – trims spaces and `sort`s lines so re‑ordering doesn’t hide copying.
* **Colorized terminal output** – green ≥90 %, yellow 50‑89 %, red <50 % (auto‑disables when piped).
* **CSV *and* JSON export** – ready for spreadsheets or scripts.
* **Ignore paths** – drop `node_modules`, `dist`, `tests`, etc.
* **Similarity threshold** – sift noise with `-t`.

---

## Limitations & future ideas

* **Path‑exact matching** – a file is compared only when paths match in both repos. (Workaround: `rsync -rvn` or rename beforehand.)
* **Binary files ignored** – comparisons are text‑only.
* **Context lost** – sorting lines kills diff context; great for plagiarism detection, not for patch generation.
* **Performance** – fine for small/medium repos (< 100k LOC). Large mono‑repos will be slower.

### Roadmap

* Verbose/debug mode (`-V`) to show exactly which files were included or skipped.
* Glob‑style ignore patterns (e.g. `-X "node_modules/**"`).
* Tiny fixture test‑suite (Bats) for CI.
* Optional parallel mode (`xargs -P`).

---

## Contributing

PRs are welcome — please keep POSIX compliance in mind (BSD vs GNU flags).

1. Fork & create a branch  
2. Make your changes  
3. Open a PR explaining the improvement

Thanks for helping improve CopyScore!

---

## License

MIT — free to use, modify, and embed in your own investigative toolchain.

