# Galaxy Mining Simulator

Game Design Document — Versão 2.0 · Planejamento consolidado

(Conceito definido)

O **Galaxy Mining Simulator** será um jogo de mineração, exploração e coleção de criaturas alienígenas no Roblox. O jogador começará em uma pequena estação espacial, minerará recursos por cliques, comprará equipamentos, descobrirá criaturas e viajará em naves para novos planetas.

A principal proposta é combinar três experiências: **a satisfação de evoluir em um Simulator, a descoberta de novos mundos e a criação de uma equipe de criaturas alienígenas**.



## 1. Identidade definitiva

| Elemento | Decisão |
|--------|--------|
| Nome | Galaxy Mining Simulator |
| Plataforma | Roblox |
| Gênero | Mining Simulator, coleção e exploração |
| Mineração | Cliques para extrair minerais |
| Viagens | Naves espaciais |
| Companheiros | Criaturas alienígenas colecionáveis |
| Multiplayer | Exploração individual em servidores compartilhados |
| Direção artística | Ficção científica cartunizada, low-poly |
| Progressão | Equipamentos, mochila, criaturas, missões e planetas |
| Monetização | Nenhuma compra necessária para progredir; sem monetização no MVP |

### Fantasia do jogador

O jogador começa como um minerador espacial desconhecido e evolui até se tornar um grande explorador galáctico, comandando uma equipe de criaturas e descobrindo minerais extraordinários.

O nome *Galaxy Mining Simulator* será provisório até verificarmos a disponibilidade e decidirmos a identidade visual definitiva.

## 2. História do universo

A galáxia de **Asterion** contém planetas ricos em minerais e criaturas que desenvolveram uma conexão natural com a energia desses recursos.

A organização **Orion Mining Corporation** contrata exploradores para estudar os planetas e coletar minerais. Durante as primeiras expedições, os jogadores descobrem que certas criaturas conseguem localizar, transformar e potencializar minerais.

O assistente robótico **ORBI** acompanha o jogador e apresenta as primeiras missões.

A narrativa será contada por diálogos curtos, descobertas e eventos ambientais, sem interromper frequentemente a mineração.

## 3. Loop principal de gameplay

O ciclo central será rápido, compreensível e ampliado pelas criaturas e pela exploração espacial.

Uma sessão de aproximadamente 5 a 10 minutos deverá oferecer oportunidades de avanço. Não exigiremos que o jogador permaneça conectado continuamente para preservar recompensas.

---

# 4. Sistema de mineração por cliques

O jogador se aproxima de um minério e clica ou toca para aplicar dano de mineração. Cada depósito possui resistência, e cada ferramenta possui poder de extração.

A regra inicial será:

\[
\text{Cliques necessários}=\left\lceil\frac{\text{Resistência}}{\text{Poder total}}\right\rceil
\]

O poder total considera a ferramenta e os bônus das criaturas equipadas.

### Exemplo

Um cristal com 60 pontos de resistência, minerado com uma ferramenta de poder 10, exige seis cliques sem bônus adicionais.

Simulador de balanceamento da mineração

Resistência do minério

> **Controle deslizante**
>
> Valor atual indisponível.
>
> **Intervalo:** 10 a 300
>
> **Incremento:** 10

Poder da ferramenta

> **Controle deslizante**
>
> Valor atual indisponível.
>
> **Intervalo:** 5 a 100
>
> **Incremento:** 5

Bônus das criaturas **%**

> **Controle deslizante**
>
> Valor atual indisponível.
>
> **Intervalo:** 0 a 100
>
> **Incremento:** 5

---

Poder total

Cliques necessários

Modelo de balanceamento do GDD. Os valores ainda poderão mudar após os testes de jogabilidade.

### Regras definidas

- Desde o início da sessão, cliques ou toques no cenário e golpes válidos por interação direta ou R2 contam para o treino. Cada gesto aceito conta uma vez, com intervalo compartilhado de 0,2 segundo. A cada 10 ações, o jogador ganha +1 de poder, até +3 por sessão. O ganho soma ao poder do equipamento após o bônus de Lumini e acompanha o jogador quando ele troca de ferramenta. Interações na interface, inclusive o botão móvel Minerar, não contam para o treino.

