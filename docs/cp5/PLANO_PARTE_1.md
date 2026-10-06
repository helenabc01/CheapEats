# Plano de implementação — Parte 1

Branch: `feat/onboarding-endereco-perfil`.

Referência de escopo: [TAREFAS.md](TAREFAS.md), seção “Parte 1 — Onboarding + Endereço + Perfil”.

## Objetivo e direção visual

Apresentar a proposta do CheapEats, permitir escolher onde receber o pedido e reunir os dados do usuário com a economia acumulada. A experiência deve reforçar a ideia de **comparar o mesmo prato pelo preço total antes de pedir**.

Usar o design system existente em `lib/ui/theme.dart` e a Home como referência visual:

- Laranja para ações principais e seleção; teal para economia; fundos claros e cards brancos.
- Poppins nos textos e Inter nos valores, por meio de `AppText`; moeda sempre com `Fmt.brl`.
- Margens de 20–24 px, espaçamentos em múltiplos de 4, raios `AppTheme.radius` e `radiusSmall`, sombras discretas quando ajudarem a hierarquia.
- Uma ação principal evidente por etapa, ícones consistentes, títulos curtos e português direto e amigável.
- Layout que funcione em celulares estreitos e na moldura de celular do navegador, com rolagem quando necessário, respeito à área segura e ao teclado.
- Alvos de toque de pelo menos 48 px, rótulos acessíveis e estados identificáveis também por texto ou ícone. Verificar legibilidade e contraste, principalmente no card teal.

## 1. Onboarding e primeira abertura — 50–60 min

Arquivos: `lib/screens/onboarding_screen.dart` e ajuste pontual em `lib/screens/splash_screen.dart`.

Construir três páginas em `PageView`, cada uma com ícone grande sobre círculo `AppColors.orangeSoft`, título `AppText.h3` e explicação `AppText.body2`:

| Página | Título | Mensagem proposta | Ícone sugerido |
| --- | --- | --- | --- |
| 1 | Compare antes de pedir | Compare o mesmo prato no iFood, 99Food, Keeta, Rappi e Aiqfome. | Comparação |
| 2 | O preço real aparece | Veja o total com entrega, taxas e o melhor cupom disponível. | Recibo |
| 3 | Peça no mais barato | Escolha a melhor oferta e continue seu pedido no app de delivery. | Sacola com seta |

Manter o mesmo enquadramento nas três páginas, indicador de progresso na parte inferior, `Pular` como ação secundária e botão principal `Próximo`, substituído por `Começar` na última página. Permitir deslizar entre páginas; usar transições curtas e respeitar a preferência por reduzir animações. Em alturas pequenas ou com fonte ampliada, permitir rolar o conteúdo sem perder acesso às ações.

Ao pular ou começar:

1. Bloquear novos toques enquanto salva `onboarding_visto = true` em `SharedPreferences`.
2. Verificar se a tela continua montada e substituir a rota pelo login.
3. Se a gravação falhar, oferecer uma mensagem curta e permitir tentar novamente.

No Splash, ler a mesma chave durante a inicialização, preservando o carregamento do catálogo, o fallback offline e o tempo mínimo da animação. Flag ausente ou falsa leva ao onboarding; verdadeira leva ao login. Limpar a pilha para que “voltar” não reabra o Splash. A conclusão vale por instalação/perfil do navegador e continua valendo depois de sair da conta.

## 2. Endereço de entrega — 45–55 min

Arquivos: `lib/screens/address_screen.dart` e novo `lib/data/mock_addresses.dart`.

Criar cinco endereços fixos de São Paulo com label, rua, bairro, latitude e longitude. Reutilizar `AddressController.defaultAddress` para FIAP Paulista, evitando duas definições do mesmo endereço. Incluir Casa e Trabalho conforme os exemplos da tarefa e mais dois locais identificáveis.

Organização da tela:

1. AppBar “Endereço de entrega” e texto curto “Escolha onde receber seu pedido”.
2. Busca com ícone e opção de limpar; filtrar por nome, rua ou bairro, ignorando maiúsculas/minúsculas e acentos.
3. Ação “Usar minha localização atual”, com indicação discreta de que a localização é simulada no protótipo.
4. Lista de endereços com ícone de casa/trabalho/escola, nome em destaque e endereço completo abaixo. O selecionado recebe fundo suave, check e indicação “Selecionado”.

Ao tocar em um endereço, chamar `AppServices.address.select(endereco)` e voltar à tela anterior, sem uma segunda etapa de confirmação. Consultar o endereço atual pelo serviço, comparando campos estáveis, para manter o check correto ao reabrir a tela.

Na localização simulada, exibir carregamento por aproximadamente 1 segundo, impedir seleções concorrentes e então escolher FIAP Paulista. Se o usuário sair durante a espera, não alterar o endereço nem executar navegação depois de desmontar a tela.

Busca sem resultados mostra “Nenhum endereço encontrado” e uma ação para limpar a busca. O botão de localização permanece disponível. O endereço fica em memória, conforme o controller existente; salvar endereços, cadastrar novos locais e geolocalização real ficam fora desta entrega.

## 3. Integração com Home e mapa — 20–30 min

O topo da Home já observa `AppServices.address`. A implementação deve comprovar essa atualização após selecionar um endereço.

Dois pontos do código precisam de atenção para cumprir a atualização do mapa:

