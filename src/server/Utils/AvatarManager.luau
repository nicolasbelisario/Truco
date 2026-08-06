local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local AvatarManager = {}

-- Cache para evitar chamar a API de amigos repetidamente para o mesmo jogador
local friendsCache = {}
local CACHE_EXPIRATION = 300 -- 5 minutos

-- [MÉTODO INTERNO] Busca os amigos de um jogador, usando cache
local function getFriends(player)
    local userId = player.UserId
    local now = tick()

    -- Verifica se o cache é válido
    if friendsCache[userId] and (now - friendsCache[userId].timestamp) < CACHE_EXPIRATION then
        return friendsCache[userId].data
    end

    local success, friends = pcall(function()
        return Players:GetFriendsAsync(userId)
    end)

    if success and friends then
        local friendList = {}
        local pages = friends
        while true do
            for _, friend in ipairs(pages:GetCurrentPage()) do
                if friend.Id then
                    table.insert(friendList, friend.Id)
                end
            end
            if pages.IsFinished then
                break
            end
            pages:AdvanceToNextPageAsync()
        end
        
        -- Salva no cache
        friendsCache[userId] = {
            data = friendList,
            timestamp = now
        }
        return friendList
    else
        warn("AvatarManager: Falha ao buscar amigos para o jogador " .. player.Name, friends)
        return nil
    end
end

-- [MÉTODO] Retorna uma lista de descrições de avatares de amigos aleatórios dos jogadores fornecidos
function AvatarManager.GetRandomFriendAvatars(players, count, excludeList)
    local allFriends = {}
    local usedFriends = excludeList or {}

    -- 1. Agrega amigos de todos os jogadores humanos na mesa
    for _, player in ipairs(players) do
        local playerFriends = getFriends(player)
        if playerFriends then
            for _, friendId in ipairs(playerFriends) do
                if not usedFriends[friendId] then
                    table.insert(allFriends, friendId)
                    usedFriends[friendId] = true
                end
            end
        end
    end

    if #allFriends == 0 then
        warn("AvatarManager: Nenhum amigo novo encontrado para os jogadores na mesa.")
        return {}, usedFriends
    end

    -- 2. Embaralha a lista de amigos para pegar avatares aleatórios
    local rng = Random.new()
    for i = #allFriends, 2, -1 do
        local j = rng:NextInteger(1, i)
        allFriends[i], allFriends[j] = allFriends[j], allFriends[i]
    end

    -- 3. Busca as descrições dos avatares até a quantidade desejada
    local avatars = {}
    local friendsToFetch = math.min(count, #allFriends)
    local usedIdsForAvatars = {}

    for i = 1, friendsToFetch do
        local friendId = allFriends[i]
        local success, humanoidDesc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(friendId)
        end)

        if success and humanoidDesc then
            table.insert(avatars, humanoidDesc)
            usedIdsForAvatars[friendId] = true -- Marca que este amigo foi escolhido
        else
            warn("AvatarManager: Falha ao buscar HumanoidDescription para o UserId: " .. friendId, humanoidDesc)
        end
    end

    -- Atualiza a lista de exclusão com os amigos recém-usados
    for id, _ in pairs(usedIdsForAvatars) do
        usedFriends[id] = true
    end

    return avatars, usedFriends
end

return AvatarManager
