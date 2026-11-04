export type CompareCategoryId =
  | 'platforms'
  | 'trainers'
  | 'engines-databases'
  | 'casual-kids'
  | 'workflows';

export interface CompareCategory {
  readonly id: CompareCategoryId;
  readonly name: string;
  readonly summary: string;
}

export interface CompareTable {
  readonly id: string;
  readonly heading: string;
  readonly caption: string;
  readonly intro?: string;
  readonly headers: readonly string[];
  readonly rows: readonly (readonly string[])[];
}

export interface CompareSection {
  readonly heading: string;
  readonly paragraphs: readonly string[];
  readonly bullets?: readonly string[];
}

export interface CompareFaq {
  readonly q: string;
  readonly a: string;
}

export interface CompareSummary {
  readonly slug: string;
  readonly title: string;
  readonly h1: string;
  readonly seoTitle: string;
  readonly description: string;
  readonly category: CompareCategoryId;
  readonly competitor: string;
  readonly brassPawnBestFor: string;
  readonly alternativeBestFor: string;
  readonly pricingModel: string;
  readonly offlineSupport: string;
}

export interface ComparePageContent {
  readonly slug: string;
  readonly tldr: string;
  readonly tables: readonly [CompareTable, CompareTable, CompareTable];
  readonly sections: readonly CompareSection[];
  readonly honestTradeoffs: readonly string[];
  readonly faqs: readonly CompareFaq[];
  readonly relatedCompare: readonly string[];
  readonly relatedGuides: readonly { readonly slug: string; readonly title: string }[];
}

export type ComparePageData = CompareSummary & ComparePageContent;
