const data = window.DATA;
const geography = window.GEOGRAPHY;
const $ = id => document.getElementById(id);
const number = d3.format(',');
const percent = d3.format('.1f');
const month = d3.utcFormat('%B %Y');
const dateOf = value => new Date(value + 'T00:00:00Z');
const state = {year:'2024-2025', programme:'ODSP', measure:'cases', area:'555', code:'all', stage:'all', full:false};
const names = new Map(data.cases.map(d => [d.area, d.name]));
const areas = [...names].sort((a,b) => a[1].localeCompare(b[1]));
const tooltip = $('tooltip');
const blue = '#2166ac';
let currentHistory = [];
let historyCursor;

function schoolRows() {
  return data.schools.filter(d => d.year === state.year &&
    (state.code === 'all' || d.code === state.code) && (state.stage === 'all' || d.stage === state.stage));
}
function pairedDate() {return state.year.slice(-4) + '-03-31';}
function casesNow() {return data.cases.filter(d => d.programme === state.programme && d.date === pairedDate());}
function valueLabel(value) {return state.measure === 'cases' ? number(value) : percent(value) + '%';}
function areaName() {return state.area === 'outside' ? 'Belleville' : names.get(state.area);}
function showTip(event, text) {
  tooltip.textContent = text;
  tooltip.hidden = false;
  const r = event.currentTarget.getBoundingClientRect();
  tooltip.style.left = Math.max(8, Math.min(innerWidth - 265, (event.clientX || r.x) + 12)) + 'px';
  tooltip.style.top = Math.max(8, Math.min(innerHeight - 95, (event.clientY || r.y) + 14)) + 'px';
}
function hideTip() {tooltip.hidden = true;}
function choose(area) {
  state.area = area;
  if (area === '595' || area === '580') state.full = true;
  $('area').value = area;
  hideTip(); render();
}
function keyboardClick(event, callback) {
  if (event.key === 'Enter' || event.key === ' ') {event.preventDefault();callback();}
}

for (const year of data.years.slice().reverse()) $('year').add(new Option(year.replace('-', '–'), year));
for (const [code,name] of areas) $('area').add(new Option(name,code));
$('area').add(new Option('Belleville · outside coverage','outside'));
for (const id of ['year','programme','measure','area','code','stage']) {
  $(id).value = state[id];
  $(id).addEventListener('change', event => {
    state[id] = event.target.value;
    if (id === 'area') choose(state.area); else render();
  });
}
$('all-schools').addEventListener('change', renderSchools);
$('reset').addEventListener('click', () => {
  Object.assign(state,{year:'2024-2025',programme:'ODSP',measure:'cases',area:'555',code:'all',stage:'all',full:false});
  for (const id of ['year','programme','measure','area','code','stage']) $(id).value = state[id];
  $('all-schools').checked = false; render();
});
$('extent').addEventListener('click', () => {state.full = !state.full; renderMap();});
$('quarter').addEventListener('input', () => inspectQuarter(+$('quarter').value));
$('course-source').href = data.sources.course;
$('boundary-source').href = data.sources.boundaries;

