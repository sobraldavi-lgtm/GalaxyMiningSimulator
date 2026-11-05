# Mineração — protótipo de interação

Etapa atual: mineração por cliques integrada ao inventário e à venda. Sem salvamento ainda.
Extrator Básico implícito com poder 5; o equipamento visual virá depois.
Uma extração concluída concede uma unidade à mochila; dados duram apenas esta sessão.

## Parâmetros

Do GDD: resistências ferro 10, cobre 25, cristal 60; poder 5; intervalo mínimo 0,2 s.
Provisório para teste: alcance 18 studs (centro da peça).
Por decisão do usuário, o depósito renova imediatamente após quebrar.
O intervalo de 0,2 s entre golpes continua valendo.
Cada uma das nove rochas tem resistência independente para cada jogador.
Os depósitos permanecem visíveis para todos; a HUD mostra a conclusão da extração
e o próximo golpe já inicia um novo ciclo com resistência completa.
Os parâmetros provisórios podem mudar após o teste de circulação e mineração.

## Verificação no Studio

1. Parar Play, sincronizar Rojo e iniciar Play novamente.
2. Chegar perto do ferro: clicar na base ou amostra duas vezes. Esperado: 5/10, depois 0/10.
3. Cobre: cinco golpes; cristal: doze golpes. HUD mostra a resistência restante.
4. Após quebrar o ferro, clicar novamente: a resistência deve mostrar 5/10 imediatamente,
respeitando apenas o intervalo de 0,2 s. A cada dois golpes, recebe uma unidade com o extrator básico.
5. Tentar de longe e por trás de obstáculo: servidor recusa o golpe.
6. Clicar muito rápido: servidor aceita no máximo um golpe a cada 0,2 s.
7. Testar com dois jogadores: o progresso de um não altera o do outro.
8. Testar toque no emulador móvel (arrastar câmera não deve minerar) e R2 com controle.
9. Conferir Output sem novos erros.

Build Rojo verifica empacotamento. Todos os scripts passaram na compilação Luau 0.745.
Testes de execução no Studio, multiplayer, toque e controle permanecem pendentes.

## Mochila e venda

Capacidade inicial: 20 de peso. Ferro: peso 1, venda 5; cobre: peso 2, venda 12;
cristal: peso 3, venda 30 Créditos. Cada depósito concluído concede uma unidade.
Não há coleta se o próximo minério ultrapassar a capacidade; a resistência é preservada.
A venda vende todo o conteúdo e mantém os Créditos no servidor durante a sessão.
Renascimento mantém a mochila; sair do servidor ou parar o teste reinicia os dados.

1. Concluir um ferro: mochila 1/20 e quantidade de ferro 1.
2. Ir ao balcão na loja à esquerda e segurar E (ou tocar no prompt / usar X no controle).
3. Esperado: mochila 0/20 e saldo 5 Créditos; vender de novo não aumenta o saldo.
4. Coletar 6 cristais: 18/20; outro cristal não cabe, mas um cobre completa 20/20.
5. Vender essa carga: ganho de 192 Créditos.
6. Testar fora do alcance, morto e com dois jogadores: inventários e vendas independentes.

Testes de regras em tests/inventory.spec.luau: capacidade exata, rejeição de excesso,
minério inválido, peso, preços, cópia de estado, venda repetida e isolamento passaram.
Executados no Luau 0.745 com módulos concatenados sem alteração de lógica, para
contornar a resolução de módulos em caminhos Windows com caracteres acentuados.

## Primeiras melhorias

No balcão: E vende. Perto do expositor da broca, segurar F compra Broca de Titânio
por 250 Créditos e equipa poder 12. No expositor da mochila, segurar G compra
Mochila Reforçada por 150 Créditos e aumenta a capacidade para 50.
Toque: usar os prompts na tela; controle: X vende, Y compra broca, B compra mochila.
Alcance provisório de compra: 10 studs do expositor; venda: 12 studs do balcão.

1. Sem Créditos, tentar comprar: deve informar saldo insuficiente sem mudar equipamento.
2. Juntar 150 Créditos, comprar mochila: capacidade 50, conteúdo preservado e desconto único.
3. Juntar 250 Créditos, comprar broca: poder 12, nome atualizado na HUD.
4. Com a broca: ferro exige 1 golpe, cobre 3 e cristal 5 (sem bônus).
5. Tentar comprar a mesma melhoria novamente: não cobra e não reaplica o efeito.
6. Tentar longe dos expositores: servidor recusa a compra.

Testes adicionais de compra e compilação de todos os scripts passaram no Luau 0.745.
Build Rojo passou. Prompts, ciclo de extração sem espera e efeitos das compras ainda
precisam ser validados em execução no Studio. Equipamentos são representados pelo
nome e efeito na HUD; modelos de ferramentas na mão ainda não foram adicionados.

## Clareza visual e controles

- Contorno azul: minério selecionado dentro do alcance; laranja: fora de alcance.
  O contorno não garante um golpe aceito: o servidor ainda verifica obstáculos e mochila.
- A barra de resistência anima a mudança e guarda a resistência individual de cada rocha
  durante a sessão. Trocar de alvo não deve mostrar a resistência de outra rocha.
- Golpe aceito mostra dano flutuante. Extração concluída mostra +1 e o nome do minério.
  Esse efeito só aparece após confirmação do servidor e some automaticamente.
- Mochila tem barra de peso, aviso CHEIA e botão Detalhes/Recolher.
  Em telas pequenas inicia recolhida; a escolha manual permanece ao redimensionar.

Verificar no Studio: mirar perto/longe; trocar entre ferro e cristal após um golpe;
completar duas extrações seguidas sem espera; encher/vender a mochila; recolher/expandir
o painel; testar janela pequena, emulador móvel e controle. Verificar alinhamento do retículo.
Confirmar que o painel recolhido ainda mostra mensagens de venda e compra.
Compilação Luau e build Rojo passaram; inspeção visual e testes em dispositivos pendentes.
