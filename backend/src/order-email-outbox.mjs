import { randomUUID } from 'node:crypto';

const LEASE_MS = 60_000;
const MAX_ATTEMPTS = 8;
// Stop conservatively before the provider's 24-hour idempotency retention ends.
const RETRY_WINDOW_MS = 23 * 60 * 60 * 1000;
const messages = {
  free_review: 'Your customization request has been received and is awaiting review.',
  needs_info: 'More information is needed for your customization request.',
  quoted: 'A quote is ready for your customization request.',
  user_acceptance: 'Your customization is ready for your review and acceptance.',
  delivered: 'Your customization order has been delivered.',
  rejected: 'Your customization request was not approved.',
};

export function orderEmailOutboxOperations(db) {
  db.exec(`CREATE TABLE IF NOT EXISTS order_email_outbox (
    id TEXT PRIMARY KEY, order_id TEXT NOT NULL, order_version INTEGER NOT NULL,
    order_status TEXT NOT NULL, recipient TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'pending' CHECK(state IN ('pending','sending','sent','failed')),
    attempts INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL,
    next_attempt_at INTEGER NOT NULL, first_attempt_at INTEGER,
    lease_token TEXT, lease_until INTEGER, sent_at INTEGER, last_error TEXT);
    CREATE INDEX IF NOT EXISTS order_email_outbox_due ON order_email_outbox(state,next_attempt_at);
    DROP TRIGGER IF EXISTS order_email_insert;
    CREATE TRIGGER order_email_insert AFTER INSERT ON customization_orders
    WHEN NEW.status='free_review'
      AND COALESCE(json_array_length(NEW.document,'$.materials'),0)>=COALESCE(json_extract(NEW.document,'$.materialCount'),0)
    BEGIN
      INSERT OR IGNORE INTO order_email_outbox
        (id,order_id,order_version,order_status,recipient,created_at,next_attempt_at)
      SELECT NEW.id||':received',NEW.id,NEW.version,NEW.status,email,
        CAST(unixepoch('subsec')*1000 AS INTEGER),CAST(unixepoch('subsec')*1000 AS INTEGER)
      FROM verified_emails WHERE user_id=NEW.user_id;
    END;
    CREATE TRIGGER IF NOT EXISTS order_email_materials_received AFTER UPDATE OF document ON customization_orders
    WHEN NEW.status='free_review'
      AND COALESCE(json_array_length(OLD.document,'$.materials'),0)<COALESCE(json_extract(OLD.document,'$.materialCount'),0)
      AND COALESCE(json_array_length(NEW.document,'$.materials'),0)>=COALESCE(json_extract(NEW.document,'$.materialCount'),0)
    BEGIN
      INSERT OR IGNORE INTO order_email_outbox
        (id,order_id,order_version,order_status,recipient,created_at,next_attempt_at)
      SELECT NEW.id||':received',NEW.id,NEW.version,NEW.status,email,
        CAST(unixepoch('subsec')*1000 AS INTEGER),CAST(unixepoch('subsec')*1000 AS INTEGER)
      FROM verified_emails WHERE user_id=NEW.user_id;
    END;
    CREATE TRIGGER IF NOT EXISTS order_email_transition AFTER UPDATE OF status ON customization_orders
    WHEN OLD.status<>NEW.status AND NEW.status IN ('needs_info','quoted','user_acceptance','delivered','rejected')
    BEGIN
      INSERT OR IGNORE INTO order_email_outbox
        (id,order_id,order_version,order_status,recipient,created_at,next_attempt_at)
      SELECT NEW.id||':'||NEW.version||':'||NEW.status,NEW.id,NEW.version,NEW.status,email,
        CAST(unixepoch('subsec')*1000 AS INTEGER),CAST(unixepoch('subsec')*1000 AS INTEGER)
      FROM verified_emails WHERE user_id=NEW.user_id;
    END;`);

  return {
    claimOrderEmail(now = Date.now()) {
      db.exec('BEGIN IMMEDIATE');
      try {
        db.prepare(`UPDATE order_email_outbox SET state='failed',last_error='RETRY_EXHAUSTED',lease_token=NULL,lease_until=NULL
          WHERE state IN ('pending','sending') AND (state='pending' OR lease_until<=?)
          AND (attempts>=? OR (first_attempt_at IS NOT NULL AND first_attempt_at<=?))`)
          .run(now, MAX_ATTEMPTS, now - RETRY_WINDOW_MS);
        const token = randomUUID();
        const row = db.prepare(`UPDATE order_email_outbox SET state='sending',attempts=attempts+1,
          first_attempt_at=COALESCE(first_attempt_at,?),lease_token=?,lease_until=?
          WHERE id=(SELECT id FROM order_email_outbox
            WHERE (state='pending' AND next_attempt_at<=?) OR (state='sending' AND lease_until<=?)
            ORDER BY created_at,id LIMIT 1) RETURNING *`)
          .get(now, token, now + LEASE_MS, now, now);
        db.exec('COMMIT');
        return row ? {id:row.id,orderId:row.order_id,status:row.order_status,to:row.recipient,leaseToken:token} : null;
      } catch (error) { db.exec('ROLLBACK'); throw error; }
    },
    completeOrderEmail(id, leaseToken, now = Date.now()) {
      return db.prepare(`UPDATE order_email_outbox SET state='sent',sent_at=?,lease_token=NULL,lease_until=NULL,last_error=NULL
        WHERE id=? AND state='sending' AND lease_token=?`).run(now,id,leaseToken).changes === 1;
    },
    failOrderEmail(id, leaseToken, errorCode, retryable, now = Date.now()) {
      const row = db.prepare("SELECT attempts,first_attempt_at FROM order_email_outbox WHERE id=? AND state='sending' AND lease_token=?").get(id,leaseToken);
      if (!row) return false;
      const next = now + Math.min(60_000 * 2 ** (row.attempts - 1), 3_600_000);
      const retry = retryable && row.attempts < MAX_ATTEMPTS && next < row.first_attempt_at + RETRY_WINDOW_MS;
      const safeCode = errorCode === 'DELIVERY_PERMANENT' ? errorCode : 'DELIVERY_TRANSIENT';
      return db.prepare(`UPDATE order_email_outbox SET state=?,next_attempt_at=?,last_error=?,lease_token=NULL,lease_until=NULL
        WHERE id=? AND state='sending' AND lease_token=?`)
        .run(retry?'pending':'failed',next,safeCode,id,leaseToken).changes === 1;
    },
    orderEmailOutboxSummary() {
      const counts = {pending:0,sending:0,sent:0,failed:0};
      for (const row of db.prepare('SELECT state,COUNT(*) AS count FROM order_email_outbox GROUP BY state').all()) counts[row.state]=row.count;
      return counts;
    },
  };
}

