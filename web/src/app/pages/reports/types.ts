/**
 * One of the Olympiad's reports, as the collector writes it in a language
 * (scripts/feed/reports.mjs): a round's, or the event's. Everything in it is
 * counted from the games of the official broadcast.
 */

export interface ReportPlayer {
  readonly name: string;
  readonly title: string | null;
  readonly elo: number | null;
  readonly team: string | null;
  /** The team's name in the report's language. */
  readonly teamName?: string | null;
}

export interface ReportMatch {
  readonly home: string;
  readonly away: string;
  readonly homeName: string;
  readonly awayName: string;
  /** Game points, home first. */
  readonly score: readonly [number, number];
}

export interface ReportRow {
  readonly team: string;
  readonly name: string;
  readonly mp: number;
  readonly gp: number;
  readonly played: number;
}

export interface ReportUpset {
  readonly winner: ReportPlayer;
  readonly loser: ReportPlayer;
  readonly gap: number;
  readonly url: string | null;
}

export interface ReportCounts {
  readonly games: number;
  readonly white: number;
  readonly black: number;
  readonly draws: number;
}

export interface ReportSection {
  /** 'Open', 'Women'. */
  readonly key: string;
  /** The section's name in the report's language. */
  readonly name: string;
  readonly top: readonly ReportMatch[];
  readonly table: readonly ReportRow[];
  readonly numbers: ReportCounts;
  readonly upsets: readonly ReportUpset[];
}

export interface ReportGame {
  readonly white: ReportPlayer;
  readonly black: ReportPlayer;
  readonly result: string;
  readonly moves: number;
  readonly opening: string | null;
  readonly url: string | null;
}

export interface Report {
  readonly id: string;
  readonly kind: 'round' | 'event';
  readonly lang: string;
  readonly headline: string;
  readonly lede: string;
  /** "Samarkand, Uzbekistan", the country in the report's language. */
  readonly where?: string | null;
  readonly date: string | null;
  readonly round: number;
  readonly rounds: number;
  readonly played: number;
  readonly event: {
    readonly name: string;
    readonly location: string | null;
    readonly dates: readonly [string, string] | null;
    readonly format: string | null;
    readonly tc: string | null;
    readonly website: string | null;
    readonly standings: string | null;
    readonly broadcast: string;
  };
  readonly sections: readonly ReportSection[];
  /** The event's, over every round so far. */
  readonly numbers?: ReportCounts & {
    readonly openings: readonly { readonly name: string; readonly count: number }[];
    readonly longest: ReportGame | null;
  };
  /** The event's: every round's report, newest first. */
  readonly reports?: readonly { readonly id: string; readonly round: number; readonly date: string | null }[];
  /** The feed's stories from the round, or the event's latest — their headlines in the report's language. */
  readonly stories: readonly { readonly id: string; readonly headline: string }[];
}