- Um clique válido aplica um golpe ao minério selecionado.
- Haverá um intervalo mínimo de 0,2 segundo entre golpes aceitos, para manter uma velocidade previsível e não recompensar ferramentas de clique automático.
- O servidor validará distância, ferramenta, intervalo e disponibilidade do depósito.
- A extração terá efeitos visuais e sonoros, além de uma barra de resistência.
- Quando a mochila estiver cheia, o jogador deverá vender ou armazenar os minerais antes de continuar coletando.
- Cada jogador terá progresso independente nos depósitos, evitando disputas pela mesma rocha.

A mineração deverá ser acessível por mouse, toque e controle, sem exigir cliques excessivamente rápidos.

## 5. Minérios e economia

Teremos duas moedas: **Créditos**, obtidos principalmente com vendas, e **Fragmentos Estelares**, recebidos por missões e descobertas especiais.

Os minerais também poderão ser utilizados diretamente para construir ou aprimorar equipamentos no futuro.

### Minérios do primeiro planeta

| Minério | Resistência | Venda | Peso |
|--------|--------|--------|--------|
| Ferro espacial | 10 | 5 créditos | 1 |
| Cobre lunar | 25 | 12 créditos | 2 |
| Cristal azul | 60 | 30 créditos | 3 |

A mochila utilizará capacidade por peso, e não apenas por quantidade de itens. Isso tornará relevante escolher quais minerais transportar.

### Equipamentos iniciais

| Ferramenta | Poder | Preço |
|--------|--------|--------|
| Extrator Básico | 5 | Gratuito |
| Broca de Titânio | 12 | 250 créditos |
| Laser Mk-I | 25 | 1.000 créditos |
| Laser Mk-II | 50 | 4.000 créditos |
| Perfurador de Plasma | 100 | 15.000 créditos |

| Mochila | Capacidade | Preço |
|--------|--------|--------|
| Mochila Inicial | 20 | Gratuita |
| Mochila Reforçada | 50 | 150 créditos |
| Mochila Espacial | 120 | 750 créditos |
| Cargueiro Compacto | 300 | 3.000 créditos |

O objetivo é que a primeira melhoria de mochila possa ser comprada após poucas viagens de mineração, enquanto ferramentas mais avançadas exigirão planejamento.

---

# 6. Criaturas alienígenas

Este será um dos principais diferenciais do jogo.

As criaturas não serão apenas acessórios visuais. Cada espécie possuirá uma característica que influencia a mineração ou a exploração.



**Lumini**

(Comum)

Criatura azul associada aos cristais. Concede +10% de poder de mineração.



**Rokko**

(Incomum)

Criatura rochosa que concede +15% de poder contra minérios metálicos.



**Nebbi**

(Raro)

Criatura flutuante que concede +10% de capacidade de mochila.



**Solari**

(Épico)

Criatura energética que concede +25% de poder de mineração.

### Como obter criaturas?

No MVP, os jogadores poderão descobrir criaturas por meio de **missões, exploração e resgates garantidos no OVNI**, sem sorteios aleatórios. A primeira oferta de Terra Nova é Lumini por 75 Créditos. Depois do resgate, o terminal permite equipar ou guardar Lumini.

O sistema de incubação de ovos alienígenas ficará para uma expansão futura, com regras e probabilidades claramente apresentadas caso seja adotado.

### Regras dos companheiros

O jogador começará com um espaço para criatura equipada e poderá desbloquear até três espaços por meio da progressão.

Os bônus de poder serão somados e terão um limite de +100% no MVP. Bônus de capacidade serão calculados separadamente.

As criaturas acompanharão visualmente o jogador, mas não terão colisão física com ele ou com os demais participantes.

### Evolução de criaturas

A evolução por experiência será uma funcionalidade futura. Na primeira versão, as criaturas terão bônus fixos para facilitar os testes de balanceamento.

---

# 7. Naves espaciais e viagens


As naves serão o principal meio de transporte entre planetas e parte importante da identidade do Galaxy Mining Simulator.

### Funcionamento

O jogador irá até o hangar, selecionará um destino no mapa galáctico e embarcará em uma nave. Uma sequência curta de decolagem e viagem fará a transição para o planeta escolhido.

No MVP, a nave será um sistema de transporte com animação, não um veículo pilotável. Isso permitirá concentrar o desenvolvimento na mineração e nas criaturas.

| Nave | Função | Disponibilidade |
|--------|--------|--------|
| Orion Scout | Transporte inicial | MVP |
| Stellar Cargo | Maior capacidade logística | Expansão |
| Nova Explorer | Exploração avançada | Expansão |
| Eclipse Voyager | Nave de longa distância | Expansão |

