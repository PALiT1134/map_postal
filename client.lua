---------------------------------------------------------------------------
-- [設定エリア] ここで true / false やデザインを自由に切り替えられます
---------------------------------------------------------------------------
local Config = {
    DefaultEnableRoute = false,  -- true: デフォルトで導線を表示 / false: デフォルトで非表示
    SavePreference     = true,  -- true: プレイヤーが切り替えた設定（true/false）を次回も記憶する

    -- デザイン設定
    Color              = { r = 160, g = 32, b = 240, a = 180 }, -- 導線の色 (赤, 緑, 青, 不透明度)
    RibbonWidth        = 1.0,   -- 導線の横幅（メートル）
    RenderDistance     = 250.0, -- 先の道路を描画する距離（メートル）
    SampleStep         = 4.0,   -- 線の滑らかさの間隔（メートル）
}

---------------------------------------------------------------------------
-- 内部変数
---------------------------------------------------------------------------
local postals = nil
local show3DRoute = Config.DefaultEnableRoute

-- 起動処理（設定の読み込み＆postals.jsonのロード）
CreateThread(function()
    -- 前回の設定（true/false）が保存されていれば復元
    if Config.SavePreference then
        local saved = GetResourceKvpString('map_postal_route_enabled')
        if saved ~= nil then
            show3DRoute = (saved == 'true')
        end
    end

    -- postals.json を読み込み
    local rawJson = LoadResourceFile(GetCurrentResourceName(), 'postals.json')
    if rawJson then
        postals = json.decode(rawJson)
        print('^2[Map Postal] 番地データを正常に読み込みました。^7')
    else
        print('^1[Map Postal] postals.json が見つかりません！^7')
    end
end)

-- 導線表示状態を切り替える内部関数
local function SetRouteState(state)
    show3DRoute = state
    if Config.SavePreference then
        SetResourceKvp('map_postal_route_enabled', show3DRoute and 'true' or 'false')
    end

    local statusText = show3DRoute and "^2有効 (True)^7" or "^1無効 (False)^7"
    TriggerEvent('chat:addMessage', {
        color = {200, 200, 200},
        args = {"マップ", "道路上の3D導線を " .. statusText .. " に設定しました。"}
    })
end

---------------------------------------------------------------------------
-- コマンド
---------------------------------------------------------------------------

-- 1. /map [番地] コマンド
RegisterCommand('map', function(source, args, rawCommand)
    -- 番地指定がない場合はピンを解除
    if not args[1] then
        if IsWaypointActive() then
            SetWaypointOff()
            TriggerEvent('chat:addMessage', {
                color = {255, 200, 0},
                args = {"マップ", "ピンと導線を削除しました。"}
            })
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 100, 100},
                args = {"使い方", "例: /map 101 （削除は /map のみ）"}
            })
        end
        return
    end

    if not postals then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {"エラー", "番地データが読み込まれていません。"}
        })
        return
    end

    local searchCode = tostring(args[1])
    local targetCoords = nil

    for i = 1, #postals do
        if tostring(postals[i].code) == searchCode then
            targetCoords = vector2(postals[i].x, postals[i].y)
            break
        end
    end

    if targetCoords then
        SetNewWaypoint(targetCoords.x, targetCoords.y)
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 120},
            args = {"マップ", string.format("番地 [%s] へのルート案内を開始しました。", searchCode)}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 100, 100},
            args = {"エラー", string.format("番地 [%s] は見つかりませんでした。", searchCode)}
        })
    end
end, false)

-- 2. /route コマンド（true / false 指定またはトグル切り替え）
RegisterCommand('route', function(source, args, rawCommand)
    if args[1] then
        local param = string.lower(args[1])
        if param == "true" or param == "on" or param == "1" then
            SetRouteState(true)
        elseif param == "false" or param == "off" or param == "0" then
            SetRouteState(false)
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 100, 100},
                args = {"使い方", "/route true または /route false （単体入力で切り替え）"}
            })
        end
    else
        -- 引数なしの場合は反転（Toggle）
        SetRouteState(not show3DRoute)
    end
end, false)

-- チャットサジェスト
TriggerEvent('chat:addSuggestion', '/map', '指定した番地にピンを刺します', {
    { name = "番地", help = "マップ上の番号 (例: 101)" }
})
TriggerEvent('chat:addSuggestion', '/route', '道路上の導線の表示/非表示を切り替えます', {
    { name = "状態", help = "true または false (省略で反転)" }
})

---------------------------------------------------------------------------
-- 3Dポリゴン描画処理
---------------------------------------------------------------------------
local function DrawQuad(p1, p2, p3, p4, r, g, b, a)
    DrawPoly(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, r, g, b, a)
    DrawPoly(p2.x, p2.y, p2.z, p4.x, p4.y, p4.z, p3.x, p3.y, p3.z, r, g, b, a)
    DrawPoly(p1.x, p1.y, p1.z, p3.x, p3.y, p3.z, p2.x, p2.y, p2.z, r, g, b, a)
    DrawPoly(p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, p4.x, p4.y, p4.z, r, g, b, a)
end

CreateThread(function()
    while true do
        -- 導線が「true」かつ「ピンが刺さっている」ときだけ描画
        if show3DRoute and IsWaypointActive() then
            local rawPoints = {}

            if GetPosAlongGpsTypeRoute then
                for dist = 3.0, Config.RenderDistance, Config.SampleStep do
                    local success, nodePos = GetPosAlongGpsTypeRoute(true, dist, 0)
                    if success then
                        table.insert(rawPoints, vector3(nodePos.x, nodePos.y, nodePos.z + 0.25))
                    else
                        break
                    end
                end
            end

            local count = #rawPoints
            if count >= 2 then
                local halfWidth = Config.RibbonWidth * 0.5
                local prevL, prevR = nil, nil

                for i = 1, count - 1 do
                    local p1 = rawPoints[i]
                    local p2 = rawPoints[i + 1]

                    local dx = p2.x - p1.x
                    local dy = p2.y - p1.y
                    local len = math.sqrt(dx * dx + dy * dy)

                    if len > 0.001 then
                        local nx = -dy / len * halfWidth
                        local ny =  dx / len * halfWidth

                        local l1 = prevL or vector3(p1.x - nx, p1.y - ny, p1.z)
                        local r1 = prevR or vector3(p1.x + nx, p1.y + ny, p1.z)
                        local l2 = vector3(p2.x - nx, p2.y - ny, p2.z)
                        local r2 = vector3(p2.x + nx, p2.y + ny, p2.z)

                        DrawQuad(l1, r1, l2, r2, Config.Color.r, Config.Color.g, Config.Color.b, Config.Color.a)

                        prevL = l2
                        prevR = r2
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)