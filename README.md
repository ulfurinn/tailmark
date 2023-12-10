# Tailmark

[![Elixir CI](https://github.com/ulfurinn/tailmark/actions/workflows/elixir.yml/badge.svg?event=push)](https://github.com/ulfurinn/tailmark/actions/workflows/elixir.yml)

This is a Markdown parser in Elixir.

## Project goals

The end goal of the library is to be able to _manipulate_ Markdown source, while most other projects typically treat it as input for HTML generation. It aims to be fully compliant with CommonMark and [Obsidian](https://obsidian.md/) syntax extensions such as Wiki-style links, transclusions, and block references. GFM support is not prioritized.

The code is largely ported to Elixir from the reference [commonmark.js](https://github.com/commonmark/commonmark.js) implementation.

## How to use it

Stick to `earmark` for now. This is not ready.

The main use case for this project is [Tall Tale](https://github.com/ulfurinn/tailmark), an experimental interactive fiction engine that uses Obsidian as its primary authoring tool, and satisfying its requirements will be the highest priority.

## Progress

### CommonMark test suite (v0.30)

| Section | Total | Passed |
| ------- | ----- | ------ |
| ATX headings | 18 | 15 (83.3 %) |
| Autolinks | 19 | 2 (10.5 %) |
| Backslash escapes | 13 | 3 (23.1 %) |
| Blank lines | 1 | 1 (**100.0 %**) |
| Block quotes | 25 | 24 (**96.0 %**) |
| Code spans | 22 | 3 (13.6 %) |
| Emphasis and strong emphasis | 131 | 36 (27.5 %) |
| Entity and numeric character references | 17 | 1 (5.9 %) |
| Fenced code blocks | 29 | 20 (69.0 %) |
| HTML blocks | 44 | 0 (0.0 %) |
| Hard line breaks | 15 | 7 (46.7 %) |
| Images | 22 | 0 (0.0 %) |
| Indented code blocks | 12 | 11 (**91.7 %**) |
| Inlines | 1 | 0 (0.0 %) |
| Link reference definitions | 27 | 5 (18.5 %) |
| Links | 90 | 10 (11.1 %) |
| List items | 48 | 47 (**97.9 %**) |
| Lists | 26 | 23 (88.5 %) |
| Paragraphs | 8 | 8 (**100.0 %**) |
| Precedence | 1 | 1 (**100.0 %**) |
| Raw HTML | 21 | 10 (47.6 %) |
| Setext headings | 27 | 21 (77.8 %) |
| Soft line breaks | 2 | 2 (**100.0 %**) |
| Tabs | 11 | 11 (**100.0 %**) |
| Textual content | 3 | 3 (**100.0 %**) |
| Thematic breaks | 19 | 18 (**94.7 %**) |
| **TOTAL** | 652 | 282 (43.3 %) |

### Extensions

- [x] YAML frontmatter (through `yaml_elixir`)
- [ ] tables
- Obsidian:
  - [ ] Wiki-style links
  - [ ] transclusions
  - [ ] callouts
  - [ ] block refs
  - [ ] links in frontmatter data