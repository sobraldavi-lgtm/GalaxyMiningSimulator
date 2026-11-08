# Instruções de desenvolvimento

- Ler docs/GDD.md e ROADMAP.md antes de alterar o projeto.
- Trabalhar em português, em etapas pequenas, explicando decisões e validações.
- Fase atual: mineração, inventário, venda e primeiras compras autorizadas; salvamento pendente.
- Por decisão do usuário, depósitos renovam imediatamente após quebrar; manter intervalo de 0,2 s entre golpes do GDD.
- O cenário estático fica em src/world/terra-nova.project.json e sincroniza em Workspace/TerraNova.
- Editar o cenário gerenciado nos arquivos para preservar as alterações no Rojo.
- Preservar mineração por cliques, viagens em naves e criaturas alienígenas colecionáveis.
- MVP: Terra Nova, três criaturas, cinco missões, sem monetização.
- Cliente: entrada e apresentação; servidor: regras, recompensas, compras e dados.
- Nunca confiar no cliente para saldo, dano, inventário, bônus ou progresso.
- Não armazenar tokens, cookies Roblox, credenciais ou dados pessoais no Git.
- Scripts locais: *.client.luau; servidor: *.server.luau; módulos: *.luau.
- Conteúdo em src/shared é replicado ao cliente; não colocar segredos nele.
- Não alterar o repositório Git pai em Documents. Executar Git na raiz deste projeto.
- Pedir confirmação antes de criar repositório remoto, publicar ou mudar sua visibilidade.
- Verificar JSON e caminhos; quando Rojo estiver instalado, executar rojo build.
- Validar alterações de comportamento no Studio e informar o que foi e não foi testado.
- Não implementar sistemas futuros ou mudar o balanceamento sem discutir o escopo.

