// Brainrot Bazaar: Tide Rush — authored entrypoint for make.fun roblox-brainrot-01.
// Node 22, standard library only. The game is the Rojo project in this directory, built with
// `rojo build default.project.json --output game.rbxl`; this program hands the built place in.
// It copies game.rbxl, src/, screenshots/ and PLAY.json to the output dir and writes dossier.json,
// the summary the judge reads, with the vendored make.fun library.
//
// Output names may hold only letters, digits, . _ and - (and cannot start with a dot): the grader
// refuses an entry whose output holds a .gitkeep, .DS_Store or other dotted name at any depth.
// OUT is MAKEFUN_OUTPUT_DIR outside the grader, which always uses /output.
// Authorship note: written by @rizkijack's recorded coding agent; source of truth is src/ + this file.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: leave out every file and directory whose name starts with a dot. */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });
}

// The scorer's own caps: only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots, one over 256 KiB, a place over 500000 instances,
// scripts whose sources are over 8 MiB or whose paths are over 1048576 characters in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
