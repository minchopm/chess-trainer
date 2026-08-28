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
};
