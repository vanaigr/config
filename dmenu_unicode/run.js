import process from 'node:process'
import proc from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'

const file = fs.readFileSync(path.join(import.meta.dirname, '/characters.txt')).toString()

const dmenu = proc.spawnSync(
    'dmenu',
    ['-i', '-l', '15', '-fn', 'monospace-16'],
    { input: file, encoding: 'utf8', env: { DISPLAY: ':0' } },
);
process.stderr.write(dmenu.stderr)
const char = dmenu.stdout.match(/^.*? /)[0].trim()

const xclip = proc.spawn('xclip', ['-selection', 'clipboard'], {
    detached: true,
    stdio: ['pipe', 'ignore', 'ignore'],
    env: { DISPLAY: ':0' },
});
xclip.stdin.end(char)
xclip.unref();
