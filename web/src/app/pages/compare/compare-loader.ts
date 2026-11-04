import { COMPARE_INDEX } from './compare-index';
import type { ComparePageContent, ComparePageData } from './types';

export async function loadComparePage(slug: string): Promise<ComparePageData | undefined> {
  const index = COMPARE_INDEX.findIndex((item) => item.slug === slug);
  if (index < 0) return undefined;

  let batch: readonly ComparePageContent[];
  if (index < 10) {
    batch = (await import('./data/batch-1')).COMPARE_BATCH_1;
  } else if (index < 20) {
    batch = (await import('./data/batch-2')).COMPARE_BATCH_2;
  } else {
    batch = (await import('./data/batch-3')).COMPARE_BATCH_3;
  }

  const content = batch.find((entry) => entry.slug === slug);
  if (!content) return undefined;

  return {
    ...COMPARE_INDEX[index],
    ...content,
  };
}
