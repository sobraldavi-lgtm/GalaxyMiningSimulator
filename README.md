# Galaxy Mining Simulator

Projeto Roblox/Luau com Rojo. Fase atual: Terra Nova, mineração por cliques, mochila, venda e primeiras melhorias.

## Estrutura

| Caminho | Destino no Studio | Responsabilidade futura |
| --- | --- | --- |
| src/client | StarterPlayer/StarterPlayerScripts/Client | Entrada, interfaces e efeitos |
| src/server | ServerScriptService/Server | Regras e dados do jogo |
| src/shared | ReplicatedStorage/Shared | Módulos e configurações compartilhados |
| src/first/Loading.client.luau | ReplicatedFirst/GalaxyLoading | Tela de carregamento |
| src/world/terra-nova.project.json | Workspace/TerraNova | Cenário estático inicial |
| docs/GDD.md | Documentação | Design e balanceamento |
| ROADMAP.md | Documentação | Entregas e progresso |
| AGENTS.md | Instruções | Regras para trabalhar neste projeto |

Cliente e servidor contêm scripts Bootstrap de diagnóstico.
O cenário TerraNova e o SpawnLocation padrão são gerenciados pelo Rojo.
O restante do Workspace é preservado, incluindo o Baseplate original.
Editar as peças de TerraNova no arquivo do cenário: alterações feitas apenas no Studio
não são exportadas automaticamente para o projeto.
As pastas Client, Server e Shared também são gerenciadas pelo Rojo.

## Preparar o ambiente

1. Instalar Rojo CLI para Windows e o plugin correspondente no Studio.
2. Conferir no terminal: `rojo --version`.
3. Registrar a versão instalada antes de adicionar código.

