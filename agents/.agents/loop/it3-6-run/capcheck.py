import importlib.util as u, os, re
def L(n,f):
    s=u.spec_from_file_location(n,f);m=u.module_from_spec(s);s.loader.exec_module(m);return m
cap=L("cap","skills-cap.py")
src=open("/tmp/proto.py").read().split("# candidate counts")[0]
exec(src)
files=ss.skill_files(); names=ss.skill_names(files)
rows=[]
for p in files:
    t=open(p,encoding="utf-8").read()
    m=re.search(r'^description:[ \t]*(.*)$', t, re.M)
    if not m: continue
    raw=m.group(1)
    q=raw[:1]
    desc=raw[1:raw.rfind(q)] if q in "\"'" and raw.rfind(q)>0 else raw
    new=normalize(desc,names)
    if new==desc: continue
    rows.append((cap.clen(desc),cap.clen(new),os.path.basename(os.path.dirname(p))))
rows.sort(reverse=True)
for r in rows: print("%3d -> %3d %s"%r)
print("changed",len(rows),"over270 after:",[r for r in rows if r[1]>270])
