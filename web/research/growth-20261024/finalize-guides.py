import json,pathlib,re,collections
root=pathlib.Path(__file__).resolve().parents[3];d=pathlib.Path(__file__).parent
allguides=[]
slugs={'thepin':'the-pin','thefork':'the-fork','discoveredattacks':'discovered-attacks','doublecheck':'double-check','overloadedpieces':'overloaded-pieces','xray':'x-ray','zwischenzug':'zwischenzug','attraction':'attraction','clearance':'clearance','deflection':'deflection','interference':'interference','undermining':'undermining','keysquares':'key-squares','basicrookendgames':'basic-rook-endgames'}
short={
'opening-memorization-vs-ideas':'Build opening knowledge around move purposes, pawn breaks and responses to unfamiliar replies rather than memorising long sequences.',
'defend-early-queen-attacks':'Identify the real threat before chasing an early queen, develop with tempo when safe, and check which squares your move leaves undefended.',
'learn-opening-traps':'Study the mistake behind an opening trap and the sound defence, so your opening still works when the opponent avoids the trap.',
'chess-engine-assistance-fair-play':'Learn when engine analysis is appropriate, keep it outside live human matches and check each platform’s fair-play rules.',
'online-chess-connection-planning':'Check your connection, battery and time control before an online chess match, and know the platform’s reconnection rules.'}
for letter in 'abc':
 p=d/f'batch-{letter}.json';guides=json.loads(p.read_text())
 for g in guides:
  if g['slug'] in short:g['description']=short[g['slug']]
  for s in g['sources']:
   for old,new in slugs.items():s['url']=s['url'].replace('practicestnam'+old+'/',new+'/')
  for section in g['sections']:
   section['paragraphs']=[s.replace('An opposing king often cannot capture it without meeting that protecting pawn, so the passer can restrict the king\'s activity.','While its support remains, the opposing king cannot legally capture it, because that would move into check. The passer can therefore restrict the king\'s activity.').replace('when setting up any position manually.','when setting up a position manually in an external analysis tool that supports it.') for s in section['paragraphs']]
  g.pop('wordCount',None)
 p.write_text(json.dumps(guides,ensure_ascii=False,indent=2)+'\n');allguides+=guides
assert len(allguides)==100
by={g['slug']:g for g in allguides};assert len(by)==100
# Retain curated same-topic choices and add one related guide across the editorial batches.
sets=[{g['slug'] for g in json.loads((d/f'batch-{x}.json').read_text())} for x in 'abc']
stop=set('chess the a an and of in to for your how with before from move moves training practice position positions'.split())
def tokens(g):return set(re.findall(r'[a-z]+',g['title'].lower()+' '+g['keyword'].lower()))-stop
for g in allguides:
 related=list(dict.fromkeys(g['related']));assert len(related)>=3 and all(s in by and s!=g['slug'] for s in related)
 group=next(s for s in sets if g['slug'] in s)
 candidates=[x for x in allguides if x['slug'] not in group]
 cross=max(candidates,key=lambda x:len(tokens(g)&tokens(x)))
 if len(tokens(g)&tokens(cross))>0:related.append(cross['slug'])
 g['related']=related
 assert len(g['description'])<=160 and not g['description'].endswith('…')
 assert len(g['sections'])>=4 and len(g['sources'])>=2
out=root/'web/src/app/pages/articles'
(out/'guide-data.ts').write_text("import { ChessGuide } from './types';\nexport const GUIDES: readonly ChessGuide[] = "+json.dumps(allguides,ensure_ascii=False,indent=2)+';\n')
index=[{k:g[k] for k in ['slug','title','description','keyword','cluster']} for g in allguides]
(out/'guide-index.ts').write_text("import { GuideSummary } from './types';\nexport const GUIDE_INDEX: readonly GuideSummary[] = "+json.dumps(index,ensure_ascii=False,indent=2)+';\n')
counts=[len(re.findall(r"\b[\w’'-]+\b",' '.join([g['lede'],g['appFit']]+[p for s in g['sections'] for p in s['paragraphs']]+[b for s in g['sections'] for b in s.get('bullets',[])]))) for g in allguides]
paragraphs=[p for g in allguides for s in g['sections'] for p in s['paragraphs']]
dups=[p for p,n in collections.Counter(paragraphs).items() if n>1]
assert not dups,dups
assert min(counts)>=400
report={'articles':len(allguides),'words':sum(counts),'minWords':min(counts),'maxWords':max(counts),'uniqueKeywords':len({g['keyword'] for g in allguides}),'uniqueTitles':len({g['title'] for g in allguides}),'duplicateBodyParagraphs':len(dups),'verifiedDiagrams':sum(bool(g.get('exercise')) for g in allguides),'clusters':dict(collections.Counter(g['cluster'] for g in allguides)),'relatedLinks':sum(len(g['related']) for g in allguides),'indexing':'English only','demandEvidence':'Observed competitor topics and Google Search Console; no search volume, difficulty or rank promises.'}
(d/'final-content-qa.json').write_text(json.dumps(report,indent=2)+'\n');(d/'keyword-map.json').write_text(json.dumps(index,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report))
