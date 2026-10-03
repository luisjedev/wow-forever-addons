# Item name search data

`ItemNames.lua` contains only names for the 579 reagent IDs from **LibItemDB v1.1.4** by Pimptasty, released September 30, 2026. No library code or dependency is included.

- [Project](https://www.curseforge.com/wow/addons/libitemdb)
- [Release](https://www.curseforge.com/wow/addons/libitemdb/files/9014697)
- [Source archive](https://edge.forgecdn.net/files/9014/697/ItemDB-ItemDB-v1.1.4.zip)
- Archive SHA-256: `9e6a265a1c1f0b4090340e6ea00d7bef36fe7d6c9178cc5801981a6993736509`

Extraction: take the numeric keys of the first `LoadReagentUses` table in `ItemDB/Data/Forever/_core/Reagents.lua`; retain exactly those IDs from each `ItemDB/Data/Forever/{enUS,esES,esMX,frFR,deDE,itIT,ptBR,ruRU,koKR,zhCN,zhTW}/Names.lua`, ordered by ascending ID. Preserve the source spelling and both Spanish variants. The archive was read as text, without executing its Lua.

The reagent and translated-name headers identify build **1.60.1.69913**. The English header gives only interface **16001**. This is earlier-build search data, not a verified catalog for the target build 70205. It provides alternate search terms only for materials independently discovered by GuildStock. Native names, quantities, profession associations and item links still come from the client. Missing aliases fall back to the native name. New or renamed materials can need a data update.

The source includes the following license:

```text
MIT License

Copyright (c) 2026 Pimptasty

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
