# Roadmap

## Etapa atual — Estrutura e ferramentas

- [x] Verificar o ambiente local.
- [x] Criar estrutura client/server/shared e configuração Rojo.
- [x] Registrar GDD e instruções de desenvolvimento.
- [x] Instalar e registrar a versão do Rojo CLI: 7.7.1.
- [x] Instalar o plugin Rojo correspondente no Studio via CLI.
- [x] Validar build com Rojo 7.7.1.
- [x] Validar sincronização com o Studio (confirmado pelo usuário).
- [x] Fazer teste mínimo de sincronização e execução, sem gameplay (mensagens cliente/servidor confirmadas).
- [ ] Confirmar conta, nome e visibilidade do GitHub com o usuário.
- [ ] Criar repositório remoto e enviar primeiro commit.

## Próximas etapas — Uma por vez, após definir cada entrega

1. Cenário Terra Nova: mapa ampliado (raio 250) com estilo cartunesco cósmico (cores vivas, ilhas, planetas, árvores de algodão-doce), instalações afastadas, caminhos de poeira estelar, portais, minas profundas e cenário gerado por tools/build_space_map.py (parte do commit af17020). Validação visual pendente no Studio.
2. Mineração por cliques e depósitos independentes por jogador: protótipo implementado; testes no Studio pendentes (docs/MINING-TEST.md).
3. Inventário por peso, venda e Créditos: implementados em memória; teste integrado no Studio pendente.
4. Ferramentas, mochilas e loja: 20 ferramentas, 20 Mochilas de Poeira Cósmica, 9 minérios e 6 pets em menu de loja; Minas Profundas no mapa (gerador em tools/build_space_map.py); teste no Studio pendente.
5. Estação de pets com OVNI em Terra Nova: 6 pets com bônus obtidos por gacha de ovos
   (chances visíveis, sorteio no servidor, primeiro pet garantido, abrir 3 e garantia
   de raro a cada 10); pets visíveis para todos.
   Fluxo de descoberta de Rokko e Nebbi e segundo espaço de criatura pendentes.
6. Cinco missões de ORBI, XP e níveis, Fragmentos Estelares, renascimento, placares,
   salvamento com DataStore e apresentação da Orion Scout no hangar: implementados
   (decisões no GDD, 08/11/2026); testes de regra em tests/progression.spec.luau;
   prêmio diário, venda automática (nível 5), contratos repetíveis,
   guia de objetivo, preferências salvas, modo de desempenho e analytics (funil
   e economia); validação no Studio pendente.
7. Interfaces: Design System 6.0 "Elegância Cósmica" (docs/UI-GUIDE.md): mundo noturno com
   céu galáctico, arte 3D própria para os 9 minérios, pets visíveis para todos,
   ferramentas na mão por família, interface escura com neon só como acento, botões 3D,
   tela de carregamento, HUD com cartão de próxima meta, prompts holográficos, placas
   de minério com golpes necessários, sons, mundo decorativo animado, Loja e menus
   refeitos; validação visual no Studio pendente. 
8. Testes em celular e multiplayer, balanceamento e Alpha 0.1.

## Fora do MVP

Outros planetas, pilotagem livre, evolução de criaturas, incubação,
monetização e sistemas avançados. Solari permanece no catálogo futuro.
Os números do GDD são hipóteses para testes, não compromissos definitivos.

