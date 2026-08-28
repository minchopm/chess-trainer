import { isDevMode } from '@angular/core';
import { Routes } from '@angular/router';

import { COPY } from './i18n/copy';
import { LOCALES } from './i18n/locales';
import { PAGES } from './i18n/pages';

/**
 * One page per language, generated from the locale table.
 *
 * Written out as thirty static paths rather than as a single `:lang` parameter
 * for two reasons. A parameter would have to be guarded by a matcher to stop it
 * swallowing `/training` and `/privacy`, and a matched route cannot be
 * enumerated — which means the prerenderer would have nothing to prerender and
 * every localised page would be served as an empty shell to a crawler that does
 * not wait for JavaScript.
 *
 * `data` and `resolve` both feed component inputs, so the page receives its
 * language and its words without reading the router at all.
 */
const localeRoutes: Routes = LOCALES.filter((locale) => locale.slug !== 'en').map((locale) => ({
  path: locale.slug,
  data: { locale },
  resolve: { copy: () => COPY[locale.slug]() },
  loadComponent: () => import('./pages/locale/locale').then((m) => m.LocalePage),
}));

/**
 * Every page is lazy, which matters here for one reason: the home page carries
 * three.js and the other seven do not.
 */
export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./pages/home/home').then((m) => m.Home),
  },

  // The hero's poster is rendered from the live scene rather than painted, so
  // it matches frame zero exactly — see `tools/poster.py`. Development only:
  // routed in production it would reach the sitemap as a render target rather
  // than a page, and a crawler would find a canvas with no words in it.
  //
  // `isDevMode()` is read at runtime, so the build still emits the component's
  // chunk — 828 bytes that production never asks for. Worth it: the poster has
  // to be reshot every time the pieces or the camera move, and a route that
  // only exists while one is editing a file is a route nobody reshoots from.
  ...(isDevMode()
    ? [
        {
          path: '__poster',
          loadComponent: () => import('./pages/poster/poster').then((m) => m.Poster),
        },
        {
          path: '__film',
          loadComponent: () => import('./pages/poster/film').then((m) => m.Film),
        },
      ]
    : []),
  {
    path: 'training',
    loadComponent: () => import('./pages/training/training').then((m) => m.Training),
  },
  {
    path: 'tactics',
    loadComponent: () => import('./pages/motifs/motifs').then((m) => m.Motifs),
  },
  {
    path: 'watch',
    loadComponent: () => import('./pages/watch/watch').then((m) => m.Watch),
  },
  {
    path: 'ratings',
    loadComponent: () => import('./pages/ratings/ratings').then((m) => m.Ratings),
  },
  {
    path: 'engine',
    loadComponent: () => import('./pages/engine/engine').then((m) => m.EnginePage),
  },
  {
    path: 'pricing',
    resolve: { pages: () => PAGES['en']() },
    loadComponent: () => import('./pages/pricing/pricing').then((m) => m.Pricing),
  },
  {
    path: 'support',
    resolve: { pages: () => PAGES['en']() },
    loadComponent: () => import('./pages/support/support').then((m) => m.Support),
  },
  {
    path: 'privacy',
    loadComponent: () => import('./pages/privacy/privacy').then((m) => m.Privacy),
  },
  {
    path: 'terms',
    loadComponent: () => import('./pages/terms/terms').then((m) => m.Terms),
  },
  {
    path: 'licences',
    loadComponent: () => import('./pages/licences/licences').then((m) => m.Licences),
  },
  // The thirty other languages. Before the catch-all, after everything whose
  // path is a word rather than a language.
  ...localeRoutes,

  // English is the site root, so /en is a second address for a page that
  // already has one.
  { path: 'en', redirectTo: '', pathMatch: 'full' },

  // Apple's forms and half the internet will write these instead.
  { path: 'privacy-policy', redirectTo: 'privacy', pathMatch: 'full' },
  { path: 'terms-of-service', redirectTo: 'terms', pathMatch: 'full' },
  { path: 'eula', redirectTo: 'terms', pathMatch: 'full' },
  { path: 'licenses', redirectTo: 'licences', pathMatch: 'full' },
  { path: 'motifs', redirectTo: 'tactics', pathMatch: 'full' },
  { path: 'glossary', redirectTo: 'tactics', pathMatch: 'full' },
  { path: 'rating', redirectTo: 'ratings', pathMatch: 'full' },
  { path: 'games', redirectTo: 'watch', pathMatch: 'full' },
  { path: 'library', redirectTo: 'watch', pathMatch: 'full' },
  // Prerendered so a static host has a real 404.html to serve.
  {
    path: '404',
    loadComponent: () => import('./pages/not-found/not-found').then((m) => m.NotFound),
  },
  {
    path: '**',
    loadComponent: () => import('./pages/not-found/not-found').then((m) => m.NotFound),
  },
];
