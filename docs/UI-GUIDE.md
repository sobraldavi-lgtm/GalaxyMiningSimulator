# Guia de interface do Galaxy Mining Simulator

A referência é [Ninja Legends](https://www.roblox.com/games/3956818381/Ninja-Legends). Para o Galaxy Mining, a prioridade é enxergar o saldo, o espaço da mochila e o progresso da ação em curso sem abrir menus. A linguagem visual usa contornos marcados, números grandes e a paleta espacial de Terra Nova.

| Cor | Uso |
| --- | --- |
| Azul marinho `#0B1530` | Superfície de painéis |
| Azul `#2563EB` | Botões e ações |
| Ciano `#22D3EE` | Mineração e progresso |
| Violeta `#8B5CF6` | Coleção de pets e contornos secundários |
| Âmbar `#FFB84D` | Créditos e alertas, sempre com texto |

O Design System 3.0 usa o módulo `VisualTheme` para superfícies, tipografia, botões e medidores. Os painéis combinam três tons de profundidade e uma faixa de luz com a cor da área. Os botões de navegação usam símbolos nativos em distintivos separados dos rótulos, que ajustam o tamanho ao espaço disponível. Use a cor e o texto juntos para comunicar função e estado.

A mochila reúne **Minérios** e **Pets**. O painel de mineração fica na parte inferior. Os menus usam os tempos de entrada e saída de `Theme.Motion`. Com movimento reduzido, os menus abrem e fecham imediatamente, e os botões ainda mudam de cor ao receber foco.

Na revisão do Studio, confira se o saldo longo cabe, se o botão da mochila responde ao toque e ao controle e se o painel inferior deixa espaço para os comandos virtuais. Confira também se o estado de mochila cheia e o resgate da Lumini são claros pelo texto.