export async function drainOrderEmails(store, mailer, {now = Date.now, batchSize = 20} = {}) {
  const result = {sent:0,failed:0};
  if (!mailer || mailer.enabled !== true || typeof mailer.send !== 'function') return result;
  const time = () => typeof now === 'function' ? now() : now;
  const limit = Number.isFinite(batchSize) ? Math.max(0,Math.min(100,Math.floor(batchSize))) : 20;
  for (let index=0;index<limit;index++) {
    const row = store.claimOrderEmail(time());
    if (!row) break;
    try {
      await mailer.send({to:row.to,subject:'Hildors customization order update',
        text:`${messages[row.status]}\n\nOrder: ${row.orderId}\nOpen Hildors App → orders to view details and any required action.`,
        idempotencyKey:row.id});
      if (store.completeOrderEmail(row.id,row.leaseToken,time())) result.sent++;
    } catch (error) {
      const status = Number(error?.status ?? error?.statusCode);
      const retryable = typeof error?.retryable === 'boolean' ? error.retryable
        : !(status >= 400 && status < 500 && status !== 408 && status !== 429);
      store.failOrderEmail(row.id,row.leaseToken,retryable?'DELIVERY_TRANSIENT':'DELIVERY_PERMANENT',retryable,time());
      result.failed++;
    }
  }
  return result;
}
