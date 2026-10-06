from pathlib import Path
import json, hashlib

ROOT = Path(__file__).parent
POSES = ["idle","walk_a","walk_b","jump","fall","crouch","aim","melee","throw","roll","dive","climb","dead"]
ROSTER = [
    {"id":"brassline","label":"Brassline","body":"#d9913d","trim":"#4f2d28","face":"#f5c58b","gear":"helmet"},
    {"id":"mistral","label":"Mistral","body":"#48b7ad","trim":"#173f4b","face":"#d89272","gear":"scarf"},
    {"id":"nightjar","label":"Nightjar","body":"#8b78d6","trim":"#24243f","face":"#b97758","gear":"cape"},
    {"id":"cobalt","label":"Cobalt","body":"#e16b7d","trim":"#3d2238","face":"#e8ad7e","gear":"visor"},
]

def esc(v): return v.replace('&','&amp;')

def fighter(x, y, r, pose, facing=1):
    # All authored coordinates are integer logical pixels; bounds target 14-18 x 20-24.
    b,t,f = r['body'],r['trim'],r['face']
    def sx(v): return x + (v if facing==1 else 24-v)
    def rect(px,py,w,h,c): return f'<rect x="{sx(px)- (w if facing<0 else 0)}" y="{y+py}" width="{w}" height="{h}" fill="{c}"/>'
    def poly(points,c): return '<polygon points="'+' '.join(f'{sx(px)},{y+py}' for px,py in points)+'" fill="'+c+'"/>'
    # pose offsets, keeping feet/socket alignment within 1px.
    leg = (0,0)
    arm = (0,0)
    if pose in ('walk_a','climb'): leg=(-1,1); arm=(1,0)
    elif pose=='walk_b': leg=(1,1); arm=(-1,0)
    elif pose=='jump': leg=(-1,-2); arm=(1,-1)
    elif pose=='fall': leg=(1,0); arm=(-1,1)
    elif pose=='crouch': leg=(0,3); arm=(0,2)
    elif pose=='roll': leg=(2,4); arm=(2,1)
    elif pose=='dive': leg=(4,2); arm=(3,0)
    elif pose=='dead': leg=(3,5); arm=(2,3)
    out=[]
    # signature gear silhouette
    if r['gear']=='cape': out.append(poly([(4,8),(1,15),(5,20),(8,16)], t))
    if r['gear']=='scarf': out.append(poly([(8,6),(3,8),(7,10)], '#f0cf57'))
    # legs and torso
    if pose=='dead':
        out += [poly([(4,18),(13,18),(17,22),(6,22)],b), rect(8,14,6,5,t)]
    else:
        out += [rect(7+leg[0],15+leg[1],3,7,t), rect(12-leg[0],15-leg[1],3,7,t)]
        if r['gear']=='helmet':
            out.append(poly([(5,8),(7,6),(15,7),(16,15),(5,15)], b))
        elif r['gear']=='scarf':
            out.append(poly([(7,7),(14,8),(15,16),(6,15)], b))
        elif r['gear']=='cape':
            out.append(poly([(6,7),(15,7),(15,17),(5,15)], b))
        else:
            out.append(poly([(6,7),(15,7),(16,15),(5,16)], b))
    # head <= 30% body height; 6px head over 22px total.
    if pose=='dead': out.append(rect(14,16,6,5,f))
    else: out.append(rect(8,1,6,6,f))
    # head/face language
    if r['gear']=='helmet': out.append(rect(7,0,8,2,t))
    elif r['gear']=='visor': out.append(rect(7,2,8,2,t))
    elif r['gear']=='scarf': out.append(rect(8,0,6,1,t))
    else: out.append(rect(8,0,6,1,t))
    # arm + weapon extension <= 0.8 body width
    if pose in ('aim','melee','throw'):
        out.append(rect(14,8+arm[1],4,3,t))
        if pose=='melee': out.append(rect(17,7,4,1,'#d5e6e6'))
        elif pose=='throw': out.append(poly([(17,8),(20,7),(20,9)],'#e8b85b'))
        else: out.append(rect(17,9,3,1,'#d5e6e6'))
    elif pose not in ('dead','roll','dive'):
        out.append(rect(4,9+arm[1],3,3,t))
    if pose=='roll': out.append(poly([(4,11),(8,8),(14,9),(17,13),(12,17),(6,16)], b))
    if pose=='dive': out.append(poly([(3,11),(10,8),(17,9),(20,11),(12,13)], b))
    # face pixel + chest emblem make identities readable at 854x480.
    out.append(rect(13 if facing==1 else 8,3,1,1,'#141824'))
    out.append(rect(9,10,2,2,t))
    return ''.join(out)

