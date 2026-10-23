import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Seo } from '../../core/seo';
import { SITE } from '../../core/site';
import { GUIDE_INDEX } from './guide-index';
import { ChessGuide } from './types';
export const TOPICS=[
 {id:'study-plans',name:'Study plans'},{id:'game-review',name:'Review your games'},{id:'app-choice',name:'Apps and practice'},
 {id:'tactics',name:'Tactics'},{id:'calculation',name:'Calculation'},{id:'positional-play',name:'Positional play'},
 {id:'endgames',name:'Endgames'},{id:'opening-principles',name:'Opening principles'},{id:'fair-play',name:'Rules and fair play'},
];
@Component({selector:'bp-articles',changeDetection:ChangeDetectionStrategy.OnPush,imports:[RouterLink],template:`
<section class="page academy"><header><p class="mono academy-kicker">The Brass Pawn training notebook</p><h1>Know what to practise next.</h1><p class="academy-lede">A hundred practical guides to thinking at the board, reviewing mistakes and building a useful routine. Choose a problem to work on, then check what you learned.</p><a class="academy-link" routerLink="/guides/chess-practice">New to Brass Pawn? Start with the app guide →</a></header>
<label class="academy-search">Find a training topic<input type="search" placeholder="Forks, endgames, game review…" [value]="query()" (input)="query.set($any($event.target).value)"></label>
<nav class="academy-topics" aria-label="Training topics"><button type="button" (click)="topic.set('')" [attr.aria-pressed]="!topic()">All topics</button>@for(t of topics;track t.id){<button type="button" (click)="topic.set(t.id)" [attr.aria-pressed]="topic()===t.id">{{t.name}}</button>}</nav>
<p class="mono academy-count" aria-live="polite">{{filtered().length}} guides</p><div class="academy-grid">@for(g of filtered();track g.slug){<article class="academy-card"><p class="mono academy-kicker">{{label(g.cluster)}}</p><h2><a [routerLink]="'/articles/'+g.slug">{{g.title}}</a></h2><p>{{g.description}}</p><a class="academy-link" [routerLink]="'/articles/'+g.slug">Practise this →</a></article>}</div>
@if(!filtered().length){<p>No matching guides. Try a broader term or select another topic.</p><button type="button" (click)="query.set('');topic.set('')">Reset filters</button>}
</section>`,styleUrl:'./articles.scss'})
export class ArticlesPage{
 readonly topics=TOPICS;readonly query=signal('');readonly topic=signal('');readonly filtered=computed(()=>GUIDE_INDEX.filter(g=>(!this.topic()||g.cluster===this.topic())&&(!this.query()||(g.title+' '+g.description+' '+g.keyword).toLowerCase().includes(this.query().trim().toLowerCase()))));
 label(id:string){return TOPICS.find(t=>t.id===id)?.name||'Chess practice'}
 constructor(){inject(Seo).apply({path:'/articles',title:'Chess training guides: tactics, endgames and better practice',description:'100 practical chess guides covering tactics, calculation, positional play, endgames, game review and choosing a training routine.',updated:'2026-10-24'})}
}
@Component({selector:'bp-guide-article',changeDetection:ChangeDetectionStrategy.OnPush,imports:[RouterLink],template:`
<article class="page academy"><header><p class="mono academy-kicker"><a routerLink="/articles">Training notebook</a> · {{label()}}</p><h1>{{guide.title}}</h1><p class="academy-lede">{{guide.lede}}</p><p class="academy-byline">Brass Pawn editorial team · Updated 24 October 2026 · {{minutes()}} min read</p></header>
<div class="academy-layout"><div class="academy-prose">
@if(guide.exercise;as e){<section class="academy-exercise"><h2>A position to work through</h2><p>{{e.prompt}}</p><div class="academy-board" role="img" [attr.aria-label]="'Chess position, '+side(e.fen)+' to move. FEN: '+e.fen">@for(row of board(e.fen);track $index;let rank=$index){@for(cell of row;track $index;let file=$index){<span aria-hidden="true" [class.light]="(rank+file)%2===0" [class.dark]="(rank+file)%2===1" [class.white-piece]="cell && cell===cell.toUpperCase()" [class.black-piece]="cell && cell===cell.toLowerCase()">{{piece(cell)}}<small>{{file===0?8-rank:''}}{{rank===7?'abcdefgh'[file]:''}}</small></span>}}</div><p class="mono">{{side(e.fen)}} to move</p><details><summary>Compare with the recorded continuation</summary><p>{{e.line}}</p><p>This is a line from the training source, not a claim that every alternative has the same outcome. Calculate the opponent’s reply before revealing it.</p></details><p class="academy-source"><a [href]="e.sourceUrl" target="_blank" rel="noopener">{{e.source}}</a></p></section>}
@for(s of guide.sections;track s.heading;let i=$index){<section [id]="'section-'+i"><h2>{{s.heading}}</h2>@for(p of s.paragraphs;track p){<p>{{p}}</p>}@if(s.bullets?.length){<ul>@for(b of s.bullets;track b){<li>{{b}}</li>}</ul>}</section>}
<section class="academy-product"><p class="mono academy-kicker">Put the practice into a routine</p><h2>Where Brass Pawn fits</h2><p>{{guide.appFit}}</p><div class="academy-actions"><a class="button button--solid" [href]="site.appStore" rel="noopener">Brass Pawn on the App Store ↗</a><a routerLink="/training">Explore the training modes</a><a routerLink="/pricing">Free and Pro</a></div></section>
<section><h2>Sources and further practice</h2><ul>@for(s of guide.sources;track s.url){<li><a [href]="s.url" target="_blank" rel="noopener">{{s.label}} ↗</a></li>}</ul></section>
<section><h2>What to work on next</h2><ul>@for(g of related();track g.slug){<li><a [routerLink]="'/articles/'+g.slug">{{g.title}}</a></li>}</ul></section>
<nav class="academy-prevnext" aria-label="More training guides">@if(previous();as p){<a [routerLink]="'/articles/'+p.slug">← {{p.title}}</a>}@if(next();as n){<a [routerLink]="'/articles/'+n.slug">{{n.title}} →</a>}</nav>
</div><aside class="academy-toc"><h2>In this guide</h2><ol>@for(s of guide.sections;track s.heading;let i=$index){<li><a [routerLink]="'/articles/'+guide.slug" [fragment]="'section-'+i">{{s.heading}}</a></li>}</ol><hr><a routerLink="/articles">All 100 training guides →</a></aside></div></article>`,styleUrl:'./articles.scss'})
export class GuideArticlePage{
 readonly guide=inject(ActivatedRoute).snapshot.data['guide'] as ChessGuide;readonly site=SITE;
 label(){return TOPICS.find(t=>t.id===this.guide.cluster)?.name||'Chess practice'}
 minutes(){return Math.max(1,Math.ceil(this.guide.sections.reduce((n,s)=>n+s.paragraphs.join(' ').split(/\s+/).length+(s.bullets||[]).join(' ').split(/\s+/).length,0)/200))}
 related(){return GUIDE_INDEX.filter(g=>this.guide.related.includes(g.slug))}
 previous(){return GUIDE_INDEX[GUIDE_INDEX.findIndex(g=>g.slug===this.guide.slug)-1]}
 next(){return GUIDE_INDEX[GUIDE_INDEX.findIndex(g=>g.slug===this.guide.slug)+1]}
 board(fen:string){return fen.split(' ')[0].split('/').map(r=>[...r].flatMap(c=>/\d/.test(c)?Array(Number(c)).fill(''):[c]))}
 side(fen:string){return fen.split(' ')[1]==='w'?'White':'Black'}
 piece(c:string){return ({K:'♔',Q:'♕',R:'♖',B:'♗',N:'♘',P:'♙',k:'♚',q:'♛',r:'♜',b:'♝',n:'♞',p:'♟'} as Record<string,string>)[c]||''}
 constructor(){const g=this.guide;inject(Seo).apply({path:'/articles/'+g.slug,title:g.title,description:g.description,published:'2026-10-24',updated:'2026-10-24',crumbs:[{label:'Training guides',path:'/articles'}],entities:[{'@type':'Article',headline:g.title,description:g.description,datePublished:'2026-10-24',dateModified:'2026-10-24',author:{'@type':'Organization',name:'Brass Pawn editorial team',url:'https://brasspawn.com/'},publisher:{'@id':'https://brasspawn.com/#organization'},mainEntityOfPage:'https://brasspawn.com/articles/'+g.slug}]})}
}
