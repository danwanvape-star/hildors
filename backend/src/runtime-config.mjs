import { readFileSync } from 'node:fs';
import { isAbsolute, resolve } from 'node:path';

export function runtimeConfig(env, defaultDirectory) {
  const mode = env.HILDORS_MODE || 'local';
  if (!['local', 'team-staging'].includes(mode)) throw new Error('Unsupported runtime mode');
  const port = Number(env.HILDORS_PORT || 8787);
  if (!Number.isInteger(port) || port < 1024 || port > 65535) throw new Error('Invalid port');
  if (env.HILDORS_ADMIN_TOKEN && env.HILDORS_ADMIN_TOKEN_FILE) throw new Error('Configure only one admin credential source');
  const adminToken = env.HILDORS_ADMIN_TOKEN_FILE
    ? readFileSync(env.HILDORS_ADMIN_TOKEN_FILE, 'utf8').trim() : env.HILDORS_ADMIN_TOKEN || '';
  if (mode === 'team-staging') {
    if (!env.HILDORS_DATA_DIR || !isAbsolute(env.HILDORS_DATA_DIR)) throw new Error('Staging requires an absolute data directory');
    if (adminToken.length < 32 || /[\r\n]/.test(adminToken)) throw new Error('Staging requires a strong admin credential');
  }
  return { mode, port, host: '127.0.0.1', adminToken,
    directory: resolve(env.HILDORS_DATA_DIR || defaultDirectory), seedDemos: mode === 'local' };
}
