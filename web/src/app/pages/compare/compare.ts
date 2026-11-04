import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { faqPage } from '../../core/schema';
import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { MoreApps } from '../../shared/more-apps/more-apps';
import {
  COMPARE_CATEGORIES,
  COMPARE_HUB_ARCHETYPE_TABLE,
  COMPARE_HUB_FAQS,
  COMPARE_HUB_META,
  COMPARE_INDEX,
} from './compare-index';
import type { CompareCategoryId, ComparePageData } from './types';

@Component({
  selector: 'bp-compare-hub',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, MoreApps],
  styleUrl: './compare.scss',
  template: `
    <section class="page compare">
      <header class="compare-head">
        <nav class="compare-crumbs mono" aria-label="Breadcrumb">
          <a routerLink="/">Home</a>
          <span aria-hidden="true">/</span>
          <span>Comparisons</span>
        </nav>
        <h1>{{ meta.h1 }}</h1>
        <aside class="compare-tldr" aria-label="TL;DR summary">
          <p class="mono compare-kicker">Answer first · TL;DR</p>
          <p>{{ meta.tldr }}</p>
        </aside>
        <p class="compare-byline mono">
          30 side-by-side comparisons · Verified against AGPLv3 repository facts · Updated 4 November 2026
        </p>
      </header>

      <section class="compare-section" id="archetypes">
        <h2>{{ archetypes.heading }}</h2>
        @if (archetypes.intro) {
          <p class="compare-prose">{{ archetypes.intro }}</p>
        }
        <div class="compare-table-wrap">
          <table class="compare-table">
            <caption>{{ archetypes.caption }}</caption>
            <thead>
              <tr>
                @for (header of archetypes.headers; track header) {
                  <th scope="col">{{ header }}</th>
                }
              </tr>
            </thead>
            <tbody>
              @for (row of archetypes.rows; track $index) {
                <tr>
                  @for (cell of row; track $index; let col = $index) {
                    @if (col === 0) {
                      <th scope="row">{{ cell }}</th>
                    } @else {
                      <td>{{ cell }}</td>
                    }
                  }
                </tr>
              }
            </tbody>
          </table>
        </div>
      </section>

      <section class="compare-section" id="browse">
        <h2>Browse comparisons by category</h2>
        <div class="compare-controls">
          <label class="compare-search">
            Filter by app, engine, platform or workflow
            <input
              type="search"
              placeholder="Stockfish, Lichess, Chessable, offline, Mac, kids…"
              [value]="query()"
              (input)="query.set($any($event.target).value)"
            />
          </label>
          <nav class="compare-pills" aria-label="Comparison categories">
            <button type="button" (click)="category.set('')" [attr.aria-pressed]="!category()">
              All ({{ all.length }})
            </button>
            @for (cat of categories; track cat.id) {
              <button
                type="button"
                (click)="category.set(cat.id)"
                [attr.aria-pressed]="category() === cat.id"
              >
                {{ cat.name }}
              </button>
            }
          </nav>
        </div>

        <p class="mono compare-count" aria-live="polite">{{ filtered().length }} comparisons shown</p>

        <div class="compare-grid">
          @for (item of filtered(); track item.slug) {
            <article class="compare-card">
              <p class="mono compare-kicker">{{ categoryLabel(item.category) }}</p>
              <h3><a [routerLink]="'/compare/' + item.slug">{{ item.title }}</a></h3>
              <p>{{ item.description }}</p>
              <p class="compare-card-meta mono">{{ item.pricingModel }}</p>
            </article>
          }
        </div>

        @if (!filtered().length) {
          <p class="compare-prose">No matching comparisons. Reset the filter to inspect all 30 guides.</p>
          <button class="button" type="button" (click)="query.set(''); category.set('')">
            Reset filters
          </button>
        }
      </section>

      <section class="compare-section" id="directory">
        <h2>Complete 30-comparison matrix</h2>
        <p class="compare-prose">
          Every comparison page includes three structured specification tables covering engine
          execution, training datasets, offline availability and multi-year pricing.
        </p>
        <div class="compare-table-wrap">
          <table class="compare-table">
            <caption>Directory of all 30 Brass Pawn side-by-side comparisons and workflow guides</caption>
            <thead>
              <tr>
                <th scope="col">Comparison</th>
                <th scope="col">Category</th>
                <th scope="col">Choose Brass Pawn for</th>
                <th scope="col">Choose the alternative for</th>
                <th scope="col">Pricing contrast</th>
                <th scope="col">Offline support</th>
              </tr>
            </thead>
            <tbody>
              @for (item of all; track item.slug) {
                <tr>
                  <th scope="row">
                    <a [routerLink]="'/compare/' + item.slug">{{ item.title }}</a>
                  </th>
                  <td>{{ categoryLabel(item.category) }}</td>
                  <td>{{ item.brassPawnBestFor }}</td>
                  <td>{{ item.alternativeBestFor }}</td>
                  <td>{{ item.pricingModel }}</td>
                  <td>{{ item.offlineSupport }}</td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </section>

      <section class="compare-section" id="faq">
        <h2>Frequently asked questions</h2>
        <dl class="compare-faq">
          @for (item of faqs; track item.q) {
            <div class="compare-faq-item">
              <dt>{{ item.q }}</dt>
              <dd>{{ item.a }}</dd>
            </div>
          }
        </dl>
      </section>

      <bp-more-apps [inline]="true" />
    </section>
  `,
})
export class CompareHubPage {
  protected readonly meta = COMPARE_HUB_META;
  protected readonly categories = COMPARE_CATEGORIES;
  protected readonly archetypes = COMPARE_HUB_ARCHETYPE_TABLE;
  protected readonly faqs = COMPARE_HUB_FAQS;
  protected readonly all = COMPARE_INDEX;

