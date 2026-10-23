// Derive web exercises from the existing CC0 puzzle library, not invented chess lines.
const fs=require('node:fs'),path=require('node:path');
const {Chess}=require(path.resolve('node_modules/chess.js'));
const dir=__dirname, puzzles=JSON.parse(fs.readFileSync('data/tactics-lichess.json','utf8')).puzzles;
const themes=[[/knight.*fork|pawn.*fork|queen.*fork|double.attack.*fork/i,'fork'],[/pin.*skewer/i,'pin'],[/discover.*attack/i,'discoveredAttack'],[/double.check/i,'doubleCheck'],[/overload/i,'overloading'],[/deflection|decoy/i,'deflection'],[/remov.*defend/i,'capturingDefender'],[/back.rank/i,'backRankMate'],[/zwischenzug|in.between/i,'intermezzo'],[/clearance/i,'clearance'],[/interference/i,'interference'],[/x.ray/i,'xRayAttack'],[/hanging/i,'hangingPiece'],[/trapped/i,'trappedPiece'],[/quiet.*tactic/i,'quietMove'],[/mating.net/i,'mateIn2'],[/smothered/i,'smotheredMate'],[/attraction/i,'attraction'],[/defensive.tactic/i,'defensiveMove'],[/forc.*line|opponent.*defen/i,'advantage']];
const used=new Set(),checks=[];
for(const letter of ['a','b','c']){
 const file=path.join(dir,`batch-${letter}.json`),guides=JSON.parse(fs.readFileSync(file,'utf8'));
 for(const g of guides){
  const theme=themes.find(([re])=>re.test(g.title+' '+g.slug));if(!theme)continue;
  for(const p of puzzles){
   if(used.has(p.id)||!p.themes.includes(theme[1])||p.rating<900||p.rating>1900||!p.solution.length||p.solution.length>5)continue;
   try{const chess=new Chess(p.fen),san=[];const subject=/knight.*fork/i.test(g.slug)?'n':/pawn.*fork/i.test(g.slug)?'p':/queen.*fork/i.test(g.slug)?'q':null;if(subject && chess.get(p.solution[0].slice(0,2))?.type!==subject)continue;for(const uci of p.solution){const m=chess.move({from:uci.slice(0,2),to:uci.slice(2,4),...(uci[4]?{promotion:uci[4]}:{})});if(!m)throw Error('illegal move');san.push(m.san)}
    if(p.fen.split(' ')[0].split('/').some(r=>[...r].reduce((n,c)=>n+(/\d/.test(c)?Number(c):1),0)!==8))throw Error('invalid ranks');
    g.exercise={fen:p.fen,prompt:'Calculate a candidate continuation without moving the pieces. Look for the tactical idea, consider the opponent’s reply, then compare your calculation with the recorded line.',line:san.join(' · '),source:'Lichess CC0 puzzle database; position from Brass Pawn’s curated training data',sourceUrl:'https://database.lichess.org/#puzzles'};
    checks.push({slug:g.slug,puzzleId:p.id,theme:theme[1],fen:p.fen,uci:p.solution,san,legal:true});used.add(p.id);break;
   }catch(e){continue;}
  }
 }
 fs.writeFileSync(file,JSON.stringify(guides,null,2)+'\n');
}
fs.writeFileSync(path.join(dir,'exercise-legality.json'),JSON.stringify({source:'Existing CC0 training data',validator:'chess.js',note:'Legality of every recorded move was verified. No new engine-win or uniqueness claim is made.',positions:checks},null,2)+'\n');console.log('Verified diagrams:',checks.length);