Futuramente, poderemos adicionar personalização de naves, melhorias de velocidade e exploração de regiões espaciais.

## 8. Planetas e progressão galáctica



**Terra Nova — Planeta inicial**

(MVP)

Minerais básicos, hangar, loja, cavernas, missões e primeiras criaturas. Ambiente seguro para aprender as mecânicas.

---



**Vulkar — Planeta vulcânico**

Expansão 0.2

Minérios resistentes, proteção térmica e criaturas associadas ao calor.

---



**Cryon — Planeta congelado**

Expansão 0.3

Cavernas geladas, rotas de exploração e equipamentos especiais.

---



**Nebulon — Planeta misterioso**

Expansão futura

Cristais prismáticos, criaturas raras e ruínas que revelam a história de Asterion.

### Desbloqueio de planetas

Novos mundos exigirão uma combinação de nível, missão concluída e tecnologia de nave.

Isso impede que o acesso dependa exclusivamente de acumular grandes quantidades de créditos.

---

# 9. Sistema de progressão

O jogador evoluirá em quatro dimensões:

| Sistema | Como evolui | O que desbloqueia |
|--------|--------|--------|
| Nível de explorador | Mineração e missões | Novas atividades |
| Ferramentas | Compra com créditos | Minerais mais resistentes |
| Criaturas | Descoberta e coleção | Bônus de mineração |
| Licença planetária | Missões e pesquisa | Novos planetas |

### Primeiros níveis

| Nível | XP total necessário | Recompensa |
|--------|--------|--------|
| 1 | 0 | Extrator Básico |
| 2 | 100 | Primeira missão de exploração |
| 3 | 250 | Acesso à caverna azul |
| 4 | 450 | Segundo espaço de criatura |
| 5 | 700 | Missão do transmissor |

Esses valores são metas iniciais de balanceamento, não valores definitivos.

## 10. Missões e narrativa

O robô ORBI será o guia inicial.



**ORBI — Assistente de exploração**

Ajuda o jogador a aprender mineração, inventário, criaturas e viagens espaciais.

---

**Campanha introdutória — Terra Nova**

1. **Primeiro contato:** minerar cinco unidades de ferro espacial.
2. **Primeira venda:** vender recursos na estação.
3. **Tecnologia aprimorada:** comprar a primeira melhoria.
4. **Amigo alienígena:** descobrir e equipar Lumini.
5. **Sinal desconhecido:** encontrar a caverna azul e reativar o transmissor.

Cada missão apresentará uma mecânica nova e oferecerá recompensas úteis.

---

# 11. Interface do jogador

A interface será projetada para computador, tablet, celular e controle.

1.250 créditos

3 fragmentos

Nível 4 · Explorador

Cristal Azul · 36/60

Mochila 18/50

Minerar

Criaturas

Itens

Wireframe conceitual da HUD. A disposição final será ajustada após testes em diferentes telas.

### Telas previstas

| Interface | Conteúdo |
|--------|--------|
| HUD | Créditos, XP, mochila e mineração |
| Loja | Ferramentas e mochilas |
| Inventário | Recursos e equipamentos |
| Criaturas | Coleção, bônus e equipe equipada |
| Missões | Objetivos e recompensas |
| Hangar | Seleção de nave e destinos |
| Configurações | Áudio, efeitos e controles |

---

# 12. Balanceamento da economia

A economia precisa permitir progresso frequente sem tornar todas as melhorias triviais.

### Metas iniciais de experiência

| Marco | Tempo estimado |
|--------|--------|
| Primeira mineração | Até 1 minuto |
| Primeira venda | 2–3 minutos |
| Primeira mochila nova | 4–6 minutos |
| Primeira ferramenta nova | 8–12 minutos |
| Primeira criatura | 10–15 minutos |
| Conclusão do tutorial | 15–25 minutos |

Esses tempos são hipóteses para testes com jogadores, não garantias.

### Regras econômicas

- As primeiras melhorias deverão produzir diferenças perceptíveis.
- Criaturas não substituirão completamente ferramentas.
- Não haverá penalidade por ficar offline.
- A mineração não exigirá velocidade extrema de cliques.
- Nenhum item essencial dependerá de Robux.
- Os preços serão ajustados com base em testes reais.

### Simulador de uma viagem de mineração

**Planejamento de carga**

---

Valor da carga

## créditos

Peso da carga

## /

---

# 13. Requisitos do MVP — Alpha 0.1

