local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)

local ScoreUI = {}

-- Referências internas (injetadas pelo UIManager)
local textoCronometro, textoPlacarJogo, textoValorRodada, textoEstatisticas
local painelEstatisticas, painelVira

-- (O) Aberto para extensão: novos métodos de exibição sem modificar os existentes
function ScoreUI.Inicializar(refs)
    textoCronometro  = refs.textoCronometro
    textoPlacarJogo  = refs.textoPlacarJogo
    textoValorRodada = refs.textoValorRodada
    textoEstatisticas = refs.textoEstatisticas
    painelEstatisticas = refs.painelEstatisticas
    painelVira = refs.painelVira
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

function ScoreUI.AtualizarEstatisticas(parceiro, nossasQuedas, quedasInimigo, estaSentado)
    if not painelEstatisticas then return end
    painelEstatisticas.Visible = estaSentado
    textoEstatisticas.Text = string.format(
        "Sua Dupla: %s\nNós: %d Quedas\nEles: %d Quedas",
        parceiro or "Ninguém", nossasQuedas or 0, quedasInimigo or 0
    )
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