  protected readonly query = signal('');
  protected readonly category = signal<CompareCategoryId | ''>('');

  protected readonly filtered = computed(() => {
    const cat = this.category();
    const q = this.query().trim().toLowerCase();
    return COMPARE_INDEX.filter(
      (item) =>
        (!cat || item.category === cat) &&
        (!q ||
          `${item.title} ${item.competitor} ${item.description} ${item.brassPawnBestFor} ${item.alternativeBestFor}`
            .toLowerCase()
            .includes(q)),
    );
  });

  protected categoryLabel(id: CompareCategoryId): string {
    return COMPARE_CATEGORIES.find((c) => c.id === id)?.name ?? 'Comparison';
  }

  constructor() {
    inject(Seo).apply({
      path: COMPARE_HUB_META.path,
      title: COMPARE_HUB_META.title,
      seoTitle: COMPARE_HUB_META.seoTitle,
      description: COMPARE_HUB_META.description,
      updated: COMPARE_HUB_META.updated,
      entities: [faqPage(COMPARE_HUB_META.path, 'en-US', COMPARE_HUB_FAQS)],
    });
  }
}

@Component({
  selector: 'bp-compare-detail',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, MoreApps],
  styleUrl: './compare.scss',
  template: `
    <article class="page compare">
      <header class="compare-head">
        <nav class="compare-crumbs mono" aria-label="Breadcrumb">
          <a routerLink="/">Home</a>
          <span aria-hidden="true">/</span>
          <a routerLink="/compare">Comparisons</a>
          <span aria-hidden="true">/</span>
          <span>{{ categoryLabel() }}</span>
        </nav>
        <h1>{{ page.h1 }}</h1>
        <aside class="compare-tldr" aria-label="TL;DR summary">
          <p class="mono compare-kicker">Answer first · TL;DR</p>
          <p>{{ page.tldr }}</p>
        </aside>
        <p class="compare-byline mono">
          Brass Pawn editorial team · Verified against AGPLv3 repository facts · Updated 4 November 2026
        </p>
      </header>

      <div class="compare-layout">
        <div class="compare-main">
          @for (table of page.tables; track table.id) {
            <section class="compare-section" [id]="'table-' + table.id">
              <h2>{{ table.heading }}</h2>
              @if (table.intro) {
                <p class="compare-prose">{{ table.intro }}</p>
              }
              <div class="compare-table-wrap">
                <table class="compare-table">
                  <caption>{{ table.caption }}</caption>
                  <thead>
                    <tr>
                      @for (header of table.headers; track header) {
                        <th scope="col">{{ header }}</th>
                      }
                    </tr>
                  </thead>
                  <tbody>
                    @for (row of table.rows; track $index) {
                      <tr>
                        @for (cell of row; track $index; let col = $index) {
                          @if (col === 0) {
                            <th scope="row">{{ cell }}</th>
                          } @else {
                            <td>{{ cell }}</td>
                          }
                        }
                      </tr>
                    }
                  </tbody>
                </table>
              </div>
            </section>
          }

          @for (section of page.sections; track section.heading; let i = $index) {
            <section class="compare-section compare-prose" [id]="'section-' + i">
              <h2>{{ section.heading }}</h2>
              @for (para of section.paragraphs; track para) {
                <p>{{ para }}</p>
              }
              @if (section.bullets?.length) {
                <ul>
                  @for (bullet of section.bullets; track bullet) {
                    <li>{{ bullet }}</li>
                  }
                </ul>
              }
            </section>
          }

          <section class="compare-section compare-tradeoffs compare-prose" id="tradeoffs">
            <p class="mono compare-kicker">Honest boundaries</p>
            <h2>When {{ page.competitor }} is the better fit</h2>
            <ul>
              @for (point of page.honestTradeoffs; track point) {
                <li>{{ point }}</li>
              }
            </ul>
          </section>

          <section class="compare-section" id="faq">
            <h2>Frequently asked questions</h2>
            <dl class="compare-faq">
              @for (faq of page.faqs; track faq.q) {
                <div class="compare-faq-item">
                  <dt>{{ faq.q }}</dt>
                  <dd>{{ faq.a }}</dd>
                </div>
              }
            </dl>
          </section>

          <section class="compare-section compare-cta compare-prose" id="try">
            <p class="mono compare-kicker">Native on iPhone, iPad &amp; Mac</p>
            <h2>Practise offline with Stockfish 18 and Reckless 0.10</h2>
            <p>
              Play unlimited coached games against the engine or over Game Center for free, with five
              daily exercises in Tactics, Rush, Positional judgement, Endgames and Guess the Elo — and
              zero advertising under the GNU AGPLv3.
            </p>
            <div class="compare-actions">
              <a class="button button--solid" [href]="site.appStore" rel="noopener">
                Brass Pawn on the App Store ↗
              </a>
              <a routerLink="/training">Explore all 8 modes</a>
              <a routerLink="/engine">Engines &amp; grading</a>
              <a routerLink="/pricing">Free vs Pro pricing</a>
            </div>
          </section>

          <section class="compare-section compare-prose" id="related">
            <h2>Related comparisons and training guides</h2>
            <p>Compare adjacent chess tools or put these training habits to work on the board:</p>
            <ul>
              @for (rel of relatedComparisons(); track rel.slug) {
                <li>
                  <a [routerLink]="'/compare/' + rel.slug">{{ rel.title }}</a> — {{ rel.pricingModel }}
                </li>
              }
              @for (guide of page.relatedGuides; track guide.slug) {
                <li>
                  <a [routerLink]="'/articles/' + guide.slug">{{ guide.title }}</a> (Training notebook)
                </li>
              }
            </ul>
          </section>

          <nav class="compare-prevnext" aria-label="Adjacent comparisons">
            @if (previous(); as prev) {
              <a [routerLink]="'/compare/' + prev.slug">← {{ prev.title }}</a>
            }
            @if (next(); as nxt) {
              <a [routerLink]="'/compare/' + nxt.slug">{{ nxt.title }} →</a>
            }
          </nav>

          <bp-more-apps [inline]="true" />
        </div>

        <aside class="compare-toc" aria-label="On this page">
          <h2>On this page</h2>
          <ol>
            @for (table of page.tables; track table.id) {
              <li>
                <a [routerLink]="'/compare/' + page.slug" [fragment]="'table-' + table.id">
                  {{ table.heading }}
                </a>
              </li>
            }
            @for (section of page.sections; track section.heading; let i = $index) {
              <li>
                <a [routerLink]="'/compare/' + page.slug" [fragment]="'section-' + i">
                  {{ section.heading }}
                </a>
              </li>
            }
            <li>
              <a [routerLink]="'/compare/' + page.slug" fragment="tradeoffs">
                When {{ page.competitor }} fits better
              </a>
            </li>
            <li>
              <a [routerLink]="'/compare/' + page.slug" fragment="faq">FAQ</a>
            </li>
          </ol>
          <hr />
          <a routerLink="/compare">All 30 chess comparisons →</a>
        </aside>
      </div>
    </article>
  `,
})
export class CompareDetailPage {
  protected readonly page = inject(ActivatedRoute).snapshot.data['page'] as ComparePageData;
  protected readonly site = SITE;

