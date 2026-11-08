# Guia de interface do Galaxy Mining Simulator

Direção visual **"Galáxia Profunda"** (Design System 5.1): simulador cartunesco no espaço profundo. Os fundos são quase pretos em índigo e violeta, as bordas de neon têm a cor de cada área, há nebulosas e estrelas nas janelas e os botões 3D são vivos. A referência de estilo é [Ninja Legends](https://www.roblox.com/games/3956818381/Ninja-Legends), sem copiar seus elementos.

| Cor | Hex | Uso |
| --- | --- | --- |
| Tinta | `#05030F` | Contornos, sombras e vinheta |
| Vazio / Noite / Ameixa | `#070418` / `#0C0726` / `#1A1048` | Degradê dos painéis e janelas |
| Real | `#2E1C9E` | Brilho superior e nebulosas |
| Ciano | `#22E1FF` | Mineração, carga e progresso |
| Violeta | `#A65BFF` | Poder e missões |
| Rosa | `#FF5FB8` | Pets e celebrações |
| Ouro | `#FFC531` | Créditos, itens equipados e metas |
| Menta | `#2EE59D` | Compra possível, sucesso e ajustes |
| Vermelho | `#FF3D57` | Mochila cheia, erros e botão fechar |

## Mundo à noite

- **Iluminação** (`default.project.json`): meia-noite, ambiente índigo e violeta, bloom forte para os neons, 5.000 estrelas, sem sol nem lua, e atmosfera roxa no horizonte.
- **Céu galáctico** (`VisualWorld.client.luau`, só no cliente): galáxia espiral girando devagar, nebulosas gigantes, faixa de "Via Láctea", estrelas cadentes e as nuvens do cenário transformadas em nebulosas de neon.
- **Vinheta** escura nas bordas da tela. A mineração ignora a vinheta e os contêineres transparentes ao decidir se um clique caiu na interface.

Use sempre cor **e** texto juntos para comunicar função e estado.

## Componentes (`src/client/VisualTheme.luau`)

- **Botão 3D** (`Theme.action`): base sólida escura e face colorida com brilho; a face afunda ao pressionar e cresce no hover/foco. O texto fica em `Face/Label`: use `Theme.setText` e `Theme.setTint`, nunca `button.Text`. Opções: `Size`, `Icon`, `TextSize`, `Radius`, `Depth`, `Silent`.
- **Navegação** (`Theme.navigationAction`): botão quadrado 3D com ícone grande, legenda e atalho.
- **Painel** (`Theme.panel`, com borda interna de neon), **poço** (`Theme.well`), **medidor** (`Theme.meter`, com brilho) e **esfera de ícone** (`Theme.badge`, com reflexo).
- **Janela** (`Theme.window`): sombra, moldura de neon, nebulosas (`Theme.nebula`), céu estrelado cintilante e cabeçalho colorido com ícone saindo pela borda e botão X 3D.
- **Efeitos** num único loop compartilhado: `Theme.rays` (raios giratórios), `Theme.shimmer` (faixa de brilho), `Theme.starfield` (estrelas) e `Theme.confetti`.
- **Interruptor** (`Theme.toggle`) com ícone, ON/OFF e som.
- **Tipografia:** `FredokaOne` em títulos, números e botões; Gotham em textos de apoio. **Números** no padrão brasileiro (`1.250`, `5,5`, `1,25 mi`).
- **Ícones** feitos de Frames, sem imagens externas: loja, mochila, missão, ajustes, broca, moeda, raio, gema, pet, estrela, cadeado, robô, alfinete, alvo, som, movimento e brilho.
- **Som** (`src/client/Sound.luau`): clique, golpe, recompensa e abertura de janela, com sons embutidos do Roblox (`rbxasset://sounds/...`).

Tudo que anima respeita **Movimento reduzido**.

## Telas

- **Carregamento** (`src/first/Loading.client.luau`, em ReplicatedFirst): céu estrelado, planeta com anel e lua orbitando, logotipo, barra de progresso e dicas.
- **HUD:** três pílulas no topo (Créditos com contagem animada e "+N"; Carga com medidor ciano → âmbar → vermelho pulsando; Poder com treino até o limite), menu 2×2 de botões 3D à esquerda e o cartão **Próxima meta** à direita: o item mais barato que falta, com progresso de Créditos e atalho para a loja. Com a mochila cheia, ele vira o alerta **MOCHILA CHEIA!**, com o botão "IR VENDER". Em telas pequenas, a navegação fica em linha e o cartão só aparece no alerta.
- **Notificações:** até três, em pílulas com ícone e cor pelo `Tone` do servidor.
- **Mochila:** resumo e grade de minérios (cor, quantidade, preço e peso); aba Pets com raios atrás do pet equipado e cadeado nos que faltam resgatar.
- **Missões:** prévia com ORBI em balão de fala e as cinco missões do GDD como "EM BREVE". O sistema de missões não existe ainda.
- **Ajustes:** Movimento reduzido, Sons, Números de dano, Placas dos minérios e Poeira cósmica.
- **Loja Orion:** cartões 3D na cor do item, com comparação com o equipamento atual, selo **PRÓXIMA** com brilho e raios, progresso até o preço, contadores por categoria e confete nas compras.
- **Mineração:** painel com esfera grande na cor do minério, barra de resistência com valores, "faltam N golpes", contorno colorido, clarão e números de dano empilhados, além de sons de golpe e de quebra.
- **Placas dos minérios:** acima de cada grupo de depósitos, com nome, resistência, golpes necessários com o poder atual (⌈resistência ÷ poder⌉, como no GDD) e um selo FÁCIL, MÉDIO, DIFÍCIL ou EXTREMO.
- **Prompts:** cartões holográficos com tecla 3D que se enche ao segurar; no toque, a tecla é um botão.
- **Mundo vivo** (só no cliente): planetas e anéis giram, ilhas, orbes e postes flutuam, nuvens derivam, estrelas dos postes rodam, chamas dos foguetes tremulam e hologramas dos portais pulsam. Só peças decorativas sem colisão de `TerraNova/Expansion` se movem.
- **Celebração:** raios, confete e cartão central no resgate de pet; vinheta "TERRA NOVA" depois do carregamento.

## Controles

| Ação | Teclado/mouse | Controle | Toque |
| --- | --- | --- | --- |
| Loja / Mochila / Missões / Ajustes | L / B / M / P | Seleção na barra | Botões da barra |
| Fechar janela | X ou clique fora | B | X ou toque fora |
| Interagir com terminal | E (segurar quando indicado) | X | Tocar na tecla do prompt |

## Revisão no Studio

1. Conferir no Output se nenhum som `rbxasset://sounds/...` falhou ao carregar.
2. Testar telas de celular em paisagem: pílulas, janelas e a grade da loja.
3. Conferir prompts com teclado, controle e toque, incluindo segurar para vender.
4. Conferir se as animações do cenário não atravessam construções e se o desempenho continua estável.
5. Testar os estados de mochila cheia, item "PRÓXIMA", pet equipado, compra e resgate de Lumini, com e sem Movimento reduzido.
