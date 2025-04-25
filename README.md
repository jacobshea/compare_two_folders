# copy-similarity-estimator

A tiny, **pure-Bash** utility that answers the question:

> *“How much of Repo B was copied from Repo A?”*

It walks both directories, compares every source/text file line-by-line, and prints:

* **Per-file similarity %**  
* **Weighted line-level similarity %** (all identical lines ÷ all lines)  
* **Simple average of file similarities %**

Designed and tested on **macOS (Bash 3.2)** but works on any POSIX shell.

---

## Why I wrote this

After cloning two GitHub projects locally (the “original” and a “suspect” repo) I needed a quick, offline way to see how much code was reused.  
Most diff tools flag *differences*; I wanted a **quantitative similarity score** I could drop in an email or slide deck.

---

## Features

| Feature | Notes |
|---------|-------|
| **Recursive** comparison | Follows the exact relative paths inside each repo |
| **Handles typical dev files** | `.ts`, `.js`, `.tsx`, `.jsx`, `.json`, `.html`, `.css`, `.md`, `.yaml`, `.yml` (edit one regex to add more) |
| **Whitespace-agnostic** | Leading/trailing spaces ignored |
| **Order-independent** | Lines are `sort`ed before comparison – great when functions are rearranged |
| **Zero external deps** | Only uses macOS-built-in `find`, `sed`, `sort`, `comm`, `awk`, `wc`, `mktemp` |

---

## Requirements

* macOS 10.15+ (or any Unix with the standard POSIX coreutils)
* Bash 3.2+  
  *No* Homebrew/Node/Python/GNU tools needed.

---

## Installation

```bash
# 1. clone this repo
git clone https://github.com/<your-org>/copy-similarity-estimator.git
cd copy-similarity-estimator

# 2. make it executable
chmod +x copy_similarity_estimator.sh
```

---

## Usage

```bash
./copy_similarity_estimator.sh /path/to/originalRepo /path/to/suspectRepo
```

Example:

```bash
./copy_similarity_estimator.sh ~/dev/mcp-client-chatbot-main ~/dev/open-imi-main
```

---

### Sample output

```
Comparing folders:
  Original: /Users/jacob/dev/mcp-client-chatbot-main
  Suspect:  /Users/jacob/dev/open-imi-main

File-by-file comparison:
------------------------
package.json                     → 74.3% similar
src/lib/utils.ts                 → 94.9% similar
src/components/ui/button.tsx     → 100.0% similar
…

------------------------
Files matched:               162
Total lines scanned:      24 317
Matching lines:           22 986
Estimated similarity
  (line-weighted):         94.53%
Average file similarity:   91.22%
```

---

## Customising

* **Add/Remove extensions** – edit the `EXTENSIONS` regex at the top of the script.  
  Example to include Python and Go:

  ```bash
  EXTENSIONS="\.ts$|\.js$|\.go$|\.py$|\.…"
  ```

* **CSV report** – uncomment the three lines at the bottom marked `# CSV` (or extend as desired).

---

## Limitations / Future ideas

* Treats two files as unrelated if their **relative path doesn’t match**.  
  (Use `rsync -rvn` beforehand to map different directory layouts.)
* Ignores binary assets (PNG, SVG, fonts).  
* Sorting lines kills context-based diffs; useful for plagiarism detection but not patch generation.

---

## License

MIT – free to use, modify, and embed in your own investigative toolchain.

---

## Contributing

1. Fork & create a branch  
2. Make your changes (please keep it POSIX-compliant)  
3. Open a PR with a clear description of the improvement

We welcome:
* Extension-lists for additional languages
* Speed/portability tweaks *(BSD vs GNU tools, etc.)*
* Optional flags (`--min 80` to show only files ≥ 80 %)  

Happy comparing!