// A local projection keeps the map independent of tile services.
function projectedCoordinates(c) {
  return typeof c[0] === 'number' ? [c[0] * .7, -c[1]] : c.map(projectedCoordinates);
}
function projectedFeature(f) {
  return {...f, geometry:{...f.geometry,coordinates:projectedCoordinates(f.geometry.coordinates)}};
}
const mapAreas = geography.areas.features.map(projectedFeature);
const land = geography.outline.features.map(projectedFeature);
function renderMap() {
  const host = $('map');
  const w = host.clientWidth, h = host.clientHeight;
  const bounds = state.full ? [-95.3,41.5,-74,57.2] : [-83.7,41.8,-74.1,46.5];
  const box = {type:'MultiPoint',coordinates:[[bounds[0]*.7,-bounds[1]],[bounds[2]*.7,-bounds[3]]]};
  const projection = d3.geoIdentity().fitExtent([[20,15],[w-20,h-15]],box);
  const path = d3.geoPath(projection);
  const point = d => projection([d.lon*.7,-d.lat]);
  host.replaceChildren();
  const svg = d3.select(host).append('svg').attr('viewBox',`0 0 ${w} ${h}`);
  svg.append('title').text('Selected school locations and the 15 covered metropolitan areas');
  svg.append('defs').append('clipPath').attr('id','map-clip').append('rect').attr('width',w).attr('height',h);
  const g = svg.append('g').attr('clip-path','url(#map-clip)');
  g.selectAll('.land').data(land).join('path').attr('class','land').attr('d',path);
  g.selectAll('.area').data(mapAreas).join('path')
    .attr('class',d => 'area' + (d.properties.CMAUID === state.area ? ' selected' : ''))
    .attr('d',path).attr('role','button').attr('tabindex',0)
    .attr('aria-label',d => 'Select ' + names.get(d.properties.CMAUID))
    .attr('aria-pressed',d => d.properties.CMAUID === state.area)
    .on('click',(event,d) => choose(d.properties.CMAUID))
    .on('keydown',(event,d) => keyboardClick(event,() => choose(d.properties.CMAUID)))
    .on('pointermove',(event,d) => showTip(event,names.get(d.properties.CMAUID)))
    .on('pointerleave',hideTip).on('blur',hideTip);
  const rows = schoolRows();
  const locations = [...d3.group(rows.filter(d => d.lon !== null && d.lat !== null),d => d.location)]
    .map(([key,records]) => ({...records[0],records}));
  const dots = g.selectAll('.location').data(locations).join('g').attr('class','location')
    .attr('transform',d => `translate(${point(d)})`).attr('role','button').attr('tabindex',0)
    .attr('aria-label',d => `${d.city}: ${d.records.length} school records. ${d.status}.`)
    .on('click',(event,d) => choose(d.area || 'outside'))
    .on('keydown',(event,d) => keyboardClick(event,() => choose(d.area || 'outside')))
    .on('pointermove',(event,d) => showTip(event,`${d.city}: ${d.records.length} records at these coordinates. ${d.status}.`))
    .on('focus',(event,d) => showTip(event,`${d.city}: ${d.records.length} records. ${d.status}.`))
    .on('pointerleave',hideTip).on('blur',hideTip);
  dots.append('circle').attr('class',d => 'school-dot' + (d.area ? '' : ' outside')).attr('r',5);
  const cities = [...d3.group(locations,d=>d.city)].map(([city,places]) => ({city,places,...places[0]}));
  const offsets = {London:[-25,28],Brantford:[-55,-8],Milton:[18,-32],Belleville:[12,-18]};
  for (const city of cities) {
    const p = point(city), offset = offsets[city.city] || [9,-10];
    const text = city.city + (city.places.length > 1 ? ` · ${city.places.length} locations` : '');
    g.append('line').attr('x1',p[0]).attr('y1',p[1]).attr('x2',p[0]+offset[0]).attr('y2',p[1]+offset[1]-4)
      .attr('stroke','#777').attr('stroke-width',.5);
    g.append('text').attr('x',p[0]+offset[0]).attr('y',p[1]+offset[1]).text(text);
  }
  const labels = state.full ? [['Thunder Bay',-89.3,49],['Greater Sudbury',-81,47.3]] : [['Ottawa',-75.65,45.6],['Lake Ontario',-78.7,43.3]];
  for (const [label,lon,lat] of labels) {
    const p=projection([lon*.7,-lat]);
    g.append('text').attr('class','map-label').attr('x',p[0]).attr('y',p[1]).text(label);
  }
  $('extent').textContent = state.full ? 'Southern Ontario ↙' : 'All Ontario ↗';
  const outside = rows.filter(d=>d.status === 'Outside assistance coverage').length;
  const missing = rows.filter(d=>d.location === null).length;
  $('coverage').textContent = `${rows.length} school records · ${locations.length} reported locations · ${outside} records outside assistance coverage` + (missing ? ` · ${missing} without coordinates` : '') + '. 2021 reference boundaries.';
}

