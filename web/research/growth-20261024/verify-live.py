import json,pathlib,urllib.request,urllib.parse,concurrent.futures,hashlib,xml.etree.ElementTree as ET,datetime
p=pathlib.Path(__file__).parent;out=p.resolve().parents[1]/'dist/brass-pawn/browser';g=json.loads((p/'keyword-map.json').read_text())
def check(a):
 u='https://brasspawn.com/articles/'+a['slug'];r=urllib.request.urlopen(u,timeout=30);data=r.read();expected=(out/'articles'/a['slug']/'index.html').read_bytes();return {'url':u,'status':r.status,'matchesBuild':hashlib.sha256(data).digest()==hashlib.sha256(expected).digest(),'robotsHeader':r.headers.get('x-robots-tag')}
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as ex:rows=list(ex.map(check,g))
assert all(x['status']==200 and x['matchesBuild'] and not x['robotsHeader'] for x in rows)
extra=[]
for path in ['/articles','/de','/bg/guides/chess-practice','/ja/today']:
 with urllib.request.urlopen('https://brasspawn.com'+path,timeout=25) as r:
  data=r.read();extra.append({'path':path,'status':r.status,'xRobotsTag':r.headers.get('x-robots-tag')})
  assert (r.headers.get('x-robots-tag')=='noindex, follow')== (path!='/articles')
sm=[]
for name in ['sitemap-pages.xml','sitemap-today.xml']:
 with urllib.request.urlopen('https://brasspawn.com/'+name,timeout=25) as r:
  urls=[x.text for x in ET.fromstring(r.read()).findall('{*}url/{*}loc')]
  excluded={x['slug'] for x in json.loads((p.resolve().parents[1]/'tools/locales.json').read_text())['locales'] if x['slug']!='en'}
  assert all(urllib.parse.urlparse(u).path.split('/')[1] not in excluded for u in urls)
  sm.append({'sitemap':name,'urls':len(urls),'englishOnly':True})
a={'checkedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'articles':rows,'otherPages':extra,'sitemaps':sm};(p/'live-verification.json').write_text(json.dumps(a,indent=2)+'\n');print({'articles200AndMatching':len(rows),'sitemaps':sm,'translatedHeaders':extra[1:]})
