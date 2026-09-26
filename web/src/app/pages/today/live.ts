import { FEED } from './feed';
import type { StorySummary } from './feed/types';

/** The stories this build was made with, by id. */
export const BUILT = new Set(FEED.map((s) => s.id));

/**
 * The stories in the live feed that this build does not have — the ones since
 * the last deploy — read in the browser from the file the app reads. Whatever
 * is in it is public: which stories are is the collector's FEED_PUBLIC.
 */
export async function liveStories(): Promise<StorySummary[]> {
  try {
    const response = await fetch('/media/feed/v1/latest.json');
    if (!response.ok) return [];
    const latest = (await response.json()) as { stories?: StorySummary[] };
    return (latest.stories ?? []).filter((s) => !BUILT.has(s.id));
  } catch {
    // The built list stands on its own; the live one only adds to it.
    return [];
  }
}

/** Where a story opens: its own page, or the one that draws a new story from the feed. */
export function storyLink(story: StorySummary): { path: string[]; query: Record<string, string> | null } {
  return BUILT.has(story.id)
    ? { path: ['/today', story.id], query: null }
    : { path: ['/today/story'], query: { id: story.id } };
}
