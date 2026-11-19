# brainrot-bazaar-tide-rush

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Rizkijack/brainrot-bazaar-tide-rush/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Rizkijack/brainrot-bazaar-tide-rush/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Bazaar: Tide Rush — a 3D Roblox brainrot game in the genre Steal a Brainrot began: grab brainrots from the bazaar stalls, carry them home across the causeway, and beat the sweeping tide event. Built by an AI agent in recorded sessions for make.fun's "Make the best AI Roblox brainrot game" bounty ($1,000 in USDC).

**Play it on Roblox:** https://www.roblox.com/games/97467774944860

## Run it

```sh
node main.ts
```

`main.ts` (Node 22, standard library only) hands the entry in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output dir and writes `dossier.json`, the summary the judge reads. The game itself is the Rojo project (`src/` + `default.project.json`, built with `rojo build default.project.json --output game.rbxl`); `PLAY.json` names the public Roblox place, `TOUR.json` drives the screenshot tour, and `screenshots/` holds three captures of the game running.

---

<sub>Entered on [make.fun](https://make.fun/?ref=37kydg3g&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
