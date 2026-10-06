# CP5 — Divisão de tarefas

O protótipo já tem a **base completa** e o **fluxo principal funcionando**: Splash → Login → Início → Busca/Mapa → Restaurante → Comparação → abrir o app de delivery, comparando **iFood, 99Food, Keeta, Rappi e Aiqfome**. Faltam **3 partes independentes**, uma por integrante. Cada parte tem os arquivos e as rotas já criados, com telas provisórias ("Em construção") e comentários `TODO(PARTE-N)` explicando o que fazer.

> Cada parte é pensada para **3 a 5 horas** de trabalho. Mexa só nos arquivos da sua parte e não vai haver conflito com ninguém.

## ✅ O que já está pronto

- [x] Design system do CP4 no `lib/ui/theme.dart` (cores e fontes do Figma, botões, campos, cards, abas)
- [x] Dados simulados realistas: 13 restaurantes com coordenadas, 71 pratos, 264 preços, 12 cupons e 5 apps (`assets/data/cheapeats_mock.json`)
- [x] Regra de preço testada: `PriceCalculator` (itens + entrega + taxa − melhor cupom, pedido mínimo, empate, cupom de 1º pedido)
- [x] Supabase: `schema.sql`, `seed.sql`, leitura do catálogo e modo offline automático
- [x] Navegação com rotas nomeadas e as 4 abas (Início, Busca, Pedidos, Perfil)
- [x] Telas: Splash, Login (com conta demo), Início, Busca, **Mapa interativo** (com prévia na Início e na Busca), Restaurante e Comparação + redirecionamento para o app
- [x] Testes automatizados (`flutter test`) e análise sem avisos (`flutter analyze`)
- [x] README com instruções, decisões técnicas e roteiro da demo

## ⏳ O que falta

