#!/usr/bin/env python3
"""Verificação estática simples para Luau quando o compilador não está disponível.

Aponta identificadores nunca declarados e locais de nível superior usados antes de
serem declarados (em Luau isso vira uma global nula e falha em tempo de execução).
Falsos positivos conhecidos: "self" e a palavra "function". Não substitui
`luau-analyze` nem o teste no Studio.

Uso (na raiz do projeto): python3 tools/lint_luau.py src/*/*.luau
"""
import re,sys
GLOBALS=set("""game workspace script Enum Instance Vector3 Vector2 CFrame Color3 ColorSequence ColorSequenceKeypoint NumberSequence
NumberSequenceKeypoint NumberRange UDim UDim2 TweenInfo Random RaycastParams OverlapParams Font task math string table utf8 os
pairs ipairs next type typeof tostring tonumber print warn error pcall xpcall select setmetatable getmetatable rawget rawset
require assert unpack tick time wait delay spawn debug coroutine buffer bit32 PhysicalProperties Ray Rect Region3 BrickColor
UserSettings settings DateTime shared _G self true false nil and or not then do end if else elseif for in while repeat until
function local return break continue Faces Axes""".split())
TYPES=set("number string boolean any Instance Player GuiObject TextLabel TextButton Frame ScreenGui UIScale TweenInfo Color3 BasePart LayerCollector".split())
def strip(src):
    out=[];i=0;n=len(src)
    while i<n:
        if src.startswith('--',i):
            m=re.match(r'--\[(=*)\[',src[i:])
            if m:
                j=src.index(']'+m.group(1)+']',i); out.append('\n'*src[i:j].count('\n')); i=j+len(m.group(1))+2; continue
            j=src.find('\n',i); i=n if j<0 else j; continue
        m=re.match(r'\[(=*)\[',src[i:])
        if m:
            j=src.index(']'+m.group(1)+']',i); out.append('""'+'\n'*src[i:j].count('\n')); i=j+len(m.group(1))+2; continue
        c=src[i]
        if c in '"\'`':
            j=i+1
            while src[j]!=c:
                if src[j]=='\\': j+=1
                j+=1
            out.append('""'); i=j+1; continue
        out.append(c); i+=1
    return ''.join(out)
def lint(path):
    src=strip(open(path,encoding='utf8').read())
    lines=src.split('\n')
    declared={}  # name -> first line declared
    alldecl={}  # name -> list of lines
    top={}      # name -> first top-level declaration line
    def decl(name,ln):
        if not name or not re.match(r'^[A-Za-z_]\w*$',name): return
        if name not in declared: declared[name]=ln
        alldecl.setdefault(name,[]).append(ln)
        if re.match(r'^(local\b|function\b)', lines[ln-1]) and name not in top: top[name]=ln
    for ln,l in enumerate(lines,1):
        for m in re.finditer(r'\blocal\s+function\s+(\w+)',l): decl(m.group(1),ln)
        for m in re.finditer(r'\blocal\s+((?:\w+\s*(?::\s*[\w?.|<>{} ]+)?\s*,\s*)*\w+)',l):
            for part in m.group(1).split(','):
                decl(part.split(':')[0].strip(),ln)
        for m in re.finditer(r'\bfor\s+([\w\s,]+?)\s+(?:in|=)',l):
            for part in m.group(1).split(','): decl(part.strip(),ln)
        for m in re.finditer(r'\bfunction\s*[\w.:]*\s*\(([^)]*)\)',l):
            for part in m.group(1).split(','):
                p=part.split(':')[0].strip()
                if p and p!='...': decl(p,ln)
        for m in re.finditer(r'^\s*function\s+(\w+)\s*\(',l): decl(m.group(1),ln)
    problems=[]
    toplevel_func_lines={}
    for ln,l in enumerate(lines,1):
        for m in re.finditer(r'(?<![\w.:])([A-Za-z_]\w*)',l):
            name=m.group(1); start=m.start(1)
            before=l[:start].rstrip()
            after=l[m.end(1):].lstrip()
            if name in GLOBALS or name in TYPES: continue
            if before.endswith('.') or before.endswith(':') and not before.endswith('::'): 
                # field access or method or type annotation
                continue
            if before.endswith('::'): continue
            # table constructor key:  Name =  (not ==)
            if re.match(r'=(?!=)',after) and (before.endswith('{') or before.endswith(',') or before=='' ):
                if name not in declared: continue
            if name not in declared:
                problems.append(f'{path}:{ln}: identificador não declarado: {name}')
    # use-before-declare for top-level locals
    for name,dl in top.items():
        if min(alldecl[name]) < dl: continue  # já havia declaração anterior (outro escopo)
        pat=re.compile(r'(?<![\w.:])'+re.escape(name)+r'(?!\w)')
        for ln in range(1,dl):
            l=lines[ln-1]
            for m in pat.finditer(l):
                before=l[:m.start()].rstrip(); after=l[m.end():].lstrip()
                if before.endswith('.') or before.endswith(':'): continue
                if re.match(r'=(?!=)',after) and (before.endswith('{') or before.endswith(',')): continue
                problems.append(f'{path}:{ln}: "{name}" usado antes de ser declarado (linha {dl})')
                break
    return problems
allp=[]
for p in sys.argv[1:]: allp+=lint(p)
seen=set()
for p in allp:
    if p not in seen and '"self"' not in p and '"function"' not in p: print(p); seen.add(p)
print(len(seen),"avisos (sem falsos positivos conhecidos)")
