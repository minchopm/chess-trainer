import json,pathlib,xml.etree.ElementTree as ET,re,hashlib
from html.parser import HTMLParser
base=pathlib.Path(__file__).resolve().parents[2];out=base/'dist/brass-pawn/browser';d=pathlib.Path(__file__).parent
class Page(HTMLParser):
 def __init__(self,s):super().__init__();self.meta={};self.links=[];self.canonical='';self.h1=[];self.in_h1=False;self.lang='';self.feed(s)
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='meta':self.meta[a.get('name',a.get('property',''))]=a.get('content','')
  if t=='link' and a.get('rel')=='canonical':self.canonical=a.get('href','')
  if t=='a':self.links.append(a.get('href',''))
  if t=='html':self.lang=a.get('lang','')
  if t=='h1':self.in_h1=True
 def handle_endtag(self,t):
  if t=='h1':self.in_h1=False
 def handle_data(self,s):
  if self.in_h1:self.h1.append(s)
guides=json.loads((d/'keyword-map.json').read_text());slugs={g['slug'] for g in guides};results=[]
for g in guides:
 path=out/'articles'/g['slug']/'index.html';s=path.read_text();p=Page(s)
 assert ''.join(p.h1).startswith(g['title']),(g['slug'],'h1')
 assert p.meta['description']==g['description'],(g['slug'],'description')
 assert p.canonical=='https://brasspawn.com/articles/'+g['slug']
 assert p.lang.lower().startswith('en') and 'noindex' not in p.meta.get('robots','')
 assert 'application/ld+json' in s and 'Article' in s
 links=[x.split('#')[0].rstrip('/').rsplit('/',1)[-1] for x in p.links if x.startswith('/articles/')]
 assert all(x in slugs for x in links),(g['slug'],'broken guide link')
 results.append({'slug':g['slug'],'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
hub=Page((out/'articles/index.html').read_text());assert len(set(x for x in hub.links if x.startswith('/articles/')))==100
xml=ET.fromstring((out/'sitemap-pages.xml').read_bytes());urls=[x.text for x in xml.findall('{*}url/{*}loc')];assert len([u for u in urls if '/articles/' in u])==100
locales={x['slug'] for x in json.loads((base/'tools/locales.json').read_text())['locales'] if x['slug']!='en'}
assert all(u.removeprefix('https://brasspawn.com/').split('/')[0] not in locales for u in urls)
for lang in ['bg','de','ja','ar']:
 p=Page((out/lang/'index.html').read_text());assert 'noindex' in p.meta['robots']
 for tail in ['guides/chess-practice','training']:
  p=Page((out/lang/tail/'index.html').read_text());assert 'noindex' in p.meta['robots']
a={'articles':100,'hubLinks':100,'sitemapPages':len(urls),'sitemapEnglishOnly':True,'translatedNoindexSamples':12,'articlesChecked':results};(d/'build-audit.json').write_text(json.dumps(a,indent=2)+'\n');print({k:v for k,v in a.items() if k!='articlesChecked'})
