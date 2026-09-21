// Additive content localization. Legacy text is never replaced by a translation.
export function validTranslations(value, fields = { title: 120, description: 10000 }) {
  if (value === undefined) return true;
  if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
  return Object.entries(value).every(([language, entry]) => ['en','zh'].includes(language)
    && entry && typeof entry === 'object' && !Array.isArray(entry)
    && Object.entries(entry).every(([key, text]) => Object.hasOwn(fields,key)
      && typeof text === 'string' && text.length <= fields[key]));
}
export function validClipTranslations(value) {
  return value === undefined || (Array.isArray(value) && value.length <= 100
    && new Set(value.map(x => x?.id)).size === value.length
    && value.every(x => x && typeof x.id === 'string' && validTranslations(x.translations)
      && Object.keys(x).every(key => ['id','translations'].includes(key))));
}
export function requestLanguage(url, headers) {
  if (url.searchParams.has('lang')) return normalizeLanguage(url.searchParams.get('lang'));
  const candidates = String(headers['accept-language'] || '').split(',').map((part,index) => {
    const [language,...parameters] = part.trim().split(';');
    const raw = parameters.find(p => p.trim().startsWith('q='));
    const quality = raw ? Number(raw.trim().slice(2)) : 1;
    return {language,quality,index};
  }).filter(x => Number.isFinite(x.quality) && x.quality > 0 && x.quality <= 1)
    .sort((a,b) => b.quality-a.quality || a.index-b.index);
  return normalizeLanguage(candidates[0]?.language);
}
export function normalizeLanguage(value) { return /^zh(?:[-_]|$)/i.test(value || '') ? 'zh' : 'en'; }
export function localizedText(value, language, fields = ['title','description']) {
  const result = {language, missingFields: [], fallbackFields: []};
  for (const key of fields) {
    const selected = value.translations?.[language]?.[key];
    const english = value.translations?.en?.[key];
    if (!selected?.trim()) result.missingFields.push(key);
    if (!selected?.trim()) result.fallbackFields.push(key);
    result[key] = selected?.trim() ? selected : english?.trim() ? english : value[key] || '';
  }
  return result;
}
export function contentFields(value) {
  return { ...(value.description !== undefined ? {description:value.description} : {}),
    ...(value.translations !== undefined ? {translations:value.translations} : {}) };
}
export function publicTag(tag, language) {
  return {...tag, ...(language ? {localized:localizedText(tag,language,['name'])} : {})};
}
export function localizedPackage(item, language, tags) {
  const tagDetails = (item.tags || []).map((name,index) => tags.find(t => t.id === item.tagIds?.[index])
    || tags.find(t => t.name === name)).filter(Boolean).map(tag => publicTag(tag,language));
  return {translations:item.translations || {}, tagIds:item.tagIds || tagDetails.map(t => t.id), tagDetails,
    localized:localizedText(item,language)};
}
