#!/usr/bin/env node

import proc from 'node:child_process'
import fs from 'node:fs'

async function main() {
  const pr = getCurrentPRNumber()
  const checks = getChecks(pr)
  if(checks.length === 0) {
    console.log('No checks')
  }

  const toCheck: any[] = []
  const cannotUse: any[] = []
  for(const check of checks) {
    if(check.state !== 'FAILURE') continue

    let url: URL
    try { url = new URL(check.link) } catch(error) {
      cannotUse.push(check)
      continue
    }

    if(url.hostname !== 'dev.azure.com') {
      cannotUse.push(check)
      continue
    }

    toCheck.push({ ...check, link: url })
  }

  if(cannotUse.length > 0) {
    console.warn('Could not check pipelines:', cannotUse)
  }

  if(toCheck.length === 0) {
    console.log('No pipelines to check')
    return
  }

  const checkResults: string[] = []

  for(const check of toCheck) {
    const [_, org, project] = check.link.pathname.split('/')
    const buildId = check.link.searchParams.get('buildId')

    const stagesUrl = new URL('https://dev.azure.com')
    stagesUrl.pathname = org + '/' + project + '/_apis/build/builds/' + buildId + '/timeline'
    stagesUrl.searchParams.set('api-version', '7.0')

    const stages: any[] = (await request(stagesUrl)).records
    const failed = stages.filter(it => {
      return it.type === 'Task'
        && (it.result === 'succeededWithIssues' || it.result === 'failed')
        && it.name !== 'Fail job if any check failed'
    })

    if(failed.length === 0) {
      console.error('Unexpected - no errors but failed:', check, stages)
      continue
    }

    const logs = await Promise.all(failed.map(it => requestText(it.log.url)))

    const logResults: string[] = []
    for(let i = 0; i < failed.length; i++) {
      const log = logs[i]
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map(it => it.replace(/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+.+? /, ''))
        .join('\n')

      logResults.push('## ' + failed[i].name + '\n\n```\n' + log + '\n```\n')
    }

    checkResults.push('# ' + check.name + '\n\n' + logResults.join('\n'))
  }

  const result = checkResults.join('\n')

  fs.writeFileSync('./pr-checks.md', result)
  console.log('done')
}


// https://dev.azure.com/oee-intellisuite/oee-intellisuite/_apis/build/builds/6442/timeline?api-version=7.0

function getChecks(pr: number): any[] {
  return execJson('gh', 'pr', 'checks', '' + pr, '--json', ['name', 'state', 'link'].join(','))
}

function getCurrentPRNumber() {
  return execJson('gh', 'pr', 'view', '--json', 'number').number
}

function execJson(name: string, ...args: string[]) {
  try {
    const text = proc.spawnSync(name, args, { stdio: ['ignore', 'pipe', 'inherit'] })
    return JSON.parse(text.stdout.toString())
  }
  catch(error) {
    console.error(`Error executing command: ${name} ${args.join(' ')}`);
    console.error(error.message);
    throw new Error('failed')
  }
}

async function request(url: URL, options: RequestInit = {}) {
  let res: Response;

  try {
    res = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });
  } catch (err) {
    throw new Error(`Network error: ${err.message}`);
  }

  if (!res.ok) {
    const message = res.statusText || 'Request failed';

    const error: any = new Error(message);
    error.status = res.status;
    error.body = await res.text().catch(err => err);
    throw error;
  }

  let data: any;
  try {
    data = await res.json();
  } catch {
    throw new Error(`Invalid JSON response (status ${res.status})`);
  }


  return data;
}

async function requestText(url: URL, options: RequestInit = {}) {
  let res: Response;

  try {
    res = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });
  } catch (err) {
    throw new Error(`Network error: ${err.message}`);
  }

  if (!res.ok) {
    const message = res.statusText || 'Request failed';

    const error: any = new Error(message);
    error.status = res.status;
    error.body = await res.text().catch(err => err);
    throw error;
  }

  let data: string;
  try {
    data = await res.text();
  } catch {
    throw new Error(`Invalid response (status ${res.status})`);
  }

  return data;
}

main()
