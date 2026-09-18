import { randomUUID } from 'node:crypto';

const directions = ['简单动作', '歌舞表演', '特效炫技', '角色成长'];
function editable(profile, version, allowLegacy = false) {
  if (!profile || !Number.isInteger(version) || profile.version !== version) throw new Error('CONFLICT');
  if (!['draft', 'rejected'].includes(profile.status)
    && !(allowLegacy && profile.applicationVersion !== 2 && profile.status === 'pending')) throw new Error('CREATOR_APPLICATION_LOCKED');
  if (!allowLegacy && profile.applicationVersion !== 2) throw new Error('CREATOR_APPLICATION_MIGRATION_REQUIRED');
}
function fields(value, tags) {
  const strings = (items, allowed, limit) => Array.isArray(items) && items.length > 0 && items.length <= limit
    && new Set(items).size === items.length && items.every(item => typeof item === 'string' && allowed.includes(item));
  if (!value || typeof value.displayName !== 'string' || !/^[A-Za-z0-9]+$/.test(value.displayName.trim()) || !/[A-Za-z]/.test(value.displayName) || value.displayName.trim().length > 80
    || typeof value.email !== 'string' || value.email.length > 254 || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value.email.trim())
    || !strings(value.characterTags, tags.filter(t => t.active).map(t => t.name), 12)
    || !strings(value.skillTags, directions, 4)
    || typeof value.marketRegion !== 'string' || value.marketRegion.length > 32
    || typeof value.agreementVersion !== 'string' || !value.agreementVersion.trim() || value.agreementVersion.length > 120
    || value.adultConfirmed !== true || value.agreementAccepted !== true) throw new Error('INVALID_CREATOR_APPLICATION');
  return { displayName: value.displayName.trim(), email: value.email.trim().toLowerCase(),
    characterTags: value.characterTags, skillTags: value.skillTags, marketRegion: value.marketRegion.trim(),
    agreementVersion: value.agreementVersion.trim(), adultConfirmed: true, agreementAccepted: true };
}

export function creatorApplicationOperations(db) {
  function persist(store, current, patch, status = current.status) {
    const document = { ...current, ...patch };
    for (const key of ['id', 'userId', 'version', 'status', 'createdAt', 'updatedAt']) delete document[key];
    const changed = db.prepare('UPDATE creator_profiles SET document=?,email_normalized=?,status=?,version=version+1,updated_at=? WHERE id=? AND version=?')
      .run(JSON.stringify(document), document.email, status, new Date().toISOString(), current.id, current.version);
    if (!changed.changes) throw new Error('CONFLICT');
    return store.getCreatorProfile(current.id);
  }
  return {
    checkCreatorApplicationEditable(userId, version) {
      const profile = this.getCreatorProfile(userId); editable(profile, version); return profile;
    },
    saveCreatorApplication(userId, value) {
      const previous = this.getCreatorProfile(userId);
      if (previous) editable(previous, value?.version, true);
      else if (value?.version !== undefined) throw new Error('CONFLICT');
      const document = fields(value, this.contentTags());
      const owner = db.prepare('SELECT user_id FROM creator_profiles WHERE email_normalized=?').get(document.email);
      if (owner && owner.user_id !== userId) throw new Error('EMAIL_IN_USE');
      const now = new Date().toISOString();
      const patch = { ...document, applicationVersion: 2, agreementAcceptedAt: now,
        applicationVideos: previous?.applicationVideos ?? [] };
      if (previous) return persist(this, previous, patch, 'draft');
      const id = randomUUID();
      db.prepare('INSERT INTO creator_profiles (id,user_id,version,status,document,email_normalized,created_at,updated_at) VALUES (?,?,1,?,?,?,?,?)')
        .run(id, userId, 'draft', JSON.stringify(patch), document.email, now, now);
      return this.getCreatorProfile(id);
    },
    attachCreatorApplicationVideo(userId, version, video) {
      const profile = this.checkCreatorApplicationEditable(userId, version);
      if ((profile.applicationVideos ?? []).length >= 10) throw new Error('CREATOR_APPLICATION_VIDEO_LIMIT');
      if (video.inspection?.status !== 'checked' || video.inspection.validation !== 'decoded') throw new Error('CREATOR_APPLICATION_VIDEO_INVALID');
      return persist(this, profile, {applicationVideos: [...(profile.applicationVideos ?? []), video]});
    },
    removeCreatorApplicationVideo(userId, version, id) {
      const profile = this.checkCreatorApplicationEditable(userId, version);
      const videos = (profile.applicationVideos ?? []).filter(video => video.id !== id);
      if (videos.length === (profile.applicationVideos ?? []).length) throw new Error('CONFLICT');
      return persist(this, profile, {applicationVideos: videos});
    },
    submitCreatorApplication(userId, version) {
      const profile = this.checkCreatorApplicationEditable(userId, version);
      fields(profile, this.contentTags());
      if (!profile.applicationVideos?.length || profile.applicationVideos.some(video => video.inspection?.status !== 'checked'
        || video.inspection.validation !== 'decoded')) throw new Error('CREATOR_APPLICATION_VIDEO_REQUIRED');
      return persist(this, profile, {submittedAt: new Date().toISOString()}, 'pending');
    },
  };
}
