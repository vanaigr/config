#!/usr/bin/env -S node
import proc from 'node:child_process'

/**
 * Swaps Cyrillic characters:
 * т ↔ м
 * и ↔ ц
 *
 * Usage:
 *   ./swap-clipboard-chars.ts          - Swaps clipboard content
 *   ./swap-clipboard-chars.ts "text"   - Swaps provided text and prints to stdout
 */

import { execSync } from 'child_process';

function getClipboard(): string {
    try {
        return execSync('xclip -selection clipboard -o', { encoding: 'utf8' });
    } catch (error) {
        throw new Error(`Failed to read clipboard: ${error.message}`);
    }
}

function setClipboard(text: string): void {
    try {
        const xclip = proc.spawn('xclip', ['-selection', 'clipboard'], {
            detached: true,
            stdio: ['pipe', 'ignore', 'ignore'],
            env: { DISPLAY: ':0' },
        });
        xclip.stdin.end(text)
        xclip.unref();
        /*
    execSync('xclip -selection clipboard -i', {
      input: text,
      encoding: 'utf8',
    });
        */
    } catch (error) {
        throw new Error(`Failed to set clipboard: ${error.message}`);
    }
}

function swapChars(text: string): string {
    // Create a mapping for the swaps
    const swapMap: Record<string, string> = {
        'т': 'м',
        'м': 'т',
        'и': 'ц',
        'ц': 'и',
        'Т': 'М',
        'М': 'Т',
        'И': 'Ц',
        'Ц': 'И',
    };

    return text.split('').map(char => {
        if(swapMap[char] === undefined) return char

        if(Math.random() < 0.8) return char

        return swapMap[char]
    }).join('');
}

function main() {
    try {
        // Check if input is provided via command-line arguments
        const args = process.argv.slice(2);

        let swapped: string
        if (args.length > 0) {
            // Use command-line arguments as input
            const input = args.join(' ');
            swapped = swapChars(input);
        } else {
            // Use clipboard as input and output
            const clipboardContent = getClipboard();
            swapped = swapChars(clipboardContent);
        }

        setClipboard(swapped);
        console.log("Clipboard swapped successfully!");
    } catch (error) {
        console.error("Error:", error.message);
        process.exit(1);
    }
}

main();
