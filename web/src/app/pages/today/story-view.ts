import { afterNextRender, ChangeDetectionStrategy, Component, computed, effect, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { Reveal } from '../../core/reveal';
import { SITE } from '../../core/site';
import { PageHead } from '../../shared/page-head/page-head';
import { Board } from '../../board/board';
import { BoardLook } from '../../board/look';
import { FEED } from './feed';
import type { Story, StorySummary } from './feed/types';
import { reportWords } from '../reports/words';
import { fill, listPath, reportPath, storyLocales, storyPath, TodayLanguage } from './i18n';
import { moveLabel, movePairs, playerText, resultText, scoreText } from './words';

/**
 * Moves the site gives away before it hands the game over. Enough to see the
 * key move played and a little either side of it; the rest of the game — and
 * playing the position yourself — is what the app is for.
 */
const FREE_MOVES = 5;

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
  imports: [RouterLink, PageHead, Reveal, Board, BoardLook],
  templateUrl: './story-view.html',
  styleUrl: './story-view.scss',
})
export class StoryView {
  readonly story = input.required<Story>();
  /** The stories around this one, in the page's language — the build's English list if not given. */
  readonly feed = input<readonly StorySummary[] | undefined>(undefined);

  private readonly language = inject(TodayLanguage);
  /** The page's words, in its language. */
  protected readonly w = this.language.words;
  protected readonly fill = fill;
  protected readonly languages = storyLocales();

  protected readonly site = SITE;
  protected readonly moveLabel = moveLabel;
  protected readonly scoreText = scoreText;
  protected readonly playerText = playerText;
  protected readonly resultText = resultText;

  protected readonly english = computed(() => this.w().slug === 'en');
  protected readonly occasion = computed(() => this.language.occasion(this.story()));
  protected readonly date = computed(() => this.language.longDate(this.story().date));
  protected readonly section = computed(() =>
    this.story().event.section === 'Women' ? this.w().women : this.story().event.section,
  );
  protected readonly inMoves = computed(() => this.language.inMoves(this.pairs().length));
  protected readonly list = computed(() => listPath(this.w().slug));
  protected path(id: string, slug = this.w().slug): string {
    return storyPath(id, slug);
  }
  /** The Olympiad's report, for a story from it: where, and what the link says. */
  protected readonly report = computed(() => {
    const id = this.story().report;
    if (!id) return null;
    const r = reportWords(this.w().slug);
    return { path: reportPath(id, this.w().slug), label: `${r.section} — ${r.standings}` };
  });
  protected readonly paragraphs = computed(() => this.story().body.split(/\n\n+/));
  protected readonly pairs = computed(() => movePairs(this.story().moves));
  /**
   * The app's own address for this story, at the move the reader is on.
   * Opens Brass Pawn there when it is installed.
   */
  protected readonly appLink = computed(() => `brasspawn://today/${this.story().id}?ply=${this.ply()}`);

  /**
   * The App Clip's link for this story — the same form the game invitations
   * use. On an iPhone or iPad with the app it opens the app on this game; on
   * one without, the clip, which shows the game and keeps it in the shared
   * container, so the app installed from the clip opens on it. The only way a
   * game survives the trip through the App Store.
   */
  protected readonly clipLink = computed(
    () =>
      `https://appclip.apple.com/id?p=${SITE.clipBundleId}&s=${encodeURIComponent(this.story().id)}&ply=${this.ply()}`,
  );

  /**
   * Whether this is a device a clip can open on. Decided in the browser: the
   * prerendered page offers the App Store, which is right everywhere, and an
   * iPhone swaps in the link that goes further. iPadOS says it is a Mac, and
   * is told apart by having a touch screen.
   */
  protected readonly onPhone = signal(false);

  constructor() {
    // Back to the story's own move whenever the story changes — following a
    // link to the next one keeps the component and changes its input.
    effect(() => {
      const story = this.story();
      this.ply.set(story.key?.ply ?? story.moves.split(' ').length);
      this.moved.set(0);
      this.handoff.set(false);
    });
    afterNextRender(() => {
      const ua = navigator.userAgent;
      this.onPhone.set(/iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1));
    });
  }
  protected readonly flip = computed(() => this.story().result === '0-1');

  protected readonly sans = computed(() => this.story().moves.split(' '));

  /**
   * Where the replay stands, in half-moves. It opens on the move the story is
   * about, as the app's story screen does, and a story read live from the feed
   * — which has no positions worked out for it — stays there.
   */
  protected readonly ply = signal(0);

  protected readonly shown = computed(() => {
    const line = this.story().line;
    const ply = this.ply();
    if (line && line[ply]) return line[ply];
    return { fen: this.story().fen, last: this.story().last };
  });

  /** How many times the reader has moved the board on this story. */
  protected readonly moved = signal(0);
  /** The card that hands the game to the app, over the board. */
  protected readonly handoff = signal(false);
  protected readonly freeMoves = FREE_MOVES;

  /**
   * Move the board — a step, a jump to either end, a move picked from the
   * score. The first few are the site's; after that the board is the app's,
   * and the next one opens the card that takes the game there, at this move.
   */
  protected step(ply: number): void {
    const line = this.story().line;
    if (!line) return;
    const target = Math.max(0, Math.min(ply, line.length - 1));
    if (target === this.ply()) return;
    if (this.moved() >= FREE_MOVES) {
      this.handoff.set(true);
      return;
    }
    this.ply.set(target);
    this.moved.update((n) => n + 1);
  }

  /** The neighbours in the feed as this build has it, in the page's language, for reading on. */
  protected readonly neighbours = computed(() => {
    const feed = this.feed() ?? FEED;
    const i = feed.findIndex((s) => s.id === this.story().id);
    if (i < 0) return { newer: null, older: feed[0] ?? null };
    return { newer: i > 0 ? feed[i - 1] : null, older: feed[i + 1] ?? null };
  });
}