  protected categoryLabel(): string {
    return COMPARE_CATEGORIES.find((c) => c.id === this.page.category)?.name ?? 'Comparisons';
  }

  protected relatedComparisons() {
    return COMPARE_INDEX.filter((item) => this.page.relatedCompare.includes(item.slug));
  }

  protected previous() {
    const idx = COMPARE_INDEX.findIndex((item) => item.slug === this.page.slug);
    return idx > 0 ? COMPARE_INDEX[idx - 1] : undefined;
  }

  protected next() {
    const idx = COMPARE_INDEX.findIndex((item) => item.slug === this.page.slug);
    return idx >= 0 && idx < COMPARE_INDEX.length - 1 ? COMPARE_INDEX[idx + 1] : undefined;
  }

  constructor() {
    const p = this.page;
    const path = `/compare/${p.slug}`;
    inject(Seo).apply({
      path,
      title: p.title,
      seoTitle: p.seoTitle,
      description: p.description,
      published: '2026-11-04',
      updated: '2026-11-04',
      crumbs: [{ label: 'Comparisons', path: '/compare' }],
      entities: [
        faqPage(path, 'en-US', p.faqs),
        {
          '@type': 'Article',
          headline: p.h1,
          description: p.description,
          datePublished: '2026-11-04',
          dateModified: '2026-11-04',
          author: {
            '@type': 'Organization',
            name: 'Brass Pawn editorial team',
            url: 'https://brasspawn.com/',
          },
          publisher: { '@id': 'https://brasspawn.com/#organization' },
          mainEntityOfPage: `https://brasspawn.com${path}`,
        },
      ],
    });
  }
}