Documentação oficial:
- [Instalação](https://rojo.space/docs/v7/getting-started/installation/)
- [Primeiro projeto e sincronização](https://rojo.space/docs/v7/getting-started/new-game/)

## Sincronizar com o Studio

No PowerShell, na pasta deste projeto:

```powershell
rojo serve default.project.json
```

Manter o terminal aberto. Abrir um Baseplate novo no Roblox Studio,
abrir o plugin Rojo e conectar a localhost, porta 34872.
Conferir a prévia das alterações antes de aceitar a sincronização.

Rojo envia alterações dos arquivos locais para o Studio.
Editar scripts gerenciados nos arquivos locais; não contar com exportação automática
de mudanças feitas no Studio para os arquivos. Git salva o histórico local;
GitHub hospeda uma cópia remota. Nenhum deles publica automaticamente o jogo.

## Verificação após instalar Rojo

```powershell
New-Item -ItemType Directory -Force build
rojo build default.project.json -o build/GalaxyMiningSimulator.rbxlx
```

O build valida a conversão, mas não substitui o teste no Studio.

1. Com Rojo conectado, verificar Client, Server e Shared nos destinos da tabela.
2. Conferir os scripts Bootstrap e suas mensagens no Output.
3. Alterar a mensagem no arquivo local e verificar sua atualização no Studio.
4. Iniciar Play e conferir Output; parar e remover o diagnóstico se for temporário.

Os scripts Bootstrap imprimem mensagens de diagnóstico do cliente e do servidor.

## Testar Terra Nova

Encerrar Play antes de sincronizar. Se o cenário não atualizar, reconectar o plugin
ao servidor Rojo deste projeto e conferir a prévia das alterações.
No Explorer, selecionar Workspace/TerraNova e pressionar F para enquadrar o cenário.
Em Play, conferir o nascimento no centro e caminhar até a loja à esquerda,
o hangar à direita e os depósitos à frente. Placas identificam as áreas.
Minérios respondem a cliques/toques e R2 no controle, com resistência validada no servidor.
O balcão da loja permite vender minérios usando E, toque ou X no controle.
Mochila, Créditos e equipamento aparecem na HUD. Perto dos expositores: F compra
Broca de Titânio (250 Créditos, poder 12); G compra Mochila Reforçada (150, capacidade 50).
As compras equipam imediatamente e não podem ser cobradas duas vezes.
Minérios recebem contorno ao mirar; golpes e extrações têm feedback visual.
HUD mostra Créditos, carga e poder com animações; o painel inferior mostra a
resistência do minério selecionado, e a Mochila abre em janela própria.
Depósitos renovam imediatamente após quebrar; golpes respeitam intervalo de 0,2 s.
Atalhos: L Loja, B Mochila, M Missões, P Ajustes; B no controle fecha janelas.
Design System 5.1 (visual noturno de galáxia), telas e roteiro de revisão visual: docs/UI-GUIDE.md.
A tela de carregamento fica em src/first (ReplicatedFirst).
Roteiro de teste e parâmetros provisórios: docs/MINING-TEST.md.
Conferir colisões, legibilidade das placas e ausência de novos erros no Output.

## Git e GitHub

Este projeto possui repositório Git próprio, separado do repositório pai em Documents.
Executar os comandos Git nesta pasta. O remoto será criado somente depois de
confirmar conta, nome e visibilidade com o usuário.

## Estado de validação

JSON e caminhos verificados. Rojo CLI 7.7.1 instalado em
`C:\Users\Usuário\Documents\Codex\tools\rojo\7.7.1` e adicionado ao PATH do usuário.
Plugin instalado por `rojo plugin install`. Build concluído com sucesso em
`build/GalaxyMiningSimulator.rbxlx`. Sincronização e execução dos diagnósticos
confirmadas pelo usuário. Cenário Terra Nova: build e XML verificados;
validação visual e circulação no Studio pendentes. Protótipo de mineração empacotado
com sucesso; inventário e venda passaram nos testes de regras, e todos os scripts
compilaram no Luau 0.745. Execução integrada e multiplayer ainda pendentes no Studio.

## Salvamento, missões e placares

O progresso (Créditos, carga, ferramentas, mochilas, pets, XP, missões, Fragmentos
e renascimentos) é salvo por `src/server/DataService.luau` com DataStore. O treino
de poder é por sessão, como define o GDD.

- Trava de sessão: só um servidor grava os dados de cada jogador por vez.
- Salva a cada 2 minutos, ao sair do jogo, ao renascer e ao fechar o servidor.
- Se não conseguir carregar, o jogador é desconectado com aviso, para não
  sobrescrever o progresso salvo com dados vazios.
- Para testar no Studio: publique o lugar e ative Game Settings > Security >
  "Enable Studio Access to API Services". Sem isso, o jogo roda em **modo de
  teste** (só memória) e mostra o aviso "MODO DE TESTE" no canto da tela.

Testes de regras, fora do Studio, com o Luau CLI:

```
luau tests/inventory.spec.luau
luau tests/progression.spec.luau
```

Missões de ORBI aparecem no rastreador da HUD e no menu Missões (tecla M). O
transmissor da missão 5 fica na Caverna Azul. Os placares ficam perto do ponto
de nascimento, o terminal do hangar fica na plataforma da Orion Scout, e o
renascimento fica no menu Renascer (tecla R).

## Guia, preferências, desempenho e analytics

- **Guia de objetivo:** um feixe e um marcador apontam para o objetivo da missão
  atual (ou para a Estação de Venda quando a mochila enche). Pode ser desligado
  em Ajustes.
- **Preferências salvas:** as opções de Ajustes são salvas com o progresso. O
  servidor aceita só as chaves de `ClientSettings` em `MiningConfig`, com valores
  verdadeiro/falso.
- **Efeitos do cenário:** desligar em Ajustes retira o céu galáctico, as
  animações e a decoração dos minérios, para aparelhos lentos.
- **Analytics** (Creator Hub > Analytics): funil do tutorial (primeira entrada
  e cada missão concluída) e economia de Créditos (fontes: vendas e missões;
  gastos: loja, pets e renascimento). Os eventos só aparecem com o jogo
  publicado e nunca interferem na partida.

