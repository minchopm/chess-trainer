import { afterNextRender, ChangeDetectionStrategy, Component, computed, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';
import { Diagram } from './diagram';
import { FEED } from './feed';
import type { Story } from './feed/types';
import { longDate, moveLabel, movePairs, occasion, playerText, resultText, scoreText } from './words';

/**
 * One game from the daily feed, drawn: the board at the moment that mattered,
 * the story, the whole score, and where the moves came from.
 *
 * The page's body, and nothing about its address — so that a story
 * prerendered at the last deploy (StoryPage) and one newer than it, read from
 * the live feed in the browser (StoryShell), are the same page.
 */
@Component({
  selector: 'bp-story-view',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, PageHead, Reveal, Diagram],
  templateUrl: './story-view.html',
  styleUrl: './story-view.scss',
})
export class StoryView {
  readonly story = input.required<Story>();

  protected readonly site = SITE;
  protected readonly moveLabel = moveLabel;
  protected readonly scoreText = scoreText;
  protected readonly playerText = playerText;
  protected readonly resultText = resultText;

  protected readonly occasion = computed(() => occasion(this.story()));
  protected readonly date = computed(() => longDate(this.story().date));
  protected readonly paragraphs = computed(() => this.story().body.split(/\n\n+/));
  protected readonly pairs = computed(() => movePairs(this.story().moves));
  /** The app's own address for this story. Opens Brass Pawn on it when installed. */
  protected readonly appLink = computed(() => `brasspawn://today/${this.story().id}`);

  /**
   * The App Clip's link for this story — the same form the game invitations
   * use. On an iPhone or iPad with the app it opens the app on this game; on
   * one without, the clip, which shows the game and keeps it in the shared
   * container, so the app installed from the clip opens on it. The only way a
   * game survives the trip through the App Store.
   */
  protected readonly clipLink = computed(
    () => `https://appclip.apple.com/id?p=${SITE.clipBundleId}&s=${encodeURIComponent(this.story().id)}`,
  );

  /**
   * Whether this is a device a clip can open on. Decided in the browser: the
   * prerendered page offers the App Store, which is right everywhere, and an
   * iPhone swaps in the link that goes further. iPadOS says it is a Mac, and
   * is told apart by having a touch screen.
   */
  protected readonly onPhone = signal(false);

  constructor() {
    afterNextRender(() => {
      const ua = navigator.userAgent;
      this.onPhone.set(/iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1));
    });
  }
  protected readonly flip = computed(() => this.story().result === '0-1');

  /** The neighbours in the feed as this build has it, for reading on. */
  protected readonly neighbours = computed(() => {
    const i = FEED.findIndex((s) => s.id === this.story().id);
    if (i < 0) return { newer: null, older: FEED[0] ?? null };
    return { newer: i > 0 ? FEED[i - 1] : null, older: FEED[i + 1] ?? null };
  });
}
