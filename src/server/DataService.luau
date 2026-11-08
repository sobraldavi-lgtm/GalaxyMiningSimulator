-- Salvamento dos jogadores com DataStore.
--  • Trava de sessão: só um servidor escreve os dados de cada jogador por vez,
--    evitando perda ou duplicação ao trocar de servidor rapidamente.
--  • Tentativas com espera crescente em caso de falha da API.
--  • Salvamento periódico, ao sair e ao fechar o servidor (BindToClose).
--  • Sem acesso às APIs (Studio sem "Enable Studio Access to API Services"
--    ou lugar não publicado), funciona só em memória e avisa no Output.
-- Guarda apenas progresso do jogo, indexado pelo UserId; nenhum dado pessoal.
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataService = {}

local STORE_NAME = "GalaxyMiningPlayers_v1"
local LOCK_TIMEOUT = 300 -- segundos até considerar a trava de outro servidor abandonada
local LOCK_RETRIES = 5
local RETRY_DELAYS = { 1, 2, 4, 8 }

local store
local available = false
local jobId = game.JobId ~= "" and game.JobId or ("studio-" .. tostring(math.random(1, 1e9)))

local function keyFor(userId: number): string
	return "player_" .. userId
end

-- Executa uma chamada com até 5 tentativas e espera crescente.
local function withRetries(label, callback)
	local lastError
	for attempt = 1, #RETRY_DELAYS + 1 do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		warn(string.format("[DataService] %s falhou (tentativa %d): %s", label, attempt, tostring(result)))
		if attempt <= #RETRY_DELAYS then
			task.wait(RETRY_DELAYS[attempt])
		end
	end
	return false, lastError
end

-- Espera ter orçamento de requisições antes de gravar (evita fila e throttling).
local function waitForBudget(requestType)
	local deadline = os.clock() + 10
	while DataStoreService:GetRequestBudgetForRequestType(requestType) <= 0 and os.clock() < deadline do
		task.wait(0.5)
	end
end

function DataService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		-- Uma leitura de teste confirma o acesso (falha no Studio sem permissão).
		local probe = pcall(function()
			result:GetAsync("probe")
		end)
		available = probe
		store = result
	end
	if not available then
		warn("[DataService] DataStore indisponível: progresso só em memória nesta sessão."
			.. (RunService:IsStudio() and " Ative 'Enable Studio Access to API Services' para testar o salvamento." or ""))
	end
	return available
end

function DataService.IsAvailable(): boolean
	return available
end

-- Carrega e trava os dados. Devolve (sucesso, dados ou nil para jogador novo).
-- Se outro servidor mantém a trava, tenta de novo; após as tentativas,
-- assume a trava (o outro servidor não grava por cima: ver Save).
function DataService.Load(player: Player)
	if not available then
		return true, nil
	end
	local key = keyFor(player.UserId)
	for attempt = 1, LOCK_RETRIES do
		local force = attempt == LOCK_RETRIES
		local lockedElsewhere = false
		local ok, data = withRetries("Carregar " .. key, function()
			waitForBudget(Enum.DataStoreRequestType.UpdateAsync)
			return store:UpdateAsync(key, function(old)
				-- A transformação pode rodar mais de uma vez: reinicia o indicador.
				lockedElsewhere = false
				old = type(old) == "table" and old or { Data = nil }
				local session = old.Session
				if not force and session and session.JobId ~= jobId and os.time() - (session.Time or 0) < LOCK_TIMEOUT then
					lockedElsewhere = true
					return nil -- cancela a escrita; outro servidor ainda usa os dados
				end
				old.Session = { JobId = jobId, Time = os.time() }
				return old
			end)
		end)
		if not ok then
			return false, nil
		end
		if not lockedElsewhere then
			return true, data and data.Data or nil
		end
		if not player.Parent then
			return false, nil
		end
		task.wait(3)
	end
	return false, nil
end

-- Grava os dados se este servidor ainda for o dono da trava.
-- release = true libera a trava (jogador saiu).
function DataService.Save(player: Player, data, release: boolean?)
	if not available then
		return true
	end
	local key = keyFor(player.UserId)
	local ownsLock = true
	local ok = withRetries("Salvar " .. key, function()
		waitForBudget(Enum.DataStoreRequestType.UpdateAsync)
		return store:UpdateAsync(key, function(old)
			ownsLock = true
			old = type(old) == "table" and old or {}
			local session = old.Session
			if session and session.JobId ~= jobId then
				ownsLock = false
				return nil -- outro servidor assumiu: não sobrescrever
			end
			return {
				Data = data,
				Session = (not release) and { JobId = jobId, Time = os.time() } or nil,
				SavedAt = os.time(),
			}
		end)
	end)
	if not ownsLock then
		warn("[DataService] " .. key .. " pertence a outro servidor; salvamento ignorado.")
	end
	return ok and ownsLock
end

-- ---------- Placares globais (OrderedDataStore) ----------

local boards = {}
local function board(name)
	if not available then return nil end
	if not boards[name] then
		local ok, result = pcall(function()
			return DataStoreService:GetOrderedDataStore("GalaxyTop_" .. name)
		end)
		boards[name] = ok and result or false
	end
	return boards[name] or nil
end

function DataService.SubmitScore(name: string, userId: number, value: number)
	local ordered = board(name)
	if not ordered then return end
	pcall(function()
		waitForBudget(Enum.DataStoreRequestType.SetIncrementSortedAsync)
		ordered:SetAsync(tostring(userId), math.floor(value))
	end)
end

-- Devolve até `count` entradas { UserId, Value } em ordem decrescente.
function DataService.TopScores(name: string, count: number)
	local ordered = board(name)
	if not ordered then return nil end
	local ok, entries = pcall(function()
		local pages = ordered:GetSortedAsync(false, count)
		return pages:GetCurrentPage()
	end)
	if not ok then return nil end
	local list = {}
	for _, entry in ipairs(entries) do
		table.insert(list, { UserId = tonumber(entry.key), Value = entry.value })
	end
	return list
end

return DataService