function renderComparison() {
  const rows = casesNow().sort((a,b) => b[state.measure] - a[state.measure]);
  const schools = d3.rollup(schoolRows().filter(d=>d.area), v=>v.length, d=>d.area);
  const max = state.measure === 'cases' ? d3.max(rows,d=>d.cases) : 100;
  $('comparison').replaceChildren();
  for (const row of rows) {
    const button = document.createElement('button');
    button.type = 'button'; button.className = 'area-row' + (row.area === state.area ? ' active' : '');
    button.setAttribute('aria-pressed',row.area === state.area);
    button.setAttribute('aria-label',`${row.name}: ${valueLabel(row[state.measure])} ${state.measure === 'cases' ? 'cases' : 'single-parent share'}, ${schools.get(row.area) || 0} selected school records`);
    button.addEventListener('click',()=>choose(row.area));
    const label = document.createElement('span');label.className='area-name';label.textContent=row.name;
    const cell = document.createElement('span');cell.className='area-cell';
    const track = document.createElement('span');track.className='area-track';
    const bar = document.createElement('span');bar.className='area-bar';bar.style.width=`${100 * row[state.measure]/max}%`;track.append(bar);
    const value = document.createElement('span');value.className='area-value';value.textContent=valueLabel(row[state.measure]);
    cell.append(track,value);
    const count = document.createElement('span');count.className='school-count'+(schools.has(row.area)?'':' zero');count.textContent=schools.get(row.area)||0;
    button.append(label,cell,count);$('comparison').append(button);
  }
  $('measure-heading').textContent = state.measure === 'cases' ? 'Cases · scale from 0' : 'Single parents · 0–100%';
  $('comparison-note').textContent = state.measure === 'cases' ? 'Counts are not adjusted for population. All bars start at zero.' : 'Single-parent cases ÷ all cases in the same area and quarter.';
}

