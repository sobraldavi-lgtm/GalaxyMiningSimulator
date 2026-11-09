#!/usr/bin/env python3
"""Confere o balanceamento de blocos Luau (function/if/do × end, parênteses e chaves).

Uso (na raiz do projeto): python3 tools/check_blocks.py src/*/*.luau tests/*.luau
"""
import re,sys
def tokens(src):
    i=0;n=len(src);line=1
    while i<n:
        c=src[i]
        if c=='\n': line+=1;i+=1;continue
        if src.startswith('--',i):
            m=re.match(r'--\[(=*)\[',src[i:])
            if m:
                close=']'+m.group(1)+']';j=src.index(close,i);line+=src[i:j].count('\n');i=j+len(close)
            else:
                j=src.find('\n',i);i=n if j<0 else j
            continue
        m=re.match(r'\[(=*)\[',src[i:])
        if m:
            close=']'+m.group(1)+']';j=src.index(close,i);line+=src[i:j].count('\n');yield('str',line);i=j+len(close);continue
        if c in '"\'`':
            j=i+1
            while src[j]!=c:
                if src[j]=='\\': j+=1
                if src[j]=='\n': raise SystemExit(f'unterminated string line {line}')
                j+=1
            yield('str',line);i=j+1;continue
        m=re.match(r'[A-Za-z_]\w*',src[i:])
        if m: yield(m.group(0),line);i+=len(m.group(0));continue
        if not c.isspace(): yield(c,line)
        i+=1
def check(path):
    src=open(path,encoding='utf8').read()
    stack=[];prev=None
    toks=list(tokens(src))
    for k,(t,line) in enumerate(toks):
        if t in('function','do','repeat','(','{','['): 
            stack.append((t,line))
        elif t=='if':
            # if-expression: preceded by = , ( return etc  -> still needs 'then ... else' without end
            p=toks[k-1][0] if k else ''
            if p in ('=','(',',','return','and','or','..','{','not'):
                stack.append(('ifexpr',line))
            else: stack.append(('if',line))
        elif t=='while' or t=='for':
            pass  # their 'do' is counted
        elif t=='end':
            if not stack: return f'{path}:{line}: extra end'
            o=stack.pop()
            if o[0] not in('function','do','if'): return f'{path}:{line}: end closes {o}'
        elif t=='until':
            o=stack.pop()
            if o[0]!='repeat': return f'{path}:{line}: until closes {o}'
        elif t in ')}]':
            o=stack.pop() if stack else None
            if o is None: return f'{path}:{line}: extra {t}'
            # close pending if-exprs
            while o[0]=='ifexpr':
                o=stack.pop()
            if {')':'(','}':'{',']':'['}[t]!=o[0]: return f'{path}:{line}: {t} closes {o}'
        elif t=='local' and stack and stack[-1][0]=='ifexpr':
            stack.pop()
    # strip trailing ifexprs
    stack=[s for s in stack if s[0]!='ifexpr']
    if stack: return f'{path}: unclosed {stack[-3:]}'
    return None
bad=0
for p in sys.argv[1:]:
    r=check(p)
    print(r or f'OK {p}'); bad+= r is not None
sys.exit(bad)
