# Guia de interface do Galaxy Mining Simulator

A referência é [Ninja Legends](https://www.roblox.com/games/3956818381/Ninja-Legends). Para o Galaxy Mining, a prioridade é enxergar o saldo, o espaço da mochila e o progresso da ação em curso sem abrir menus. A linguagem visual usa contornos marcados, números grandes e a paleta espacial de Terra Nova.

| Cor | Uso |
| --- | --- |
| Azul marinho `#1B1250` / `#0A0630` | Superfícies e contornos |
| Azul `#2F7BFF` | Botões e ações |
| Ciano `#00D8FF` | Mineração, carga e progresso |
| Violeta `#A855F7` | Poder, pets e contornos secundários |
| Ouro `#FFB800` | Créditos, itens equipados e metas |
| Verde `#2FD16B` | Compra possível e sucesso |
| Vermelho `#FF3B4E` | Mochila cheia, erros e botão fechar |

Use sempre cor **e** texto juntos para comunicar função e estado.

## Design System 4.0 (`src/client/VisualTheme.luau`)

- **Tipografia:** `FredokaOne` (arredondada, cartunesca) para títulos e números; `GothamBold`/`GothamMedium` para rótulos e textos de apoio. Textos longos usam `Theme.fitText` para encolher sem cortar.
- **Números:** `Theme.format` usa o padrão brasileiro (`1.250`, `5,5`); `Theme.compact` abrevia a partir de um milhão (`1,25 mi`).
- **Ícones:** desenhados com Frames, sem imagens externas: loja, mochila, missão, ajustes, broca, moeda, raio, gema, pet, estrela, cadeado, robô (ORBI), alfinete e brilho. `Theme.badge` coloca o ícone num distintivo redondo.
- **Componentes:** `panel`, `well`, `meter`, `action` (com foco, hover e clique), `navigationAction` (com atalho de teclado), `toggle` (interruptor) e `window` (janela modal com faixa de título, sombra e botão fechar), usada pela loja e pelos menus.
- **Movimento:** `Theme.Motion` define Interaction, Enter, Exit, Pop, Count e Float. `Theme.tween` e `Theme.pop` respeitam **Movimento reduzido**: as mudanças acontecem sem animação.

## Telas

- **HUD (topo):** Créditos com contagem animada e "+N" a cada ganho; Carga com medidor (ciano → âmbar a 80% → vermelho e contorno pulsando quando cheia) e "+1 minério" a cada coleta; Poder com o progresso do treino até o limite da mochila (medidor dourado no máximo).
- **Navegação:** à esquerda em telas largas (com atalhos L, B, M, P); em linha abaixo da HUD em telas pequenas.
- **Notificações:** até três empilhadas, com cor e ícone pelo tipo (`Tone` enviado pelo servidor: success, error, warning, sale, power). As coletas não geram notificação, porque já aparecem no contador.
- **Mochila:** resumo (carga, valor estimado na venda, ferramenta) e grade dos nove minérios com cor, quantidade e preço unitário; aba Pets com cartões, cadeado para os não resgatados e destaque dourado para o equipado. O valor estimado é só informativo; a venda é calculada no servidor.
- **Missões:** prévia com ORBI e as cinco missões do GDD marcadas como "EM BREVE". O sistema de missões ainda não existe.
- **Ajustes:** interruptores de Movimento reduzido, Números de dano e Poeira cósmica (preferências locais da sessão).
- **Loja Orion:** contadores de itens obtidos por categoria, comparação com o equipamento atual (por exemplo "Poder 20 (+8)"), selo **PRÓXIMA** no primeiro item ainda não obtido (a grade rola até ele), barra de progresso até o preço e mensagens coloridas do servidor.
- **Mineração:** painel inferior com o distintivo na cor do minério, barra de resistência com valores, contorno ciano (ao alcance) ou âmbar (fora de alcance), clarão a cada golpe e números de dano empilhados; a quebra mostra "+1 minério" em dourado.
- **Celebração:** ao resgatar um pet, aparece um cartão central com raios giratórios; também há uma vinheta "TERRA NOVA" ao entrar.

## Controles

| Ação | Teclado/mouse | Controle | Toque |
| --- | --- | --- | --- |
| Loja / Mochila / Missões / Ajustes | L / B / M / P | Seleção na barra | Botões da barra |
| Fechar janela | X ou clique fora | B | X ou toque fora |

Ao abrir uma janela com o controle, o primeiro botão recebe o foco automaticamente.

## Revisão no Studio

Confira se o saldo longo cabe, se as janelas cabem em telas de celular (paisagem), se os botões respondem a toque e controle e se o painel de mineração deixa espaço para os comandos virtuais. Confira também os estados de mochila cheia, item "PRÓXIMA", pet equipado e a celebração do resgate de Lumini, com e sem Movimento reduzido.