function renderHistory() {
  currentHistory = data.cases.filter(d=>d.area === state.area && d.programme === state.programme);
  const host=$('history');host.replaceChildren();
  $('history-unit').textContent = state.measure === 'cases' ? 'Cases' : 'Single-parent share';
  $('quarter').disabled = currentHistory.length === 0;
  if (!currentHistory.length) {
    host.innerHTML='<p class="empty">No assistance series for Belleville<br>in these files.</p>';
    $('history-readout').textContent='Unavailable';return;
  }
  const w=host.clientWidth,h=host.clientHeight;
  const x=d3.scaleUtc().domain(d3.extent(currentHistory,d=>dateOf(d.date))).range([48,w-18]);
  const y=d3.scaleLinear().domain([0,state.measure === 'cases' ? d3.max(currentHistory,d=>d.cases)*1.05 : 100]).nice().range([h-28,18]);
  const svg=d3.select(host).append('svg').attr('viewBox',`0 0 ${w} ${h}`).attr('role','img');
  svg.append('title').text(`${areaName()}, ${state.programme}: quarterly ${state.measure === 'cases'?'caseload':'single-parent share'} history. Use the slider to inspect exact values.`);
  svg.append('g').attr('transform',`translate(48,0)`).call(d3.axisLeft(y).ticks(4).tickSize(-(w-66)).tickFormat(state.measure === 'cases' ? d3.format('~s') : d=>d+'%')).call(g=>g.selectAll('.tick line').attr('stroke-opacity',.65));
  svg.append('g').attr('transform',`translate(0,${h-28})`).call(d3.axisBottom(x).tickValues([2003,2010,2020,2026].map(y=>new Date(Date.UTC(y,y===2003?2:0,1)))).tickFormat(d3.utcFormat('%Y')).tickSize(0));
  svg.append('path').datum(currentHistory).attr('class','trace').attr('d',d3.line().x(d=>x(dateOf(d.date))).y(d=>y(d[state.measure])));
  const paired=currentHistory.find(d=>d.date === pairedDate());
  svg.append('line').attr('class','pair-line').attr('x1',x(dateOf(paired.date))).attr('x2',x(dateOf(paired.date))).attr('y1',12).attr('y2',h-28);
  svg.append('circle').attr('cx',x(dateOf(paired.date))).attr('cy',y(paired[state.measure])).attr('r',4).attr('fill','var(--paper)').attr('stroke',blue).attr('stroke-width',2);
  const cursor=svg.append('circle').attr('r',3).attr('fill',blue);
  historyCursor = row => cursor.attr('cx',x(dateOf(row.date))).attr('cy',y(row[state.measure]));
  const pairIndex=currentHistory.indexOf(paired);$('quarter').value=pairIndex;inspectQuarter(pairIndex);
  svg.on('pointermove',event=>{
    const px=d3.pointer(event)[0],date=x.invert(px);
    const i=d3.bisector(d=>dateOf(d.date)).center(currentHistory,date);
    $('quarter').value=i;inspectQuarter(i);
  });
}
function inspectQuarter(index) {
  const row=currentHistory[index];if(!row)return;
  historyCursor(row);
  $('history-readout').textContent=`${month(dateOf(row.date))} · ${valueLabel(row[state.measure])}${state.measure === 'cases'?' cases':''}`;
  $('quarter').setAttribute('aria-valuetext',$('history-readout').textContent);
}
function renderComposition() {
  $('composition').replaceChildren();
  $('composition-date').textContent=month(dateOf(pairedDate()));
  const row=casesNow().find(d=>d.area === state.area);
  if(!row){$('composition').innerHTML='<p class="empty">Not reported for Belleville.</p>';return;}
  for(const [key,label] of [['fts','Single, without children'],['ftsp','Single parent'],['ftc','Couple, with or without children']]) {
    const share=100*row[key]/row.cases;
    const div=document.createElement('div');div.className='family';
    div.innerHTML=`<div class="family-label"><span>${label}</span><span>${percent(share)}%</span></div><div class="family-track"><div class="family-fill" style="width:${share}%"></div></div><span class="family-count">${number(row[key])} cases</span>`;
    $('composition').append(div);
  }
}
function renderSchools() {
  const all=$('all-schools').checked;
  const rows=schoolRows().filter(d=>all || (state.area === 'outside' ? d.status === 'Outside assistance coverage' : d.area === state.area));
  rows.sort((a,b)=>a.city.localeCompare(b.city)||a.location?.localeCompare(b.location)||a.name.localeCompare(b.name));
  $('school-rows').replaceChildren();
  $('school-summary').textContent=`${rows.length} records · ${all?'all areas':areaName()} · ${state.year.replace('-','–')}`;
  for(const row of rows) {
    const tr=document.createElement('tr');
    const title=document.createElement('td');title.textContent=row.name;
    const note=document.createElement('span');note.className='record-note';note.textContent=`School ${row.id}`;title.append(note);tr.append(title);
    const enrolment = row.enrolment !== null && /^\d+$/.test(row.enrolment) ? number(+row.enrolment) : 'Unavailable';
    for(const value of [row.code,row.stage,row.city,enrolment]) {
      const td=document.createElement('td');td.textContent=value;tr.append(td);
    }
    const loc=tr.children[3];
    const note2=document.createElement('span');note2.className='record-note';note2.textContent=row.status === 'Matched' ? names.get(row.area) : row.status;loc.append(note2);
    $('school-rows').append(tr);
  }
  if(!rows.length) {
    const tr=document.createElement('tr');const td=document.createElement('td');td.colSpan=5;td.className='empty';
    td.textContent='No matching school records. Try another area or show all selected records.';tr.append(td);$('school-rows').append(tr);
  }
}
function render() {
  $('period').textContent=`School year ${state.year.replace('-','–')} · assistance snapshot ${month(dateOf(pairedDate()))}`;
  $('programme-name').textContent=state.programme === 'OW' ? 'Ontario Works' : 'Ontario Disability Support Program';
  $('detail-title').textContent=areaName();
  $('detail-note').textContent=state.area === 'outside' ? 'Outside assistance coverage. School records remain visible.' : `${state.programme} · ${month(dateOf(pairedDate()))}. Dotted line marks this quarter in the history.`;
  renderMap();renderComparison();renderHistory();renderComposition();renderSchools();
}
let resizeTimer;
window.addEventListener('resize',()=>{clearTimeout(resizeTimer);resizeTimer=setTimeout(()=>{renderMap();renderHistory();},120);});
render();