def make_sheet():
    cols, rows, cw, ch = len(POSES), len(ROSTER), 28, 30
    W,H=cols*cw,rows*ch
    bg='<rect width="100%" height="100%" fill="#111522"/>'
    cells=[]
    for ri,r in enumerate(ROSTER):
        for ci,p in enumerate(POSES):
            x,y=ci*cw,ri*ch
            cells.append(f'<g id="{r["id"]}_{p}">{fighter(x+5,y+3,r,p,1)}</g>')
            # alternating tiny floor guides are not part of sprite bounds
            cells.append(f'<path d="M{x+2} {y+27}h24" stroke="#283043" stroke-width="1"/>')
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{W*4}" height="{H*4}" viewBox="0 0 {W} {H}" shape-rendering="crispEdges">{bg}{"".join(cells)}</svg>'
    (ROOT/'vf7_fighter_contact_sheet.svg').write_text(svg,encoding='utf-8')
    # Also emit individually addressable transparent cells for the eventual integrator.
    for r in ROSTER:
        out_dir = ROOT/'sprites'/r['id']; out_dir.mkdir(parents=True,exist_ok=True)
        for p in POSES:
            cell = f'<svg xmlns="http://www.w3.org/2000/svg" width="{28*4}" height="{30*4}" viewBox="0 0 28 30" shape-rendering="crispEdges"><g id="{r["id"]}_{p}">{fighter(5,3,r,p,1)}</g></svg>'
            (out_dir/f'{p}.svg').write_text(cell,encoding='utf-8')
    return svg

def main():
    svg=make_sheet()
    files=[]
    for p in sorted([ROOT/'generate_art.py',ROOT/'vf7_fighter_contact_sheet.svg', *((ROOT/'sprites').rglob('*.svg'))]):
        h=hashlib.sha256(p.read_bytes()).hexdigest(); files.append({'path':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':h,'bytes':p.stat().st_size})
    manifest={'schema':'vf7-art-draft/1','logical_tile_px':16,'sheet_cell_logical_px':[28,30], 'actor_target_logical_px':[14,24], 'poses':POSES,'roster':ROSTER,'files':files,'generated_by':'hand-authored deterministic SVG; clean-room; no reference asset input'}
    (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    prov='''VF7 ART DRAFT PROVENANCE\n=========================\nPurpose: quarantined presentation draft for VF7-WP1 review.\nSource: hand-authored integer-coordinate SVG generator (generate_art.py).\nClean-room: no Y8 screenshot, sprite, SWF, HTML5 package, web asset, trace, or copied title/character used.\nStyle: original dark industrial palette with four distinct silhouettes: helmet armor, scarf courier, cape warden, visor technician.\nGrid: 16px logical tile; contact sheet cells 28x30 logical px; actor bounds target 14-18x20-24 px.\nRendering: shape-rendering=crispEdges; intended nearest-neighbor integer scaling.\nStatus: DRAFT ONLY; not wired into live assets; no product checkbox/tick or commit.\nKnown gap: contact sheet is SVG (PNG export/live-window captures remain for integrator WP7-WP1).\n'''
    (ROOT/'PROVENANCE.md').write_text(prov,encoding='utf-8')
    (ROOT/'metrics.json').write_text(json.dumps({'actor_bounds_target':'14-18 x 20-24 logical px','head_max_fraction':0.30,'weapon_extension_max_fraction':0.80,'socket_drift_target_px':1,'silhouette_pairwise_target_pct':15,'measured':'geometry-authored bounds; pixel edge-mask measurement pending integrator'},indent=2),encoding='utf-8')
if __name__=='__main__': main()