- `MapPreviewCard`, usado na Home e na Busca, lê o endereço, mas não escuta o controller. Fazer um ajuste localizado em `lib/widgets/map_preview_card.dart`: observar o endereço e atualizar a câmera quando suas coordenadas mudarem. Apenas reconstruir `initialCenter` não garante mover um mapa já montado; usar uma chave baseada nas coordenadas ou controle explícito da câmera.
- `MapScreen` tem `initialCameraFit` além de `initialCenter`. Validar que o enquadramento inicial realmente coloca o endereço escolhido no centro visível; ajustar pontualmente `lib/screens/map_screen.dart` se o enquadramento por limites sobrepor esse centro.

Esses ajustes são a exceção de integração aos arquivos principais da Parte 1 e devem ficar pequenos e revisáveis. Evitar alterações nas telas da Parte 2 e nos controllers de pedidos/favoritos da Parte 3.

As distâncias e taxas do catálogo são simuladas e atualmente fixas. Trocar o endereço deve atualizar seu texto e a posição/câmera dos mapas; não prometer recálculo de frete ou distância nesta entrega.

## 4. Perfil — 45–55 min

Arquivo: `lib/screens/profile_screen.dart`.

Montar uma página com rolagem e a mesma linguagem visual da Home:

- Cabeçalho com avatar laranja e iniciais, nome e e-mail da sessão. Para visitante, mostrar “Visitante” e “Entrou sem conta”. Tratar nomes longos e nomes com uma única palavra sem quebrar o layout.
- Card teal “Minha economia”, com valor de `AppServices.orders.totalSavings` em destaque e quantidade de pedidos com singular/plural. Com zero pedidos, mostrar `R$ 0,00` e uma mensagem acolhedora, como “Sua economia começa no próximo pedido”. Os valores vêm do serviço, sem totais inventados.
- Menu em card branco, com `ListTile`, ícones e setas: Favoritos, Endereços, Mapa, Cupons e Sobre o CheapEats. Usar as rotas existentes; Favoritos e Cupons poderão permanecer provisórios até as entregas dos outros integrantes.
- “Sobre” abre diálogo com a proposta do app, versão `1.0.0` conforme `pubspec.yaml`, indicação de protótipo acadêmico e os cinco integrantes conforme o README. Garantir leitura/rolagem em telas pequenas.
- `DataSourceChip` no rodapé e botão “Sair” com menor destaque que o card de economia.

Observar sessão e pedidos com `ListenableBuilder`, para refletir alterações sem reabrir a aba. Reaproveitar a hierarquia do card de comparação, mantendo suas cores dentro dos tokens existentes.

“Sair” chama `AppServices.session.logout()` e navega ao login limpando a pilha. O botão voltar não deve recuperar o Perfil ou a Home da sessão encerrada. A flag do onboarding permanece gravada.

## 5. Validação e entrega — 30–40 min

Testes de comportamento que protegem os fluxos novos:

- Inicialização com flag ausente/falsa e verdadeira; persistência ao pular e ao começar.
- Navegação pelas três páginas e prevenção de conclusão duplicada durante a gravação.
- Busca de endereços, resultado vazio, seleção, check ao reabrir e localização simulada; saída da tela durante a espera.
- Endereço refletido na Home e nas coordenadas/câmera dos mapas após a troca.
- Perfil da conta demo e do visitante, economia acompanhando pedidos, rotas do menu e logout com pilha limpa.

Preparar `SharedPreferences.setMockInitialValues` nos testes. O teste atual de fluxo principal em `test/widget_test.dart` espera Splash → Login: definir explicitamente o onboarding como visto nesse cenário e criar testes separados para a primeira abertura. Manter fonte sem download, catálogo offline e tiles desativados nos testes, seguindo a infraestrutura atual.

Executar `flutter analyze` e `flutter test`. Fazer revisão visual no navegador com viewport estreito, teclado aberto, textos longos e fonte ampliada; verificar que não há overflow, controles cortados ou espaçamentos inconsistentes. Testar primeira abertura em perfil limpo e reabertura no mesmo perfil.

Ao concluir e validar a implementação, atualizar somente o status da Parte 1 no README e registrar prints das novas telas em `docs/prints/`. Preservar as alterações preexistentes nos arquivos gerados de plugins das plataformas, que já estavam modificados antes da criação da branch.

Commits sugeridos para a implementação:

1. `feat: adiciona onboarding na primeira abertura`
2. `feat: adiciona selecao de endereco e sincroniza mapas`
3. `feat: implementa perfil e resumo de economia`
4. `test: valida os fluxos da parte 1`
5. `docs: atualiza status e demonstracao da parte 1`

Estimativa total: **3h10–4h**, considerando o ambiente Flutter já funcional.

## Checklist de aceite

- [ ] Três páginas coerentes com a proposta e o tema do app.
- [ ] Pular e Começar salvam a conclusão e levam ao login.
- [ ] Onboarding aparece somente na primeira abertura.
- [ ] Busca, seleção e localização simulada funcionam com feedback claro.
- [ ] Home e prévias do mapa refletem a troca; mapa completo abre no endereço escolhido.
- [ ] Perfil mostra sessão, economia e quantidade de pedidos corretamente.
- [ ] Todos os itens do menu navegam; Sobre apresenta versão e integrantes.
- [ ] Sair encerra a sessão e impede voltar às telas anteriores.
- [ ] Layout revisado em telas pequenas e com fonte ampliada.
- [ ] Análise e testes passam; documentação e prints refletem a entrega.
