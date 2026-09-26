import { FEED } from './feed';
import type { StorySummary } from './feed/types';

/** The stories this build was made with, by id. */
export const BUILT = new Set(FEED.map((s) => s.id));

/**
 * The stories in the live feed that this build does not have — the ones since
 * the last deploy — read in the browser from the file the app reads. Whatever
 * is in it is public: which stories are is the collector's FEED_PUBLIC.
 */
export async function liveStories(folder: string | null = null, known: ReadonlySet<string> = BUILT): Promise<StorySummary[]> {
  try {
    // The copy of the feed in the page's language, beside the English one.
    const response = await fetch(`/media/feed/v1/${folder ? `${folder}/` : ''}latest.json`);
    if (!response.ok) return [];
    const latest = (await response.json()) as { stories?: StorySummary[] };
    return (latest.stories ?? []).filter((s) => !known.has(s.id));
  } catch {
    // The built list stands on its own; the live one only adds to it.
    return [];
  }
}

/** Whether the feed says the collector has made this story its own page. */
export function hasPage(story: Pick<StorySummary, 'id' | 'url'>): boolean {
  return story.url === `https://brasspawn.com/today/${story.id}`;
}

/**
 * Where a story opens. One this build has: its page, inside the app. One
 * newer, whose page the collector made: that page, loaded as a page — it
 * carries the story it was made from, replay and all, which navigating to it
 * inside the app would not have. One from before the collector made pages:
 * the page that draws a story from the feed.
 */
export function storyLink(story: StorySummary): {
  path: string[];
  query: Record<string, string> | null;
  href: string | null;
} {
  if (BUILT.has(story.id)) return { path: ['/today', story.id], query: null, href: null };
  if (hasPage(story)) return { path: [], query: null, href: `/today/${story.id}` };
  return { path: ['/today/story'], query: { id: story.id }, href: null };
}