A primeira versão jogável será limitada ao planeta Terra Nova. Ela deverá demonstrar o ciclo completo de mineração, venda, melhoria e coleção.

---

**Progresso dos requisitos** /

### Critérios de aceitação

O MVP estará pronto quando um novo jogador conseguir entrar, completar o tutorial, minerar recursos, vendê-los, comprar equipamentos, descobrir e equipar uma criatura e retornar posteriormente com seus dados preservados.

A nave inicial deverá aparecer no hangar e apresentar o sistema de viagens, mas a exploração de outros planetas ficará para atualizações posteriores.

---

# 14. Arquitetura técnica planejada

Ainda não começaremos a programar. Esta é apenas a organização prevista para os sistemas.

Workspace
├── TerraNova
│   ├── MiningAreas
│   ├── OreDeposits
│   ├── Hangar
│   └── NPCs
└── WorldDecorations

ReplicatedStorage
├── Remotes
├── SharedModules
└── Assets

ServerScriptService
├── MiningService
├── EconomyService
├── InventoryService
├── CreatureService
├── QuestService
└── DataService

StarterGui
├── HUD
├── ShopUI
├── InventoryUI
├── CreaturesUI
└── QuestsUI

StarterPlayer
└── StarterPlayerScripts

O servidor controlará as recompensas, os saldos, as compras, os bônus das criaturas e o salvamento. O cliente ficará responsável por entrada, animações, efeitos e apresentação das interfaces.

---

# 15. Cronograma de produção

| Semana | Entrega |
|--------|--------|
| 1 | Cenário Terra Nova e estrutura do projeto |
| 2 | Mineração por cliques e depósitos |
| 3 | Mochilas, inventário e venda |
| 4 | Ferramentas e loja |
| 5 | Criaturas e seus bônus |
| 6 | Missões, ORBI e progressão |
| 7 | Interfaces, nave e salvamento |
| 8 | Testes, balanceamento e Alpha 0.1 |

Esse cronograma é uma meta inicial. Se algum sistema precisar de mais testes, ajustaremos o prazo em vez de comprometer a qualidade.

## 16. Expansões futuras

**Alpha 0.2 — Vulkar**

Segundo planeta, novos minerais, criaturas e viagem espacial funcional entre mundos.

---

**Alpha 0.3 — Cryon**

Planeta congelado, novas missões e equipamentos de exploração.

---

**Beta 0.5 — Evolução alienígena**

Experiência para criaturas, habilidades especiais e coleção ampliada.

---

**Versão 1.0 — Galáxia de Asterion**

Mais planetas, exploração cooperativa, personalização de naves e novas descobertas.

---

# 17. Decisões finais do projeto

**GDD v2.0 — Direção definida**

| Sistema | Decisão |
|--------|--------|
| Mineração | Cliques, com limite de frequência |
| Viagens | Naves espaciais |
| Companheiros | Criaturas alienígenas |
| Aquisição inicial | Exploração e missões |
| Moeda principal | Créditos |
| Moeda especial | Fragmentos Estelares |
| Primeiro planeta | Terra Nova |
| Primeira versão | Alpha 0.1 |
| Monetização no MVP | Nenhuma |
| Desenvolvimento | Roblox Studio e Luau |

**O Galaxy Mining Simulator agora possui uma direção de design consolidada.** Os números de economia, os tempos de progressão e os bônus das criaturas são parâmetros iniciais que deverão ser validados em testes.

O próximo passo será transformar este GDD em um **documento de produção**, com o mapa de Terra Nova, as telas do jogo, o catálogo de recursos e as tarefas de desenvolvimento organizadas por prioridade — ainda sem escrever código.



## Nota de migração para o repositório — 04/11/2026

Fonte: GDD v2.0 da conversa “Saudação informal amigável”.
Imagens de busca e controles interativos não são ativos do projeto.
Os trechos de simuladores e de progresso acima vieram sem controles funcionais;
nenhum sistema foi implementado.

Escopo operacional do MVP: Terra Nova; mineração por cliques; inventário por peso;
venda e loja; três criaturas (Lumini, Rokko e Nebbi); cinco missões de ORBI;
interfaces; progressão; salvamento; apresentação da Orion Scout no hangar.
Solari permanece no catálogo para expansão. Não haverá outros planetas jogáveis no MVP.

Pendências para detalhar antes de implementar: distância definitiva de mineração,
arredondamento da capacidade com bônus,
recompensas e XP por ação/missão, desbloqueio do terceiro espaço de criatura
e fluxo exato de descoberta de Rokko e Nebbi.
Não inventar esses valores durante a criação da estrutura.

