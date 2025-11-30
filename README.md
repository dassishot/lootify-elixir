# Lootify - Sistema de Apostas Real-Time

Sistema de apostas esportivas em tempo real construído com Elixir/Phoenix, usando arquitetura de microserviços com Distributed Erlang.

## 🏗️ Arquitetura

```
                              Internet
                                 │
                            Load Balancer
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
              ┌──────────┐              ┌──────────┐
              │ Gateway  │              │ Gateway  │
              │ (Phoenix)│◄────────────►│ (Phoenix)│
              └────┬─────┘   Cluster    └────┬─────┘
                   │                         │
     ┌─────────────┼─────────────────────────┼─────────────┐
     │             │     BEAM Cluster        │             │
     │             ▼                         ▼             │
     │  ┌──────────────────────────────────────────────┐  │
     │  │   ┌─────────┐  ┌─────────┐  ┌─────────┐    │  │
     │  │   │  Users  │  │  Bets   │  │ Wallets │    │  │
     │  │   │ Service │◄►│ Service │◄►│ Service │    │  │
     │  │   └────┬────┘  └────┬────┘  └────┬────┘    │  │
     │  └────────┼────────────┼────────────┼──────────┘  │
     └───────────┼────────────┼────────────┼─────────────┘
                 ▼            ▼            ▼
            PostgreSQL   PostgreSQL   PostgreSQL
             (users)       (bets)     (wallets)
```

## 📦 Serviços

| Serviço | Porta DB | Descrição |
|---------|----------|-----------|
| `lootify_wallets` | 5432 | Gerenciamento de saldos e transações |
| `lootify_users` | 5433 | Autenticação e perfil de usuários |
| `lootify_bets` | 5434 | Eventos, mercados e apostas |
| `lootify_gateway` | 4000 | API REST + WebSockets |

## 🚀 Quick Start

### Pré-requisitos

- Elixir 1.19+
- Erlang/OTP 28+
- Docker e Docker Compose
- PostgreSQL (via Docker)

### 1. Subir os bancos de dados

```bash
cd D:\developer\lootify
docker-compose up -d
```

### 2. Configurar cada serviço

```bash
# Wallets
cd lootify_wallets
mix deps.get
mix ecto.create
mix ecto.migrate

# Users
cd ../lootify_users
mix deps.get
mix ecto.create
mix ecto.migrate

# Bets
cd ../lootify_bets
mix deps.get
mix ecto.create
mix ecto.migrate

# Gateway
cd ../lootify_gateway
mix deps.get
```

### 3. Iniciar os serviços (cada um em um terminal)

```powershell
# Terminal 1 - Wallets
cd D:\developer\lootify\lootify_wallets
iex --sname wallets -S mix

# Terminal 2 - Users
cd D:\developer\lootify\lootify_users
iex --sname users -S mix

# Terminal 3 - Bets
cd D:\developer\lootify\lootify_bets
iex --sname bets -S mix

# Terminal 4 - Gateway
cd D:\developer\lootify\lootify_gateway
iex --sname gateway -S mix phx.server
```

### 4. Conectar os nós (em qualquer terminal IEx)

```elixir
Node.connect(:"wallets@SEUHOSTNAME")
Node.connect(:"users@SEUHOSTNAME")
Node.connect(:"bets@SEUHOSTNAME")
Node.connect(:"gateway@SEUHOSTNAME")

# Verificar conexões
Node.list()
```

## 📡 API Endpoints

### Autenticação

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| POST | `/api/auth/register` | Registrar usuário | ❌ |
| POST | `/api/auth/login` | Login | ❌ |
| GET | `/api/auth/me` | Dados do usuário | ✅ |
| POST | `/api/auth/logout` | Logout | ✅ |

### Wallet

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| GET | `/api/wallet/balance` | Ver saldo | ✅ |
| POST | `/api/wallet/deposit` | Fazer depósito | ✅ |

### Eventos

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| GET | `/api/events` | Listar eventos | ❌ |
| GET | `/api/events/:id` | Detalhes do evento | ❌ |

