#!/usr/bin/env node
import { Temporal as T } from 'temporal-polyfill'

// destTz is optional, default is UTC

function main() {
    const args = process.argv.slice(2)
    const destTz = args[2] || 'UTC'
    console.log('  ' + args[0] + ' ' + args[1] + ' -> ' + destTz)
    for(const zdt of convert(args[0], args[1], destTz)) {
        console.log(zdt.toPlainDateTime().toString())
    }
    process.exit(0)
}

function convert(
    sourceTime: string,
    sourceTz: string,
    destTz: string,
) {
    const time1 = T.PlainDateTime.from(sourceTime)
        .toZonedDateTime(sourceTz, { disambiguation: 'earlier' })
        .toInstant()
        .toZonedDateTimeISO(destTz)

    const time2 = T.PlainDateTime.from(sourceTime)
        .toZonedDateTime(sourceTz, { disambiguation: 'later' })
        .toInstant()
        .toZonedDateTimeISO(destTz)

    if(T.ZonedDateTime.compare(time1, time2) === 0) return [time1]
    return [time1, time2]
}

main()
