/**
 * Canadian English: the same words.
 *
 * copy/en-ca.ts is byte-identical to copy/en.ts — the App Store carries the two
 * as separate localisations but the text was never made to differ, and inventing
 * differences to justify a second file would be worse than admitting there are
 * none. Re-exported rather than copied, so the two can never drift apart by
 * accident; if Canadian English ever needs its own sentence, this file is where
 * it stops being a re-export.
 *
 * The duplicate content is what hreflang is for: en and en-CA name each other as
 * alternates, which is the case that markup exists to describe.
 */
export { pages } from './en';
