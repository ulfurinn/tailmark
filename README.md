# Tailmark

This is a pure-Elixir Markdown parser with some support for Obsidian extensions.

I wrote it for some of my own projects. It's not fit for public consumption. Use it at your own peril.

This is mostly a direct translation of commonmark.js into Elixir.

## Commonmark compliance status

| Section | Total | Passed |
| ------- | ----- | ------ |
| ATX headings | 18 | 18 (**100.0 %**) |
| Autolinks | 19 | 8 (42.1 %) |
| Backslash escapes | 13 | 5 (38.5 %) |
| Blank lines | 1 | 1 (**100.0 %**) |
| Block quotes | 25 | 24 (**96.0 %**) |
| Callouts | 3 | 3 (**100.0 %**) |
| Code spans | 22 | 18 (81.8 %) |
| Emphasis and strong emphasis | 131 | 124 (**94.7 %**) |
| Entity and numeric character references | 17 | 4 (23.5 %) |
| Fenced code blocks | 29 | 23 (79.3 %) |
| HTML blocks | 44 | 0 (0.0 %) |
| Hard line breaks | 15 | 13 (86.7 %) |
| Images | 22 | 5 (22.7 %) |
| Indented code blocks | 12 | 11 (**91.7 %**) |
| Inlines | 1 | 1 (**100.0 %**) |
| Link reference definitions | 27 | 5 (18.5 %) |
| Links | 90 | 39 (43.3 %) |
| List items | 48 | 47 (**97.9 %**) |
| Lists | 26 | 23 (88.5 %) |
| Paragraphs | 8 | 8 (**100.0 %**) |
| Precedence | 1 | 1 (**100.0 %**) |
| Raw HTML | 21 | 9 (42.9 %) |
| Setext headings | 27 | 27 (**100.0 %**) |
| Soft line breaks | 2 | 2 (**100.0 %**) |
| Tabs | 11 | 11 (**100.0 %**) |
| Textual content | 3 | 3 (**100.0 %**) |
| Thematic breaks | 19 | 19 (**100.0 %**) |
| Wikilinks | 2 | 2 (**100.0 %**) |
| **TOTAL** | 657 | 454 (69.1 %) |