### Apostas

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| GET | `/api/bets` | Minhas apostas | ✅ |
| GET | `/api/bets/:id` | Detalhes da aposta | ✅ |
| POST | `/api/bets` | Fazer aposta | ✅ |
| DELETE | `/api/bets/:id` | Cancelar aposta | ✅ |

### Health Check

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/health` | Status do serviço |

## 🔌 WebSocket

### Conexão

```javascript
import { Socket } from "phoenix"

const socket = new Socket("/socket", {
  params: { token: "seu_jwt_token" }
})
socket.connect()
```

### Canal do Usuário

```javascript
const userChannel = socket.channel(`user:${userId}`)

userChannel.join()
  .receive("ok", resp => console.log("Conectado!", resp))
  .receive("error", resp => console.log("Erro:", resp))

// Receber atualizações
userChannel.on("balance", balance => {
  console.log("Saldo atualizado:", balance)
})

userChannel.on("bet_placed", bet => {
  console.log("Aposta confirmada:", bet)
})

userChannel.on("bet_settled", bet => {
  console.log("Aposta liquidada:", bet)
})

// Fazer aposta via WebSocket
userChannel.push("place_bet", {
  market_id: "uuid-do-mercado",
  amount: "50.00",
  selection: "home_win"
})
  .receive("ok", resp => console.log("Aposta feita:", resp))
  .receive("error", resp => console.log("Erro:", resp))

// Cancelar aposta
userChannel.push("cancel_bet", { bet_id: "uuid-da-aposta" })

// Consultar saldo
userChannel.push("get_balance", {})
  .receive("ok", balance => console.log("Saldo:", balance))
```

### Canal de Evento (Odds em tempo real)

```javascript
const eventChannel = socket.channel(`event:${eventId}`)

eventChannel.join()
  .receive("ok", resp => console.log("Inscrito no evento"))

// Receber atualizações de odds
eventChannel.on("odds_updated", data => {
  console.log(`Market ${data.market_id}: ${data.odds}`)
})

// Receber mudança de status
eventChannel.on("status_changed", data => {
  console.log(`Evento agora está: ${data.status}`)
})

// Dados completos do evento
eventChannel.on("event_data", event => {
  console.log("Evento:", event)
})
```

## 📁 Estrutura do Projeto

```
lootify/
├── docker-compose.yml              # PostgreSQL para todos os serviços
│
├── lootify_wallets/                # Serviço de Carteiras
│   ├── lib/
│   │   ├── lootify_wallets/
│   │   │   ├── domain/
│   │   │   │   ├── wallet.ex       # Schema + lógica de domínio
│   │   │   │   └── transaction.ex
│   │   │   ├── wallets.ex          # Contexto (usecases)
│   │   │   ├── server.ex           # GenServer (comunicação cluster)
│   │   │   └── repo.ex
│   │   └── lootify_wallets.ex
│   └── priv/repo/migrations/
│
├── lootify_users/                  # Serviço de Usuários
│   ├── lib/
│   │   ├── lootify_users/
│   │   │   ├── domain/user.ex      # Schema + validações
│   │   │   ├── users.ex            # Contexto
│   │   │   ├── guardian.ex         # JWT Auth
│   │   │   └── server.ex
│   │   └── lootify_users.ex
│   └── priv/repo/migrations/
│
├── lootify_bets/                   # Serviço de Apostas
│   ├── lib/
│   │   ├── lootify_bets/
│   │   │   ├── domain/
│   │   │   │   ├── event.ex        # Eventos (jogos)
│   │   │   │   ├── market.ex       # Mercados (odds)
│   │   │   │   └── bet.ex          # Apostas
│   │   │   ├── bets.ex             # Contexto
│   │   │   ├── odds_cache.ex       # Cache ETS (real-time)
│   │   │   └── server.ex
│   │   └── lootify_bets.ex
│   └── priv/repo/migrations/
│
└── lootify_gateway/                # API Gateway (Phoenix)
    ├── lib/
    │   ├── lootify_gateway_web/
    │   │   ├── channels/
    │   │   │   ├── user_socket.ex
    │   │   │   ├── user_channel.ex
    │   │   │   └── event_channel.ex
    │   │   ├── controllers/
    │   │   │   ├── auth_controller.ex
    │   │   │   ├── wallet_controller.ex
    │   │   │   ├── event_controller.ex
    │   │   │   ├── bet_controller.ex
    │   │   │   └── health_controller.ex
    │   │   ├── plugs/auth.ex
    │   │   ├── router.ex
    │   │   └── endpoint.ex
    │   └── lootify_gateway.ex
    └── config/
