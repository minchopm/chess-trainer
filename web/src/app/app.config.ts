import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import {
  provideRouter,
  withComponentInputBinding,
  withInMemoryScrolling,
  withRouterConfig,
} from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      // 'enabled' rather than 'top': a new page opens at the top, and going
      // back returns you to where you were, which on a page four screens tall
      // is the difference between a back button and a punishment.
      withInMemoryScrolling({ scrollPositionRestoration: 'enabled', anchorScrolling: 'enabled' }),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
      // The localised pages take their language and their words as inputs; this
      // is what lets the router hand them over instead of the component
      // reaching into the route to fetch them.
      withComponentInputBinding(),
    ),
    provideClientHydration(withEventReplay()),
  ],
};
