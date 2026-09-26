import { Injectable, computed, inject } from '@angular/core';

import { CurrentLocale } from '../../../i18n/current';
import { DEFAULT_LOCALE, type Locale, LOCALES } from '../../../i18n/locales';
import type { StorySummary } from '../feed/types';
import { APP_WORDS } from './app-words';
import { type Plural, siteWords, type SiteWords } from './site-words';

export { feedFolder, listPath, reportPath, STORY_SLUGS, storyPath, storySlug } from './slugs';
import { STORY_SLUGS, storySlug } from './slugs';

/** The app has no Bulgarian yet; the site does, so its words for the app's labels are here. */
const BG_APP: Record<string, string> = {
  white: 'Бели', black: 'Черни', today: 'Днес', result: 'Резултат', event: 'Турнир',
  keyMove: 'Ключов ход', enginesChoice: 'Изборът на енджина', replay: 'Преглед', tryIt: 'Опитайте сами',
  after: 'След {0}', stockfish: 'Stockfish {0} → {1}', round: '{0}. кръг',
  empty: 'Още няма истории. Появяват се след всеки кръг на голям турнир.',
  squares: 'Полета', pieces: 'Фигури', lightSide: 'Светла страна', set: 'Комплект',
  banded: 'С месингови пръстени', plain: 'Чимшир и абанос', parlour: 'Чимшир и орех',
  wood: 'Орех', lamplight: 'Лампа', amber: 'Кехлибар', forest: 'Гора', ocean: 'Океан', ivory: 'Порцелан',
  rose: 'Розова вода', sand: 'Пясък', slate: 'Шисти',
  ebony: 'Слонова кост и абанос', emerald: 'Слонова кост и смарагд', sapphire: 'Слонова кост и сапфир',
  claret: 'Слонова кост и бордо', glyph: 'Класически',
  snow: 'Сняг', chalk: 'Тебешир', boxwood: 'Чимшир', frost: 'Скреж', mist: 'Мъгла',
};

export interface TodayWords extends SiteWords {
  /** The words the app has for the same things — White, the result, the key move, the sets. */
  readonly app: Record<string, string>;
  readonly locale: Locale;
  /** The slug the story pages are in: the reader's, or the one they read. */
  readonly slug: string;
}

/** `{0}`, `{1}` filled in. */
export function fill(template: string, ...values: (string | number)[]): string {
  return template.replace(/\{(\d)\}/g, (_, i) => String(values[Number(i)] ?? ''));
}

/** A count in a language's own plural form. */
export function plural(form: Plural, n: number, tag: string): string {
  if (typeof form === 'string') return fill(form, n);
  const category = new Intl.PluralRules(tag).select(n);
  return fill(form[category] ?? form.other ?? Object.values(form)[0] ?? '', n);
}

export function wordsFor(locale: Locale): TodayWords {
  const slug = storySlug(locale.slug);
  const base = locale.slug === 'en-ca' || locale.slug === 'fr-ca' ? locale.slug : slug;
  const app = locale.slug === 'bg' ? BG_APP : (APP_WORDS[base] ?? APP_WORDS[slug] ?? APP_WORDS['en']);
  return { ...siteWords(locale.slug), app, locale, slug };
}

/**
 * The Today pages' words, for the language the page is in — which the
 * address says (CurrentLocale), so a story at /de/today/… is German from the
 * first frame, in the prerenderer and the browser alike.
 */
@Injectable({ providedIn: 'root' })
export class TodayLanguage {
  private readonly current = inject(CurrentLocale);
  readonly words = computed(() => wordsFor(this.current.locale()));

  /** "Olympiad · Open · Round 9", in the reader's language. */
  occasion(story: Pick<StorySummary, 'event'>): string {
    const w = this.words();
    const section = story.event.section === 'Women' ? w.women : story.event.section;
    return [story.event.short, section, story.event.round ? fill(w.app['round'], story.event.round) : null]
      .filter(Boolean)
      .join(' · ');
  }

  /** "26 September 2026", in the reader's language. */
  longDate(iso: string): string {
    return new Date(`${iso}T12:00:00Z`).toLocaleDateString(this.words().locale.tag, {
      day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC',
    });
  }

  inMoves(n: number): string {
    return plural(this.words().inMoves, n, this.words().locale.tag);
  }
}

/** The site locales a story page exists in, English first — for hreflang and the language row. */
export function storyLocales(): Locale[] {
  return [DEFAULT_LOCALE, ...LOCALES.filter((l) => STORY_SLUGS.includes(l.slug))];
}