```

## 🔑 Pontos-chave da Arquitetura

### Comunicação entre Serviços

Os serviços se comunicam via **Distributed Erlang** através de GenServers registrados globalmente:

```elixir
# Chamando o serviço de Wallet a partir do serviço de Bets
LootifyWallets.Server.reserve(user_id, amount, reference_id)
```

### Cache de Odds (ETS)

Odds são armazenadas em ETS para acesso ultra-rápido (~0.001ms):

```elixir
# Leitura do cache
LootifyBets.OddsCache.get(market_id)

# Atualização (notifica via PubSub)
LootifyBets.OddsCache.put(market_id, new_odds)
```

### Transações Atômicas

Operações de wallet usam transações com lock otimista:

```elixir
Repo.transaction(fn ->
  wallet = Repo.one!(from w in Wallet, where: w.user_id == ^user_id, lock: "FOR UPDATE")
  # ... operações atômicas
end)
```

### Idempotência

Todas as operações de wallet são idempotentes via `reference_id`:

```elixir
# Se a mesma operação for chamada 2x, a segunda é ignorada
LootifyWallets.credit(user_id, amount, reference_id, "Depósito")
```

## 🧪 Testando no IEx

```elixir
# Criar usuário
{:ok, user} = LootifyUsers.register(%{
  email: "test@example.com",
  username: "testuser",
  password: "SecurePass123"
})

# Criar wallet
{:ok, wallet} = LootifyWallets.create_wallet(user.id)

# Depositar
{:ok, _} = LootifyWallets.credit(user.id, Decimal.new("1000.00"), UUID.uuid4(), "Depósito")

# Ver saldo
{:ok, balance} = LootifyWallets.get_balance(user.id)

# Criar evento
{:ok, event} = LootifyBets.create_event(%{
  name: "Brasil x Argentina",
  category: "futebol",
  starts_at: DateTime.utc_now() |> DateTime.add(3600, :second)
})

# Criar mercado
{:ok, market} = LootifyBets.create_market(%{
  event_id: event.id,
  name: "Vencedor",
  type: "winner",
  odds: Decimal.new("2.50")
})

# Fazer aposta
{:ok, bet} = LootifyBets.place_bet(user.id, market.id, Decimal.new("100.00"), "brasil")
```

## 📊 Variáveis de Ambiente (Produção)

```bash
# Database
DATABASE_URL=ecto://user:pass@host/database
POOL_SIZE=20

# Auth
GUARDIAN_SECRET_KEY=sua_chave_secreta_aqui

# Cluster
CLUSTER_SERVICE=lootify-cluster

# Phoenix
SECRET_KEY_BASE=sua_chave_secreta_phoenix
PHX_HOST=lootify.com
PORT=4000
```

## 🐳 Docker (Produção)

```dockerfile
# Exemplo de Dockerfile para cada serviço
FROM elixir:1.19-alpine AS builder

WORKDIR /app
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY lib lib
COPY priv priv
COPY config config

RUN mix release

FROM alpine:3.18
COPY --from=builder /app/_build/prod/rel/lootify_* ./
CMD ["bin/lootify_*/start"]
```

## 📈 Escalabilidade

- **Horizontal**: Adicione mais nós ao cluster Kubernetes
- **Vertical**: Aumente recursos dos pods
- **Cache**: Odds em ETS com `read_concurrency: true`
- **Pool**: Configure `POOL_SIZE` para conexões de banco

## 🔒 Segurança

- JWT para autenticação
- Senhas hash com PBKDF2
- CORS configurado
- Validação de entrada em todos os endpoints
- Lock otimista em transações financeiras

## 📝 Licença

MIT

