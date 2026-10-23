export interface ChessGuide {
 slug:string; title:string;description:string;keyword:string;cluster:string;lede:string;
 sections:{heading:string;paragraphs:string[];bullets?:string[]}[];
 related:string[];sources:{label:string;url:string}[];appFit:string;
 exercise?:{fen:string;prompt:string;line:string;source:string;sourceUrl:string};
}
export interface GuideSummary{slug:string;title:string;description:string;keyword:string;cluster:string}
