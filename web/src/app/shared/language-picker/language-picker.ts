import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { CurrentLocale } from '../../i18n/current';
import { LOCALES, type Locale, localePath } from '../../i18n/locales';

/**
 * Thirty-one languages, as thirty-one links.
 *
 * A `<select>` would be smaller and would be the wrong element: a language
 * chooser is navigation, and navigation that only exists once a script has run
 * is navigation a crawler never sees. These are anchors inside a `<details>`,
 * so they are followed, indexed, and openable with the keyboard before any of
 * this component's own code has loaded.
 *
 * Each language is written in itself. Somebody looking for Greek is looking for
 * Ελληνικά — the word "Greek" is only useful to a person who already reads the
 * language the page is in, which is the one thing this control cannot assume.
 */
@Component({
  selector: 'bp-language-picker',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
    <details class="picker" [attr.open]="open() ? '' : null" (toggle)="onToggle($event)">
      <summary>
        <svg viewBox="0 0 16 16" width="13" height="13" aria-hidden="true">
          <circle cx="8" cy="8" r="6.2" fill="none" stroke="currentColor" stroke-width="1.2" />
          <path
            d="M1.8 8h12.4M8 1.8c3.4 3.6 3.4 8.8 0 12.4M8 1.8c-3.4 3.6-3.4 8.8 0 12.4"
            fill="none"
            stroke="currentColor"
            stroke-width="1.2"
          />
        </svg>
        <span class="current">{{ current().name }}</span>
        <span class="visually-hidden">— {{ label }}</span>
      </summary>

      <div class="sheet">
        <ul>
          @for (locale of locales; track locale.tag) {
            <li>
              <a
                [routerLink]="path(locale)"
                [attr.hreflang]="locale.tag"
                [attr.lang]="locale.tag"
                [attr.dir]="locale.dir"
                [attr.aria-current]="locale.tag === current().tag ? 'true' : null"
                [title]="locale.english"
                (click)="open.set(false)"
              >
                {{ locale.name }}
              </a>
            </li>
          }
        </ul>
      </div>
    </details>
  `,
  styleUrl: './language-picker.scss',
})
export class LanguagePicker {
  protected readonly locales = LOCALES;
  protected readonly label = 'Language';
  protected readonly open = signal(false);

  /** Which language the visitor is reading. See CurrentLocale for why not the router. */
  protected readonly current = inject(CurrentLocale).locale;

  protected path(locale: Locale): string {
    return localePath(locale);
  }

  protected onToggle(event: Event): void {
    this.open.set((event.target as HTMLDetailsElement).open);
  }
}
