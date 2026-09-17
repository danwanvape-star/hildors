export const visibleClip = clip => Boolean(clip.media || clip.bundledAsset) && (!clip.visibility || clip.visibility === 'published');
export const visiblePackage = item => item?.status === 'published' && item.clips.some(visibleClip);
export const activeClips = item => item.clips.filter(c => c.visibility !== 'withdrawn' && (item.format !== 'package' || c.media));
export const checkedClips = item => activeClips(item).length > 0 && activeClips(item).every(c => c.media?.inspection?.status === 'checked');
export const editableClip = (item, clip) => Boolean(clip) && (item?.status === 'draft'
  || (item?.status === 'published' && item.format === 'package' && !item.ownerId && ['draft','withdrawn'].includes(clip.visibility)));
