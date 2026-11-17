local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)

local ScoreUI = {}

local COR_NOS      = Color3.fromRGB(39, 174, 96)
local COR_ELES     = Color3.fromRGB(210, 55, 55)
local COR_CANGA    = Color3.fromRGB(240, 195, 35)
local COR_PENDENTE = Color3.fromRGB(68, 72, 85)

local COR_BORDA_ATIVA    = Color3.fromRGB(235, 240, 250)
local COR_BORDA_PENDENTE = Color3.fromRGB(95, 100, 115)

-- Referências internas (injetadas pelo UIManager)
local textoCronometro, textoPlacarJogo, textoValorRodada, textoEstatisticas
local painelEstatisticas, painelVira
local marcadoresQuedas = {}

local function corParaResultado(resultado)
    if resultado == "NOS" then
        return COR_NOS, COR_BORDA_ATIVA
    elseif resultado == "ELES" then
        return COR_ELES, COR_BORDA_ATIVA
    elseif resultado == "CANGA" then
        return COR_CANGA, COR_BORDA_ATIVA
    end
    return COR_PENDENTE, COR_BORDA_PENDENTE
end

local function atualizarCirculosQuedas(nossasQuedas, quedasInimigo, historicoQuedas)
    if #marcadoresQuedas == 0 then return end

    local lista = {}
    if type(historicoQuedas) == "table" then
        for i = 1, 3 do
            lista[i] = historicoQuedas[i]
        end
    else
        local idx = 1
        for _ = 1, (nossasQuedas or 0) do
            if idx <= 3 then
                lista[idx] = "NOS"
                idx += 1
            end
        end
        for _ = 1, (quedasInimigo or 0) do
            if idx <= 3 then
                lista[idx] = "ELES"
                idx += 1
            end
        end
    end

    for i, circulo in ipairs(marcadoresQuedas) do
        local corFundo, corBorda = corParaResultado(lista[i])
        circulo.BackgroundColor3 = corFundo
        local borda = circulo:FindFirstChildOfClass("UIStroke")
        if borda then
            borda.Color = corBorda
            borda.Transparency = lista[i] and 0.15 or 0.55
        end
    end
end

-- (O) Aberto para extensão: novos métodos de exibição sem modificar os existentes
function ScoreUI.Inicializar(refs)
    textoCronometro    = refs.textoCronometro
    textoPlacarJogo    = refs.textoPlacarJogo
    textoValorRodada   = refs.textoValorRodada
    textoEstatisticas  = refs.textoEstatisticas
    painelEstatisticas = refs.painelEstatisticas
    painelVira         = refs.painelVira
    marcadoresQuedas   = refs.marcadoresQuedas or {}
    atualizarCirculosQuedas(0, 0, nil)
end

function ScoreUI.AtualizarStatus(msg, val)
    if not textoCronometro then return end
    local nome = GameConfig.StateDisplayNames[msg] or msg
    local num = tonumber(val)
    textoCronometro.Text = (num and num > 0) and (nome .. " " .. num) or nome
    textoCronometro.Visible = true
end

function ScoreUI.AtualizarPlacar(meu, inimigo)
    if textoPlacarJogo then
        textoPlacarJogo.Text = "JOGO: " .. meu .. " x " .. inimigo
    end
end

function ScoreUI.AtualizarValorRodada(val, estaSentado)
    if textoValorRodada then
        textoValorRodada.Text = "VALE: " .. tostring(val)
        textoValorRodada.Visible = estaSentado
    end
end

function ScoreUI.AtualizarEstatisticas(parceiro, nossasQuedas, quedasInimigo, estaSentado, historicoQuedas)
    if not painelEstatisticas then return end
    painelEstatisticas.Visible = estaSentado
    if textoEstatisticas then
        textoEstatisticas.Text = "Dupla: " .. (parceiro or "Ninguém")
    end
    atualizarCirculosQuedas(nossasQuedas, quedasInimigo, historicoQuedas)
end

function ScoreUI.DefinirVisibilidade(visivel)
    if painelEstatisticas then painelEstatisticas.Visible = visivel end
    if textoPlacarJogo then textoPlacarJogo.Visible = visivel end
    if painelVira then painelVira.Visible = visivel end
    if textoValorRodada then textoValorRodada.Visible = visivel end
end

function ScoreUI.MostrarPlacar(estaSentado)
    if textoPlacarJogo then textoPlacarJogo.Visible = estaSentado end
end

function ScoreUI.OcultarPlacar()
    if textoPlacarJogo then textoPlacarJogo.Visible = false end
end

return ScoreUI
