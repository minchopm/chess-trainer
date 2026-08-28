import type { Pages } from './types';

/**
 * The inner pages in English, lifted verbatim out of the templates.
 *
 * Introducing this layer changed where the words live and not one word itself,
 * so the English pages read today exactly as they read before. Every other
 * language is a translation of this file.
 */
export const pages: Pages = {
  support: {
    head: {
      slug: 'Support',
      title: 'Ask a person',
      lede: 'There is no ticket system, no chatbot and no help centre with 400 articles in it. There is an email address and an issue tracker, and both reach the person who wrote the app.',
    },
    meta: {
      title: 'Support',
      description:
        'How to reach a human about Brass Pawn, what to include when reporting a wrong puzzle, and the questions that get asked most.',
    },
    email: {
      slug: 'Email',
      body: 'For anything: a bug, a wrong puzzle, a question about a purchase, or a disagreement with an evaluation. Write in English or Bulgarian.',
    },
    tracker: {
      slug: 'Issue tracker',
      name: 'GitHub issues',
      body: 'For anything you would rather were public — and for anything you want other people to be able to find later, which is most bug reports.',
    },
    report: {
      slug: 'If a puzzle is wrong',
      title: 'Send four things and it can be checked in a minute.',
      checklist: [
        'The FEN shown on the puzzle screen — tap and hold to copy it.',
        'The move you played, and the move the app said was right.',
        'Which mode you were in.',
        'The app version, from the About screen.',
      ],
      caveat:
        'Puzzles do occasionally disagree with a deeper search, and the disagreements cluster on long, quiet, highly rated positions whose point lies deeper than the verification searched. That is a limit of the check rather than a fault in the puzzle — but it is worth knowing which ones, and the only way to know is if you say.',
    },
    faq: { slug: 'Questions', title: 'Asked often enough to write down.' },
    more: {
      ratings: 'What a rating measures',
      tactics: 'The motifs',
      privacy: 'Privacy Policy',
      terms: 'Terms of Service',
      licences: 'Licences',
    },
  },
  pricing: {
    head: {
      slug: 'What it costs',
      title: 'Playing is free. The training is sold.',
      lede: 'Chess against the engine and chess against a person, unlimited, with no advertising anywhere in the app — that is free and it stays free. What is sold is the library, the drills, the exercises and the run.',
    },
    meta: {
      title: 'Pricing',
      description:
        'Playing is free and unlimited — the engine, a real opponent, and all 900 games. Pro lifts the five-a-day training limit: $3.99 a month or $49.99 once.',
    },
    free: {
      name: 'Free',
      note: 'No account. Nothing to sign up for.',
      items: [
        'Unlimited play against the engine, 1400 to full strength',
        'Unlimited online games over Game Center',
        'Move-by-move coaching in every game you play',
        'Five tactics puzzles a day',
        'Five Rush runs a day',
        'Five each: positional, endgame, Guess the Elo',
        'Ratings, streaks and spaced repetition, in full',
      ],
    },
    monthly: {
      flag: 'Brass Pawn Pro',
      name: 'Monthly',
      per: 'per month',
      note: 'Cancel in your Apple Account settings, any time.',
      items: [
        'Every daily limit removed',
        'All {tactics} tactics puzzles',
        'All {positional} positional exercises',
        'All {endgames} endgame drills',
        'All {games} games to judge',
        'Unlimited Rush',
        'Everything in Free, unchanged',
      ],
    },
    lifetime: {
      name: 'One-off unlock',
      once: 'once',
      note: 'A non-consumable purchase. It does not renew.',
      items: [
        'Exactly the same as Pro monthly',
        'No renewal, no expiry, no reminder emails',
        'Restores on your other devices',
        'For people who would rather decide once',
      ],
    },
    table: {
      slug: 'The whole allowance',
      title: 'What the free tier actually gives you.',
      activity: 'Activity',
      freeCol: 'Free',
      proCol: 'Pro',
      unlimited: 'Unlimited',
      fiveADay: '5 a day',
      none: 'None',
      rows: [
        'Play against the engine',
        'Online games over Game Center',
        'Watch — the 900-game library',
        'Tactics puzzles',
        'Rush runs',
        'Positional exercises',
        'Endgame drills',
        'Guess the Elo',
        'Advertising',
      ],
      reset:
        'Daily allowances reset at nine in the morning, local time — not midnight, so an evening session is not cut in half by a date change.',
    },
    why: {
      slug: 'Why it is shaped this way',
      title: 'Three decisions, and the reason for each.',
      reasons: [
        {
          title: 'Metered, not locked',
          body: [
            'Nobody pays for a trainer they have not used, and a mode that refuses to open teaches nothing about what is behind it. So every mode opens, every day, and you get far enough in to feel the loop and watch the rating move.',
            'The paywall is never shown on launch. When the day’s allowance is spent the screen says so, and only a deliberate tap opens the purchase sheet.',
          ],
        },
        {
          title: 'Two prices, not three',
          body: [
            'There is no annual plan in between, because a third price is a third decision to make at the exact moment somebody wants to solve a puzzle. Monthly if you are not sure. One-off if you are.',
          ],
        },
        {
          title: 'Playing is never sold',
          body: [
            'Chess against the engine and chess against a person cost nothing to run and are the reason the app exists. Selling them would make this a chess app with a toll booth rather than a trainer.',
            'And there is no advertising — partly taste, partly licence. The app links two copyleft engines, Stockfish under the GPLv3 and Reckless under the AGPLv3, and a proprietary ad SDK in the same binary would make the whole thing undistributable. {link}',
          ],
        },
      ],
      licenceLink: 'The licence page explains it properly.',
    },
    answers: {
      slug: 'Buying, cancelling, refunds',
      title: 'The awkward questions, answered here rather than in an email.',
      items: [
        {
          q: 'How do I cancel?',
          a: 'Settings → your name → Subscriptions → Brass Pawn. We cannot cancel it for you, because the subscription is between you and Apple and we never had it. Cancelling stops future renewals and does not shorten the period you have paid for.',
        },
        {
          q: 'How do I get a refund?',
          a: 'Through Apple, at {link}. We cannot issue refunds for App Store purchases. If something is broken, write to us — we would rather fix it.',
        },
        {
          q: 'I bought the unlock and got a new phone.',
          a: 'Sign in with the same Apple Account and tap Restore purchases on the paywall screen. The app asks StoreKit what you own; nothing is stored on a server of ours because there is no server of ours.',
        },
        {
          q: 'Does Pro change my rating or unlock “better” puzzles?',
          a: 'No. The rating system is identical and every puzzle in the library is reachable on a free account — five a day at a time. Pro removes the counter, not a curtain.',
        },
        {
          q: 'Will the free allowance shrink later?',
          a: 'It may change in either direction as the library grows. Unlimited play against the engine and against a person will not become a paid feature; that is written into the {link} rather than only promised here.',
        },
      ],
      termsLink: 'Terms',
      more: 'More questions, and how to reach a human →',
    },
  },
};
