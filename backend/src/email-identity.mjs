import { createHmac, randomBytes, randomInt, randomUUID, timingSafeEqual } from 'node:crypto';

// An unconfigured process deliberately invalidates outstanding codes on restart.
// This secret is never stored alongside the short, brute-forceable email codes.
const processSecret = randomBytes(32);
const invalid = () => new Error('INVALID_EMAIL_CHALLENGE');

export function emailIdentityOperations(db, { codeSecret = processSecret } = {}) {
  if (!(typeof codeSecret === 'string' || Buffer.isBuffer(codeSecret)) || Buffer.byteLength(codeSecret) < 32) {
    throw new Error('INVALID_EMAIL_CODE_SECRET');
  }
  db.exec(`CREATE TABLE IF NOT EXISTS verified_emails (
    email TEXT PRIMARY KEY,user_id TEXT NOT NULL UNIQUE REFERENCES users(id),verified_at INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS email_auth_challenges (
      id TEXT PRIMARY KEY,email TEXT NOT NULL,code_hash TEXT NOT NULL,
      binding_user_id TEXT REFERENCES users(id),ip TEXT NOT NULL,
      created_at INTEGER NOT NULL,expires_at INTEGER NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,consumed INTEGER NOT NULL DEFAULT 0);
    CREATE INDEX IF NOT EXISTS email_auth_email_time ON email_auth_challenges(email,created_at);
    CREATE INDEX IF NOT EXISTS email_auth_ip_time ON email_auth_challenges(ip,created_at);
    CREATE INDEX IF NOT EXISTS email_auth_time ON email_auth_challenges(created_at);`);
  const digest = (id, code) => createHmac('sha256', codeSecret).update(`${id}:${code}`).digest('hex');
  function atomic(fn) {
    db.exec('SAVEPOINT email_identity');
    try { const result = fn(); db.exec('RELEASE email_identity'); return result; }
    catch (error) { db.exec('ROLLBACK TO email_identity; RELEASE email_identity'); throw error; }
  }
  return {
    emailAccount(userId) {
      const row = db.prepare('SELECT email FROM verified_emails WHERE user_id=?').get(userId);
      return { userId, email: row?.email ?? null, emailVerified: Boolean(row) };
    },
    startEmailChallenge(value, { userId, ip = '' } = {}) {
      const email = typeof value === 'string' ? value.trim().toLowerCase() : '';
      if (email.length > 254 || !/^[a-z0-9.!#$%&'*+/=?^_`{|}~-]{1,64}@[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\.[a-z]{2,63}$/.test(email)
        || email.includes('..')) throw new Error('INVALID_EMAIL');
      const address = typeof ip === 'string' ? ip.slice(0, 200) : '';
      return atomic(() => {
        const now = Date.now();
        db.prepare('DELETE FROM email_auth_challenges WHERE created_at<=?').run(now - 3600000);
        const recent = db.prepare('SELECT count(*) AS n,max(created_at) AS latest FROM email_auth_challenges WHERE email=?').get(email);
        const ipCount = db.prepare('SELECT count(*) AS n FROM email_auth_challenges WHERE ip=?').get(address).n;
        const total = db.prepare('SELECT count(*) AS n FROM email_auth_challenges').get().n;
        if ((recent.latest !== null && now - recent.latest < 60000) || recent.n >= 5 || (address && ipCount >= 20) || total >= 10000) {
          throw new Error('EMAIL_RATE_LIMITED');
        }
        let bindingUser = null;
        if (userId && db.prepare('SELECT id FROM users WHERE id=?').get(userId)
          && !db.prepare('SELECT 1 FROM verified_emails WHERE user_id=?').get(userId)) bindingUser = userId;
        const challengeId = randomBytes(32).toString('base64url');
        const code = String(randomInt(0, 1000000)).padStart(6, '0');
        // A resend replaces the old code without erasing its rate-limit record.
        db.prepare('UPDATE email_auth_challenges SET consumed=1 WHERE email=?').run(email);
        db.prepare(`INSERT INTO email_auth_challenges
          (id,email,code_hash,binding_user_id,ip,created_at,expires_at) VALUES (?,?,?,?,?,?,?)`)
          .run(challengeId, email, digest(challengeId, code), bindingUser, address, now, now + 600000);
        return { challengeId, code, email, expiresIn: 600, resendAfter: 60 };
      });
    },
    invalidateEmailChallenge(id) {
      if (typeof id === 'string') db.prepare('UPDATE email_auth_challenges SET consumed=1 WHERE id=?').run(id);
    },
    verifyEmailChallenge(id, code, { userId, requireExisting = false } = {}) {
      if (typeof id !== 'string' || id.length !== 43) throw invalid();
      // Return validation failures from the transaction so attempt counters commit.
      const result = atomic(() => {
        const row = db.prepare('SELECT * FROM email_auth_challenges WHERE id=?').get(id);
        if (!row || row.consumed || row.expires_at <= Date.now() || row.attempts >= 5) return null;
        db.prepare('UPDATE email_auth_challenges SET attempts=attempts+1 WHERE id=?').run(id);
        if (typeof code !== 'string' || !/^\d{6}$/.test(code)
          || !timingSafeEqual(Buffer.from(row.code_hash, 'hex'), Buffer.from(digest(id, code), 'hex'))) return null;
        const owner = db.prepare('SELECT user_id FROM verified_emails WHERE email=?').get(row.email);
        if (requireExisting && !owner) return null;
        let ownerId = owner?.user_id;
        if (!ownerId) {
          if (row.binding_user_id && row.binding_user_id !== userId) return null;
          const canBind = row.binding_user_id && !db.prepare('SELECT 1 FROM verified_emails WHERE user_id=?').get(row.binding_user_id);
          ownerId = canBind ? row.binding_user_id : randomUUID();
          db.prepare('INSERT OR IGNORE INTO users(id) VALUES (?)').run(ownerId);
          db.prepare('INSERT INTO verified_emails VALUES (?,?,?)').run(row.email, ownerId, Date.now());
        }
        db.prepare('UPDATE email_auth_challenges SET consumed=1 WHERE id=?').run(id);
        return { ...this.createDeviceSession(ownerId), userId: ownerId, email: row.email, emailVerified: true };
      });
      if (!result) throw invalid();
      return result;
    },
  };
}
