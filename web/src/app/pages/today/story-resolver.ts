import { isPlatformBrowser } from '@angular/common';
import { inject, makeStateKey, PLATFORM_ID, REQUEST_CONTEXT, TransferState } from '@angular/core';
import { ActivatedRouteSnapshot, RedirectCommand, Router } from '@angular/router';

import type { Story } from './feed/types';

/** What the collector hands the renderer with a story's page: the story, as the feed has it now. */
export interface StoryRenderContext {
  readonly story: Story;
}

/**
 * The story for /today/<id>, wherever it is.
 *
 * A page the collector rendered — a story newer than the last deploy, or one
 * approved in new words since — was given the story with the request, and
 * carries it to the browser in its transfer state, so hydrating it reads the
 * same story the HTML was made from, board positions and all, without asking
 * for anything. A page the deploy prerendered reads the build's own module.
 * Failing all of those — a link followed inside the site to a story it has
 * never heard of — the feed's own file, which has no positions in it, so that
 * page shows the board and not the replay.
 */
export function resolveStory(route: ActivatedRouteSnapshot): Promise<Story | RedirectCommand> {
  // Everything injected before the first await: a resolver's injection
  // context does not survive one.
  const id = route.paramMap.get('id') ?? '';
  const router = inject(Router);
  const state = inject(TransferState);
  const context = inject(REQUEST_CONTEXT, { optional: true }) as StoryRenderContext | null;
  const browser = isPlatformBrowser(inject(PLATFORM_ID));
  const key = makeStateKey<Story>(`story:${id}`);

  return (async () => {
    // The collector's copy first, on the server and then in the browser: it is
    // the newer, and for a story approved in new words since the last deploy
    // it is the one whose words the page must have — the build's copy is not.
    if (context?.story?.id === id) {
      state.set(key, context.story);
      return context.story;
    }
    const carried = state.get(key, null);
    if (carried) return carried;

    const { STORIES } = await import('./feed/stories');
    const load = STORIES[id];
    if (load) return load();

    if (browser && /^[a-z0-9-]{1,120}$/.test(id)) {
      try {
        const response = await fetch(`/media/feed/v1/stories/${id}.json`);
        if (response.ok) return (await response.json()) as Story;
      } catch {
        // The 404 below.
      }
    }
    return new RedirectCommand(router.parseUrl('/404'));
  })();
}