## Decisões durante o protótipo

- Por solicitação do usuário, remover a recuperação de 10 segundos: depósitos
  renovam imediatamente após quebrar. O intervalo mínimo de 0,2 s entre golpes permanece.
- Alcance provisório da mineração: 18 studs; confirmar em testes no Studio.
- Primeiras compras implementadas: Broca de Titânio (250 Créditos, poder 12)
  e Mochila Reforçada (150 Créditos, capacidade 50), equipadas automaticamente.
- Inventário, Créditos e equipamento são mantidos apenas durante a sessão;
  salvamento e os demais equipamentos do catálogo continuam pendentes.

## Decisões de progressão — 08/11/2026

Escolhidas com o usuário como **hipóteses para testes** (centralizadas em
`src/shared/MiningConfig.luau`, ajustar após testes com jogadores):

- XP: 1 por minério extraído e até 10 por venda (limitado à quantidade de
  minérios vendidos, para que vender um por vez não renda XP extra). Níveis 1–5 seguem a
  tabela do GDD (0/100/250/450/700); depois do 5, +300 XP por nível.
- Missões de ORBI (§10) em sequência, com recompensas de 50, 75, 100, 150 e 250
  Créditos e 1 Fragmento Estelar cada. A missão 5 (transmissor da caverna azul)
  exige nível 3, que é o "acesso à caverna azul" da tabela de níveis.
- O "segundo espaço de criatura" do nível 4 continua pendente (um pet por vez).
- Renascimento (pedido do usuário, fora do GDD original): custa 50.000 × (n + 1)
  Créditos; reinicia Créditos, carga, ferramentas, mochilas e treino; mantém pets,
  nível, XP, missões e Fragmentos; cada renascimento dá +25% nas vendas.
- Placares: Top 10 de Créditos ganhos em vendas e de renascimentos (OrderedDataStore),
  além de leaderstats (Créditos, Nível, Renasc.) na lista de jogadores.
- Salvamento com DataStore e trava de sessão; o treino de poder continua por sessão.
- Hangar: apresentação da Orion Scout e do mapa galáctico; viagens continuam fora do MVP.

## Decisão: pets por gacha de ovos — 08/11/2026

Por decisão do usuário, pets passam a ser obtidos **apenas em ovos** no OVNI,
substituindo o resgate direto. Isso altera a regra anterior "sem sorteios
aleatórios" do MVP. Regras mantidas para proteger o jogador:

- Ovos custam **Créditos** (sem Robux, sem monetização no MVP).
- As **chances de cada pet são sempre mostradas** no cartão do ovo.
- O sorteio acontece **só no servidor**; o cliente apenas anima o resultado.
- Quem ainda não tem pets e abre um ovo que contém Lumini recebe **Lumini**, para
  que a missão "Amigo alienígena" não dependa de sorte.
- Pet repetido devolve **50%** do preço do ovo; pet novo é equipado se for melhor.

Ovos iniciais (hipóteses para testes, em `MiningConfig.Eggs`):

| Ovo | Preço | Chances |
| --- | --- | --- |
| Ovo Estelar | 75 | Lumini 70% · Rokko 25% · Nebbi 5% |
| Ovo Cometa | 600 | Rokko 40% · Nebbi 35% · Zapi 20% · Glacio 5% |
| Ovo Supernova | 2.500 | Zapi 45% · Glacio 35% · Solari 20% |

Raridades: Lumini Comum, Rokko Incomum, Nebbi e Zapi Raros, Glacio e Solari Épicos.
Se ovos forem vendidos por Robux no futuro, as regras do Roblox exigem mostrar as
chances antes da compra (já atendido) e a decisão deve ser revisada à parte.

### Gacha: abrir 3 e garantia de raro — 08/11/2026 (aprovado pelo usuário)

- **Abrir 3:** abre 3 ovos de uma vez pelo preço × 3 (sem desconto).
- **Garantia de raro:** cada ovo tem um contador salvo. Depois de 9 aberturas
  seguidas desse ovo sem pet Raro ou Épico, a 10ª é garantida Raro+, sorteada
  entre os Raro+ do próprio ovo pelas chances dele. Qualquer Raro+ zera o contador.
  A loja mostra "Raro em N" em cada ovo; o Ovo Supernova só tem Raro+ ("SEMPRE RARO+").

