import { ChangeDetectionStrategy, Component, computed, effect, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CurrentLocale } from '../../i18n/current';
import { LOCALES } from '../../i18n/locales';
import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { faqPage } from '../../core/schema';
import { GUIDE_COPY } from './content';

@Component({
  selector: 'bp-practice-guide',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
    <article class="page guide" [attr.lang]="locale().tag" [attr.dir]="locale().dir">
      <header><p class="mono">Brass Pawn · {{ locale().name }}</p>
        <h1>{{ words().title }}</h1><p class="intro">{{ words().intro }}</p>
        <a class="store" [href]="site.appStore">{{ words().cta }}</a>
      </header>
      <div class="body">
        <div>
          @for (section of words().sections; track section.q) {
            <section><h2>{{ section.q }}</h2><p>{{ section.a }}</p></section>
          }
          @for (item of words().faq; track item.q) {
            <section><h2>{{ item.q }}</h2><p>{{ item.a }}</p></section>
          }
          <p><a class="store" [href]="site.appStore">{{ words().cta }}</a></p>
        </div>
        @if (locale().slug !== 'bg') {
          <aside><img [src]="image()" [alt]="words().title" width="420" height="913" loading="lazy" /></aside>
        }
      </div>
      <nav class="languages" aria-label="Languages">
        @for (language of languages; track language.slug) {
          <a [routerLink]="path(language.slug)" [attr.hreflang]="language.tag" [attr.lang]="language.tag" [attr.dir]="language.dir">{{ language.name }}</a>
        }
      </nav>
    </article>
  `,
  styles: [`
    .guide { padding-block: clamp(3rem, 8vw, 7rem); max-width: 1120px; }
    header { max-width: 850px; } h1 { font-size: clamp(2rem, 5vw, 3.6rem); line-height: 1.12; }
    .intro { font-size: 1.25rem; line-height: 1.7; margin-block: 1.5rem; }
    .body { display: grid; grid-template-columns: minmax(0, 1fr) 260px; gap: 4rem; margin-block: 3rem; }
    section { margin-block-end: 2rem; } h2 { font-size: 1.35rem; line-height: 1.4; }
    section p { line-height: 1.8; margin-block-start: .8rem; }
    img { width: 100%; height: auto; border-radius: 1rem; }
    .store { display: inline-block; border: 1px solid currentColor; padding: .7rem 1rem; border-radius: .5rem; }
    .languages { display: flex; flex-wrap: wrap; gap: 1rem; border-block-start: 1px solid; padding-block-start: 2rem; }
    @media (max-width: 700px) { .body { grid-template-columns: 1fr; } aside { max-width: 260px; margin-inline: auto; } }
  `],
})
export class PracticeGuide {
  protected readonly locale = inject(CurrentLocale).locale;
  protected readonly site = SITE;
  protected readonly languages = LOCALES;
  protected readonly words = computed(() => GUIDE_COPY[this.locale().slug as keyof typeof GUIDE_COPY]);
  protected path(slug: string): string { return `${slug === 'en' ? '' : '/' + slug}/guides/chess-practice`; }
  protected readonly image = computed(() => `/media/shot/iphone/${this.locale().slug}/mistake-420.webp`);

  constructor() {
    const seo = inject(Seo);
    effect(() => {
      const locale = this.locale();
      const words = this.words();
      const path = this.path(locale.slug);
      seo.apply({
        path, locale, title: words.title, description: words.intro,
        translatedPath: '/guides/chess-practice', translatedIn: LOCALES.map(l => l.slug),
        updated: '2026-10-02',
        entities: [faqPage(path, locale.tag, words.faq)],
      });
    });
  }
}
