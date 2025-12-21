import fs from 'node:fs'
const file = fs.readFileSync('./UnicodeData.txt').toString()
const rows = file.trim().split('\n').map(line => line.split(';'))

const output = []

for(const row of rows) {
    const code = parseInt(row[0], 16)
    output.push(String.fromCodePoint(code) + ' ' + row[1] + ' ' + code)
}

fs.writeFileSync('characters.txt', output.join('\n'))