| Parte | Responsável | Tema | Arquivos principais |
| --- | --- | --- | --- |
| [1](#parte-1--onboarding--endereço--perfil) | **Henrique** | Onboarding + Endereço + Perfil | `onboarding_screen.dart`, `address_screen.dart`, `profile_screen.dart`, `splash_screen.dart` |
| [2](#parte-2--filtros-da-busca--cupons) | **Mateus** | Filtros da busca + Cupons | `search_filters.dart`, `search_filters_sheet.dart`, `coupons_screen.dart` |
| [3](#parte-3--pedidos-no-supabase--favoritos) | **Helena** | Pedidos (Supabase) + Favoritos | `orders_screen.dart`, `orders_controller.dart`, `favorites_screen.dart`, `favorites_controller.dart`, `supabase/schema.sql` |
| [Bônus](#bônus--sacola-comparativa) | quem terminar antes | Sacola comparativa (opcional) | `cart_controller.dart`, `cart_screen.dart` |

---

## 🧰 Como trabalhar (vale para todos)

### 1. Preparar o ambiente (uma vez)

```bash
git clone https://github.com/helenabc01/CheapEats.git
cd CheapEats
flutter pub get
flutter run -d chrome
```

Para entrar no app, use a **conta demo** (botão "Conta demo" no login: `ana.demo@cheapeats.app` / `cheap123`) ou **Explorar sem conta**.

> **Importante para o professor ver seu nome nos contribuidores:** configure o Git com o **mesmo e-mail da sua conta do GitHub**.
>
> ```bash
> git config user.name "Seu Nome"
> git config user.email "seu-email-do-github@exemplo.com"
> ```

### 2. Criar a sua branch

```bash
git checkout main
git pull
git checkout -b feature/cp5-parte-N-seu-nome
```

### 3. Achar o que fazer

No VS Code, aperte `Ctrl + Shift + F` e procure por `TODO(PARTE-N)` (troque N pelo número da sua parte). Os comentários dizem exatamente o que implementar.

### 4. Regras do projeto

- **Cores e fontes** sempre pelo tema: `AppColors.orange`, `AppColors.teal`, `AppText.h4`, `AppText.body2`, `AppText.price(...)`… Nada de `Color(0xFF...)` direto nas telas.
- **Valores em reais** com `Fmt.brl(valor)` (ex.: `Fmt.brl(12.9)` → `R$ 12,90`).
- **Dados** sempre via `AppServices` (ex.: `AppServices.catalog.restaurants`), nunca lendo o JSON direto.
- Para a tela atualizar quando algo muda, use `ListenableBuilder(listenable: AppServices.x, builder: ...)`.
- Reaproveite os widgets prontos de `lib/widgets/` (lista abaixo).
- Textos em português, com o mesmo tom do app: direto e amigável.
- Antes de cada commit, rode `flutter analyze` (0 problemas) e `flutter test` (tudo passando).

### 5. Entregar

```bash
git add .
git commit -m "feat: tela de onboarding com 3 slides"
git push -u origin feature/cp5-parte-N-seu-nome
```

Depois, no GitHub, abra um **Pull Request para a `main`** e marque o Ryan para revisar. Faça **vários commits pequenos**, um por avanço: fica mais fácil revisar e mostra melhor o seu trabalho.

Por fim, troque o "⏳" da sua parte por "✅" na tabela de status do `README.md`. Se puder, adicione um print da sua tela em `docs/prints/`.

### 🧩 O que já existe para você usar

| Onde | O que é |
| --- | --- |
| `AppServices.catalog` | Apps, restaurantes, pratos e cupons (`platforms`, `restaurants`, `coupons`, `restaurantById`, `searchDishes`…) |
| `AppServices.calculator` | Comparação de preços (`compareDish`, `compare`, `bestPlatformFor`, `maxSavingsRatio`) |
| `AppServices.session` | Usuário logado (`displayName`, `email`, `isGuest`, `logout()`) |
| `AppServices.address` | Endereço de entrega (`current`, `select(...)`); o mapa centraliza nele |
| `AppServices.favorites` | Favoritos (`isFavorite`, `toggle`, `ids`) |
| `AppServices.orders` | Pedidos (`orders`, `register(...)`, `totalSavings`) |
| `AppRoutes` | Nomes das rotas (`AppRoutes.login`, `.restaurant`, `.compare`, `.map`, `.coupons`…) |
| `RestaurantCard`, `DishTile`, `PlatformBadge`, `SavingsBadge`, `PromoTag`, `FoodImage`, `RestaurantLogo`, `SectionHeader`, `QuantityStepper`, `DataSourceChip`, `CategoryTile`, `MapPreviewCard` | Widgets prontos em `lib/widgets/` |
| `Fmt` | Formatação: `brl`, `fee`, `percent`, `deliveryTime`, `distance` |

> Para ver como usar, olhe as telas prontas: `home_screen.dart`, `map_screen.dart`, `restaurant_screen.dart` e `comparison_screen.dart`.

---

## Parte 1 — Onboarding + Endereço + Perfil

**Responsável:** Henrique

**Objetivo:** apresentar o app na primeira abertura, permitir escolher o endereço de entrega (funcionalidade "Localização integrada" do MVP) e criar a área do usuário.

**Arquivos:** `lib/screens/onboarding_screen.dart`, `lib/screens/address_screen.dart`, `lib/screens/profile_screen.dart`, `lib/screens/splash_screen.dart` (um ajuste) e, opcionalmente, um arquivo novo `lib/data/mock_addresses.dart`.

### Passo a passo

1. **Onboarding** (`onboarding_screen.dart`): `PageView` com 3 páginas:
   - "Compare antes de pedir": o mesmo prato em 5 apps;
   - "O preço real aparece": frete, taxas e cupons já somados;
   - "Peça no mais barato": um toque e você vai para o app vencedor.

   Cada página tem um ícone grande num círculo `AppColors.orangeSoft`, título `AppText.h3` e texto `AppText.body2`. Embaixo vêm as bolinhas de página (veja o carrossel da Home em `home_screen.dart`), o botão **Pular** (`TextButton`) e o botão **Próximo/Começar** (`ElevatedButton`).
2. Ao terminar ou pular, salvar que o onboarding já foi visto e ir para o login:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   await prefs.setBool('onboarding_visto', true);
   if (!context.mounted) return;
   Navigator.of(context).pushReplacementNamed(AppRoutes.login);
   ```
3. **Splash** (`splash_screen.dart`, no `TODO(PARTE-1)`): ler a flag e decidir o destino:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   final visto = prefs.getBool('onboarding_visto') ?? false;
   Navigator.of(context).pushNamedAndRemoveUntil(
     visto ? AppRoutes.login : AppRoutes.onboarding, (_) => false);
   ```
4. **Endereços simulados:** crie uma lista com 4 a 6 `DeliveryAddress` em São Paulo, **com latitude e longitude** (o mapa centraliza no endereço escolhido). Exemplos: "FIAP Paulista · Av. Paulista, 1106" (-23.5641, -46.6534), "Casa · Rua Vergueiro, 3185 · Vila Mariana" (-23.5869, -46.6380), "Trabalho · Av. Faria Lima, 2232 · Pinheiros" (-23.5763, -46.6886).
5. **Tela de endereço** (`address_screen.dart`):
   - campo de busca que filtra a lista;
   - item "Usar minha localização atual": mostra um carregamento de 1 s (`Future.delayed`) e escolhe o endereço da FIAP;
   - lista com ícone (casa/trabalho/escola) e check no endereço atual (`AppServices.address.current`);
   - ao tocar: `AppServices.address.select(endereco)` e `Navigator.pop(context)`.
6. **Perfil** (`profile_screen.dart`):
   - cabeçalho com avatar (círculo laranja com as iniciais de `AppServices.session.displayName`), nome e e-mail (ou "Visitante · entrou sem conta");
   - card **Minha economia** em teal (veja o `_HeroCard` em `comparison_screen.dart`) com `Fmt.brl(AppServices.orders.totalSavings)` e a quantidade de pedidos;
   - menu com `ListTile` para Favoritos (`AppRoutes.favorites`), Endereços (`AppRoutes.address`), Mapa (`AppRoutes.map`), Cupons (`AppRoutes.coupons`) e "Sobre o CheapEats" (dialog com a versão e os integrantes);
   - `DataSourceChip` (de onde vêm os dados);
   - botão **Sair**: `AppServices.session.logout()` + `Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false)`.

### Critérios de aceite

- [ ] O onboarding aparece só na primeira vez (para testar de novo, use uma aba anônima do Chrome).
- [ ] "Pular" e "Começar" levam ao login.
- [ ] Ao escolher um endereço, o topo da Home muda na hora e o mapa abre centralizado nele.
- [ ] O perfil mostra o nome de quem fez login (ou "Visitante") e "Sair" volta para o login.
- [ ] Visual seguindo o tema (cores, fontes e espaçamentos das outras telas).

---

## Parte 2 — Filtros da busca + Cupons

**Responsável:** Mateus

**Objetivo:** filtrar e ordenar os resultados da busca e reunir todos os cupons dos apps em uma tela.

**Arquivos:** `lib/data/search_filters.dart`, `lib/widgets/search_filters_sheet.dart`, `lib/screens/coupons_screen.dart`.

### Passo a passo

1. **Lógica dos filtros** (`search_filters.dart`, nos dois `TODO(PARTE-2)`):
   - `applyToRestaurants`: manter só as categorias escolhidas (`r.category`), os restaurantes que estão nos apps escolhidos (`r.isOn(id)`) e, se `freeDeliveryOnly`, os que têm `r.lowestDeliveryFee == 0`. Ordenar por `sort`: `bestRated` → `rating` maior; `fastest` → menor `deliveryRange.$1`; `lowestPrice` → menor `lowestDeliveryFee`.
   - `applyToDishes`: mesmas regras de categoria e app (`d.priceOn(id) != null`), mais o `maxPrice` (use `dish.lowestPrice`). Para `lowestPrice`, ordene pelo total do melhor app: `AppServices.calculator.compareDish(r, d).best?.total`.
2. **Bottom sheet** (`search_filters_sheet.dart`): trocar o conteúdo provisório por um `StatefulBuilder` (ou `StatefulWidget`) com:
   - `FilterChip` para cada categoria (`FoodCategory.all`) e para cada app (`AppServices.catalog.platforms`, use `PlatformBadge`);
   - `SwitchListTile` "Só entrega grátis";
   - `Slider` de preço máximo (R$ 10 a R$ 200);
   - `ChoiceChip` de ordenação (`SearchSort.values`, use `.label`);
   - botões **Limpar** e **Aplicar** (`Navigator.pop(context, novosFiltros)`).

   A tela de Busca já mostra um contador no ícone de filtros e reaplica tudo sozinha.
3. **Tela de Cupons** (`coupons_screen.dart`):
   - `ChoiceChip` no topo para filtrar por app (Todos + os 5 apps);
   - cards agrupados por app, com código em destaque, título, regra (`minOrder`, `maxDiscount`, "só no 1º pedido"), validade (`expiresAt`) e restaurante, se for exclusivo (`AppServices.catalog.restaurantById(c.restaurantId!)`);
   - botão "Copiar" com `Clipboard.setData(ClipboardData(text: c.code))` + `SnackBar`;
   - seção "Expirados" no fim, com os cupons `c.isExpired()` em cinza;
   - texto de rodapé: "A comparação já aplica automaticamente o melhor cupom".

### Critérios de aceite

- [ ] Buscar "pizza" e filtrar só o app "Keeta" esconde a Pizza de Rúcula, que não é vendida no Keeta.
- [ ] Filtrar a categoria "Pizza" mostra só os pratos da Bella Napoli.
- [ ] "Só entrega grátis" esconde os restaurantes sem frete grátis em algum app.
- [ ] Ordenar por "Melhor avaliação" muda a ordem dos restaurantes.
- [ ] "Limpar" volta aos filtros padrão e o contador do ícone some.
- [ ] Cupons agrupados por app, copiar funciona e o cupom expirado (`VOLTA20`) aparece separado.
- [ ] Os banners da Home ("Ver cupons") abrem a tela de cupons.

---

## Parte 3 — Pedidos no Supabase + Favoritos

**Responsável:** Helena

**Objetivo:** mostrar o histórico de pedidos com a economia de cada um, **gravar os pedidos no Supabase** (a escrita no banco) e salvar os restaurantes favoritos.

**Arquivos:** `lib/screens/orders_screen.dart`, `lib/core/services/orders_controller.dart`, `lib/screens/favorites_screen.dart`, `lib/core/services/favorites_controller.dart`, `supabase/schema.sql`.

### Passo a passo

1. **Tabela no banco:** adicione ao fim do `supabase/schema.sql` (no `TODO(PARTE-3)`) e rode no SQL Editor do Supabase (peça acesso ao projeto para o Ryan):
   ```sql
   create table if not exists public.orders (
     id              uuid primary key default gen_random_uuid(),
     device_id       text not null,
     restaurant_id   text not null references public.restaurants(id),
     restaurant_name text not null,
     platform_id     text not null references public.platforms(id),
     items_summary   text not null,
     total           numeric(10,2) not null,
     savings         numeric(10,2) not null default 0,
     created_at      timestamptz not null default now()
   );
   alter table public.orders enable row level security;
   create policy "app registra pedidos" on public.orders for insert to anon, authenticated with check (true);
   create policy "app lê pedidos" on public.orders for select to anon, authenticated using (true);
   grant select, insert on public.orders to anon, authenticated;
   ```
   > Protótipo: sem login real, cada aparelho é identificado por um `device_id` aleatório salvo no `shared_preferences`. Com o Supabase Auth, isso vira `auth.uid()`.
2. **Gravar** (`OrdersController.register`, que o comparador já chama): além de guardar na lista, inserir no Supabase quando ele estiver disponível:
   ```dart
   if (AppServices.dataSource == DataSource.supabase) {
     try {
       await Supabase.instance.client.from('orders').insert({
         'device_id': deviceId,
         'restaurant_id': order.restaurantId,
         'restaurant_name': order.restaurantName,
         'platform_id': order.platformId,
         'items_summary': order.itemsSummary,
         'total': order.total,
         'savings': order.savings,
       });
     } catch (e) {
       debugPrint('Falha ao salvar pedido no Supabase: $e'); // o pedido continua na lista local
     }
   }
   ```
3. **Carregar** o histórico ao abrir o app (ex.: um método `load()` chamado no splash): `select()` filtrando por `device_id` e ordenando por `created_at` decrescente. Sem banco, comece com 3 a 5 **pedidos simulados** antigos (crie `fromJson`/`toJson` no `OrderRecord`).
4. **Aba Pedidos** (`orders_screen.dart`):
   - `ListenableBuilder(listenable: AppServices.orders, ...)`;
   - card com `RestaurantLogo` ou `FoodImage`, nome do restaurante, `PlatformBadge` do app usado, itens, data ("05/10 · 20:15"), total (`AppText.price`) e `SavingsBadge(amount: order.savings)`;
   - card de resumo no topo: "Você já economizou R$ X com o CheapEats";
   - tocar no pedido abre um detalhe (bottom sheet) com o botão **Pedir de novo**, que abre o restaurante (`AppRoutes.restaurant`);
   - estado vazio: "Nenhum pedido ainda" + botão para ir à Busca (`MainShell.tab.value = MainShell.searchTab`).
5. **Favoritos** (`favorites_controller.dart`): salvar a lista de ids no `shared_preferences` a cada `toggle` e carregar ao abrir o app:
   ```dart
   Future<void> load() async {
     final prefs = await SharedPreferences.getInstance();
     _ids..clear()..addAll(prefs.getStringList('favoritos') ?? []);
     notifyListeners();
   }
   ```
   Chame `AppServices.favorites.load()` no splash, junto com o carregamento do catálogo.
6. **Tela de Favoritos** (`favorites_screen.dart`, aberta pelo Perfil): lista de `RestaurantCard` dos ids favoritos (`AppServices.catalog.restaurantById(id)`); tocar abre o restaurante; estado vazio "Toque no coração de um restaurante para salvar aqui".

### Critérios de aceite

- [ ] Fazer um pedido pelo comparador faz ele aparecer na aba Pedidos na hora.
- [ ] O pedido aparece na tabela `orders` do Supabase (mostre o *Table Editor* na apresentação!).
- [ ] Sem internet, o app não quebra: o pedido fica só na lista local.
- [ ] Depois de pedir no Keeta, o cupom de 1º pedido do Keeta (`BEMVINDO15`) deixa de ser aplicado (isso já acontece e vale mostrar na demo).
- [ ] Favoritar no restaurante faz ele aparecer em Favoritos, e os favoritos continuam lá depois de recarregar a página (F5).

---

## Bônus — Sacola comparativa

Opcional, para quem terminar antes. Hoje o comparador compara **um prato** (com quantidade). A sacola compara **o pedido inteiro**: o frete é pago uma vez só, então o app vencedor pode mudar!

- Crie `lib/core/services/cart_controller.dart` (`ChangeNotifier` com `List<OrderItem>` e o restaurante atual; ao adicionar item de outro restaurante, pergunte se quer esvaziar a sacola).
- Ligue o botão de sacola do comparador (`TODO(BONUS)` em `comparison_screen.dart`) e mostre a barra "Ver sacola (3 itens)" no restaurante (`TODO(BONUS)` em `restaurant_screen.dart`).
- Na `cart_screen.dart`, use `AppServices.calculator.compare(restaurante, itens)`. Ele já aceita vários itens, então dá para reaproveitar o `PlatformTile` e o resumo da comparação.

---

## 🏁 Checklist final (antes da apresentação)

- [ ] Todos os PRs revisados e mesclados na `main`
- [ ] `flutter analyze` sem problemas e `flutter test` passando na `main`
- [ ] `flutter run -d chrome` testado no computador da apresentação (com internet para o mapa e as fotos)
- [ ] Selo **Dados: Supabase** aparecendo (e o modo offline testado)
- [ ] Tabela de status do README atualizada
- [ ] Ensaiar o roteiro da demo (README → "Roteiro da demonstração")
