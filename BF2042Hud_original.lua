behaviour("BF2042Hud")

local COLORS = {}
local LOADOUT_COLORS = {}
local DAMAGE_TIMER = 0
local DAMAGE_MOVE = 0

local TIME_SINCE_LAST_HIT = 0
local TIME_SINCE_LAST_KILL = 0
local KILLSTREAK_TIMER = 0
local PLAYER_KILLSTREAK = 0
local LAST_HIT_POINT = nil
local SQUADMATES = {}
local VIEWPORT_MATRIX = nil

local MAP_BLIPS = {}
local SCREEN_BLIPS = {}
local FLAG_HEADERS = {}
local FLAG_INDICATORS = {}
local FLAG_INDICATOR_STYLES = {}
local FLAG_CAPTURE_STYLES = {}
local MAP_VIEW_RANGE = {}

local MAP_TIMER = 0
local BLIP_TIMER = 0

local BFPrint = function() end

function BF2042Hud:Start()
	-- local existingHud = GameObject.Find("BF2042Hud(Clone)")
	-- if existingHud == nil then existingHud = GameObject.Find("BF2042HudWorkshopBranch(Clone)") end
	-- if existingHud ~= nil and existingHud ~= self.gameObject then
	-- 	GameObject.Destroy(existingHud)
	-- end
	-- print("Found duplicate ! Removing...")

	BFPrint = function(...)
		if not self.script.mutator.GetConfigurationBool("debugMode") then return end
		print(...)
	end

	COLORS = {}
	LOADOUT_COLORS = {}

	--self.targets.canvas.worldCamera = PlayerCamera.activeCamera
	self.enabled = true
	self.overrideState = false
	self.data = self.gameObject.GetComponent(DataContainer)


	COLORS.primary = self.data.GetColor("primary")
	COLORS.secondary = self.data.GetColor("secondary")

	COLORS.blue = self.data.GetColor("blue")

	COLORS.green = self.data.GetColor("green")
    COLORS.dark_green = self.data.GetColor("dark_green")

    COLORS.yellow = self.data.GetColor("yellow")
    COLORS.dark_yellow = self.data.GetColor("dark_yellow")

	COLORS.red = self.data.GetColor("red")
	COLORS.secondary_red = self.data.GetColor("secondary_red")
	COLORS.red2 = self.data.GetColor("red2")
    COLORS.dark_red = self.data.GetColor("dark_red")

	COLORS.text_bright_normal = self.data.GetColor("text_bright_normal")
	COLORS.text_bright_hurt = self.data.GetColor("text_bright_hurt")

	-- LOADOUT_COLORS.ammoText = {}
	-- LOADOUT_COLORS.ammoText.mat = self.targets.weaponAmmoSelected

	--Normal tint
	LOADOUT_COLORS.normal = {}
	LOADOUT_COLORS.normal.primary = COLORS.primary
	LOADOUT_COLORS.normal.primaryDarker = COLORS.primary
	LOADOUT_COLORS.normal.primaryEmissionMat = self.data.GetMaterial("primaryEmission")
	LOADOUT_COLORS.normal.primaryEmissionMatDarker = self.data.GetMaterial("primaryEmissionDarker")
	LOADOUT_COLORS.normal.secondary = COLORS.secondary
	LOADOUT_COLORS.normal.textBright = COLORS.text_bright_normal
	LOADOUT_COLORS.normal.ammoText = {}
	LOADOUT_COLORS.normal.ammoText.mat = self.targets.weaponAmmoNormal

	LOADOUT_COLORS.normal.notSelected = {}
	LOADOUT_COLORS.normal.notSelected.iconMat = self.targets.weaponIconNotSelectedNormal
	LOADOUT_COLORS.normal.notSelected.iconColor = Color.white

	LOADOUT_COLORS.normal.selected = {}
	LOADOUT_COLORS.normal.selected.iconMat = self.targets.weaponIconSelectedNormal
	LOADOUT_COLORS.normal.selected.iconColor = Color(0, 0.9728527, 1, 1)

	--Hurt tint
	LOADOUT_COLORS.hurt = {}
	LOADOUT_COLORS.hurt.primary = COLORS.red
	LOADOUT_COLORS.hurt.primaryDarker = COLORS.red2
	LOADOUT_COLORS.hurt.primaryEmissionMat = self.data.GetMaterial("redEmission")
	LOADOUT_COLORS.hurt.primaryEmissionMatDarker = self.data.GetMaterial("redEmissionDarker")
	--LOADOUT_COLORS.hurt.secondary = COLORS.dark_red
	LOADOUT_COLORS.hurt.secondary = COLORS.secondary_red
	LOADOUT_COLORS.hurt.textBright = COLORS.text_bright_hurt
	LOADOUT_COLORS.hurt.ammoText = {}
	LOADOUT_COLORS.hurt.ammoText.mat = self.targets.weaponAmmoHurt

	LOADOUT_COLORS.hurt.notSelected = {}
	LOADOUT_COLORS.hurt.notSelected.iconMat = self.targets.weaponIconNotSelectedHurt
	LOADOUT_COLORS.hurt.notSelected.iconColor = Color.white
	LOADOUT_COLORS.hurt.notSelected.ammoTextTint = self.targets.weaponIconSelectedHurt

	LOADOUT_COLORS.hurt.selected = {}
	LOADOUT_COLORS.hurt.selected.iconMat = self.targets.weaponIconSelectedHurt
	LOADOUT_COLORS.hurt.selected.iconColor = Color.red

	LOADOUT_COLORS.theme = LOADOUT_COLORS.normal

	DAMAGE_TIMER = 0
	DAMAGE_MOVE = 0

	TIME_SINCE_LAST_HIT = 0
	TIME_SINCE_LAST_KILL = 0
	KILLSTREAK_TIMER = 0
	self.killstreakQueue = 0
	self.playerKillfeedQueue = 0

	LAST_HIT_POINT = Vector3.zero
	self.damageIndicatorImage = self.targets.damageIndicatorContainer.transform.GetChild(0).gameObject.GetComponent(Image)

	SQUADMATES = {}

	--MAP STUFF
	-- VIEWPORT_MATRIX = Matrix4x4.TRS(Vector3(0.5, 0.5, 0.5), Quaternion.identity, Vector3(0.5, 0.5, 0.5))
	-- self.mapCam = self.targets.mapCam
	-- self.mapCam.cullingMask = self.vanillaMapCam.cullingMask
	self.mapImage = self.targets.mapImage

	self.mapImage.texture = Minimap.texture

	self.mapImageRect = self.mapImage.gameObject.GetComponent(RectTransform)


	MAP_VIEW_RANGE = {}
	--MAP_VIEW_RANGE.foot = {mapRange=3500, blipRangeHor=60, blipRangeVer=200}
	MAP_VIEW_RANGE.foot = {mapRange=2000, blipRangeHor=120, blipRangeVer=200}
	MAP_VIEW_RANGE.vehicle = {mapRange=2000, blipRangeHor=80, blipRangeVer=260}
	--MAP_VIEW_RANGE.vehicle = {mapRange=2000, blipRangeHor=30, blipRangeVer=260}
	MAP_VIEW_RANGE.current = MAP_VIEW_RANGE.foot
	self.mapImageRect.sizeDelta = Vector2(MAP_VIEW_RANGE.current.mapRange, MAP_VIEW_RANGE.current.mapRange)

	MAP_BLIPS = {}
	--print(type(Minimap.playerSquadBlipTexture))
	self.targets.actorsTexture.texture = Minimap.actorBlipTexture
	self.targets.playerSquadTexture.texture = Minimap.playerSquadBlipTexture
	self.targets.mapContainer.SetActive(self.script.mutator.GetConfigurationBool("minimap"))
	if self.script.mutator.GetConfigurationBool("minimap") then
		Minimap.SetBlipScale(0.35, 0.35, 0.35)
	-- 	for k, actor in pairs(ActorManager.actors) do
	-- 		local blipData = {}
	-- 		blipData.type = "actor"
	-- 		blipData.target = actor
	-- 		blipData.blip = GameObject.Instantiate(self.targets.actorBlip)
	-- 		blipData.blip.transform.SetParent(actor ~= Player.actor and self.mapImage.transform or self.targets.mapHolder.transform, false)

	-- 		blipData.rect = blipData.blip.GetComponent(RectTransform)
	-- 		if actor.team == Player.team then
	-- 			blipData.image = blipData.blip.transform.GetChild(0).gameObject.GetComponent(Image)
	-- 			blipData.blip.transform.GetChild(1).gameObject.SetActive(false)
	-- 		else
	-- 			blipData.image = blipData.blip.transform.GetChild(1).gameObject.GetComponent(Image)
	-- 			blipData.blip.transform.GetChild(0).gameObject.SetActive(false)
	-- 		end

	-- 		blipData.image.color = COLORS.blue

	-- 		blipData.blip.transform.localPosition = Vector3.zero

	-- 		MAP_BLIPS[#MAP_BLIPS+1] = blipData
	-- 	end
	end

	self.actors = {}
	for k, actor in pairs(ActorManager.actors) do
		actor.onTakeDamage.AddListener(self, "OnDamage")

		local actorData = {
			damageDealtByPlayer = 0,
		}

		self.actors[actor] = actorData
	end

	--print(#ActorManager.vehicles)
	--Vehicle blip creation disabled beacuse of switch to new minimap system
	-- if self.script.mutator.GetConfigurationBool("vehicleBlips") then
	-- 	for k, vehicle in pairs(GameObject.FindObjectsOfType(Vehicle)) do
	-- 		self:CreateVehicleBlip(vehicle)
	-- 	end
	-- 	GameEvents.onVehicleSpawn.AddListener(self, "OnVehicleSpawn")
	-- end

	self.targets.audioSource.SetOutputAudioMixer(AudioMixer.Ingame)
	GameObject.Find("Hitmarker").GetComponent(AudioSource).volume = 0

	self.script.AddValueMonitor("MonitorActiveWeapon", "OnActiveWeaponChange")
	self.script.AddValueMonitor("MonitorLoadoutTheme", "OnLoadoutThemeChange")
	self.script.AddValueMonitor("MonitorPlayerSquad", "OnPlayerSquadChange")
	self.script.AddValueMonitor("MonitorPlayerAmmo", "OnPlayerAmmoChange")
	self.script.AddValueMonitor("MonitorPlayerSpareAmmo", "OnPlayerSpareAmmoChange")
	self.script.AddValueMonitor("MonitorPlayerCamY", "OnPlayerCamYChange")
	GameEvents.onActorSpawn.AddListener(self, "OnSpawn")
	GameEvents.onActorDiedInfo.AddListener(self, "OnActorDied")
	GameEvents.onPlayerDealtDamage.AddListener(self, "OnPlayerDealtDamage")
	GameEvents.onVehicleDestroyed.AddListener(self, "OnVehicleDestroyed")
	GameEvents.onVehicleDisabled.AddListener(self, "OnVehicleDisabled")
	GameEvents.onCapturePointCaptured.AddListener(self, "OnFlagCaptured")
	GameEvents.onCapturePointNeutralized.AddListener(self, "OnFlagNeutralized")
	--GameEvents.onSquadAssignedNewOrder.AddListener(self, "OnSquadNewOrder")

	self.minimapOverlayColor = {
		[Player.team] = Color(COLORS.primary.r, COLORS.primary.g, COLORS.primary.b, 0.7529412),
		[Player.enemyTeam] = Color(COLORS.red.r, COLORS.red.g, COLORS.red.b, 0.7529412),
		[Team.Neutral] = Color(1, 1, 1, 0.7529412),
	}

	SCREEN_BLIPS = {}
	FLAG_HEADERS = {}
	FLAG_INDICATORS = {}
	FLAG_INDICATOR_STYLES = {
		[Player.team] = {
			backgroundColor = COLORS.primary,
			headerColor = COLORS.secondary / 2,
			nearbyFlagColor = COLORS.blue
		},
		[Player.enemyTeam] = {
			backgroundColor = COLORS.red,
			headerColor = COLORS.dark_red / 2,
			nearbyFlagColor = COLORS.red * 1.4
		},
		[Team.Neutral] = {
			backgroundColor = Color.white,
			headerColor = Color.white / 3,
			nearbyFlagColor = Color.white
		},
	}
	FLAG_CAPTURE_STYLES = {
		["defend"] = {
			parent = self.targets.flagCaptureBlip.transform.GetChild(0).gameObject,
			control = self.targets.flagCaptureBlip.transform.GetChild(0).GetChild(1).gameObject.GetComponent(Image),
			header = self.targets.flagCaptureBlip.transform.GetChild(0).GetChild(3).gameObject.GetComponent(Text),
		},
		["neutralize"] = {
			parent = self.targets.flagCaptureBlip.transform.GetChild(1).gameObject,
			control = self.targets.flagCaptureBlip.transform.GetChild(1).GetChild(1).gameObject.GetComponent(Image),
			header = self.targets.flagCaptureBlip.transform.GetChild(1).GetChild(3).gameObject.GetComponent(Text),
		},
		["capture"] = {
			parent = self.targets.flagCaptureBlip.transform.GetChild(2).gameObject,
			control = self.targets.flagCaptureBlip.transform.GetChild(2).GetChild(1).gameObject.GetComponent(Image),
			header = self.targets.flagCaptureBlip.transform.GetChild(2).GetChild(3).gameObject.GetComponent(Text),
		},
	}
	self.targets.blipContainer.SetActive(self.script.mutator.GetConfigurationBool("flagBlips"))
	for k, flag in pairs(ActorManager.capturePoints) do
		--SCREEN BLIPS
		local blip = GameObject.Instantiate(self.targets.flagBlip)
		blip.transform.SetParent(self.targets.blipContainer.transform, false)
		--blip.transform.position = Vector3(100, 100, 0)

		local blipData = {}
		blipData.blip = blip;
		blipData.distanceText = blip.transform.GetChild(3).gameObject.GetComponent(Text)
		blipData.flagNameText = blip.transform.GetChild(5).gameObject.GetComponent(Text)
		blipData.directionImage = blip.transform.GetChild(4).GetChild(0).gameObject.GetComponent(Image)
		blipData.orderAnimation = blip.transform.GetChild(6).gameObject.GetComponent(Animator)
		blipData.isDrawing = false
		blipData.rect = blip.GetComponent(RectTransform)
		blipData.styles = {
			[Player.team] = {
				control = blipData.blip.transform.GetChild(0).GetChild(1).gameObject.GetComponent(Image),
				headerText = blipData.blip.transform.GetChild(0).GetChild(3).gameObject.GetComponent(Text),
				color = COLORS.primary
			},
			[Player.enemyTeam] = {
				control = blipData.blip.transform.GetChild(1).GetChild(1).gameObject.GetComponent(Image),
				headerText = blipData.blip.transform.GetChild(1).GetChild(3).gameObject.GetComponent(Text),
				color = COLORS.red
			},
			[Team.Neutral] = {
				control = blipData.blip.transform.GetChild(2).GetChild(1).gameObject.GetComponent(Image),
				headerText = blipData.blip.transform.GetChild(2).GetChild(3).gameObject.GetComponent(Text),
				color = Color.white
			},
		}

		blipData.trackingId = PlayerHud.RegisterElementTracking(flag.transform.position+Vector3(0, 7.5, 0), blipData.rect, blipData.blip)
		PlayerHud.ClampElementTracking(blipData.trackingId, 62.5, blipData.directionImage.gameObject, blipData.distanceText.gameObject)

		SCREEN_BLIPS[flag] = blipData

		local sub = flag.name:sub(1, 1)
		if FLAG_HEADERS[sub] == nil then
			FLAG_HEADERS[sub] = 1
			blipData.header = FLAG_HEADERS[sub]
		else
			FLAG_HEADERS[sub] = FLAG_HEADERS[sub] + 1
			blipData.header = FLAG_HEADERS[sub]
		end

	end

	for k, flag in pairs(ActorManager.capturePoints) do
		local sub = flag.name:sub(1, 1)
		if FLAG_HEADERS[sub] ~= nil then
			if FLAG_HEADERS[sub] == 1 then
				FLAG_HEADERS[sub] = ""
				SCREEN_BLIPS[flag].header = FLAG_HEADERS[sub]
			end
		end

		--FLAG INDICATORS
		local indicator = GameObject.Instantiate(self.targets.flagIndicator)
		local indicatorData = {
			indicator = indicator,
			animator = indicator.GetComponent(Animator),
			headerText = indicator.transform.GetChild(1).gameObject.GetComponent(Text),
			background = indicator.transform.GetChild(0).gameObject.GetComponent(Image),
			triangle = indicator.transform.GetChild(2).gameObject.GetComponent(Image)
		}

		indicator.transform.SetParent(self.targets.flagIndicatorContainer.transform, false)
		indicatorData.headerText.text = sub..tostring(SCREEN_BLIPS[flag].header)
		--indicatorData.headerText.text = sub..tostring(FLAG_HEADERS[sub])

		FLAG_INDICATORS[flag] = indicatorData
	end


	local loadoutScreenObject = self.transform.Find("LoadoutScreen").gameObject
	if loadoutScreenObject ~= nil and loadoutScreenObject.activeSelf then
		self.loadoutScreen = ScriptedBehaviour.GetScript(loadoutScreenObject)
	else
		self.loadoutScreen = nil
	end

	self.transform.Find("PPVolume").gameObject.SetActive(self.script.mutator.GetConfigurationBool("bloom"))

	MAP_TIMER = 0
	BLIP_TIMER = 0

	self.script.StartCoroutine("FindArmorMutator")
end


function BF2042Hud:OnVehicleDestroyed(vehicle, info)
	if info.sourceActor ~= Player.actor then return end
	self:InstantiateKillstreakObj(self.targets.playerVehicleDestroyedObject)
	self:InstantiatePlayerKillfeedMessageObj("VEHICLE DESTROYED")

	self:PlayerExperienceNonCor(Color.white, "vehicleKill")

	self.targets.killlogAnimator.SetTrigger("start")
	KILLSTREAK_TIMER = 3.17
end

function BF2042Hud:OnVehicleDisabled(vehicle, info)
	if info.sourceActor ~= Player.actor then return end
	self:InstantiatePlayerKillfeedMessageObj("VEHICLE DISABLED")

	self:PlayerExperienceNonCor(Color.white, "vehicleDisable")

	self.targets.killlogAnimator.SetTrigger("start")
	KILLSTREAK_TIMER = 3.17
end

function BF2042Hud:FindArmorMutator()
	coroutine.yield(WaitForSeconds(0.15))

	-- for k, object in pairs(GameObject.FindObjectsOfType(ScriptedBehaviour)) do
	-- 	if string.find(object.gameObject.name:lower(), "armor") then
	-- 		print(object.gameObject.name)
	-- 	end
	-- end

	local armorModObj = GameObject.Find("PlayerArmor")
	if armorModObj ~= nil then
		self.armorMod = ScriptedBehaviour.GetScript(armorModObj)
		self.armorMod:DisableHUD()
	end
end

function BF2042Hud:MonitorPlayerAmmo()
	if Player.actor.activeWeapon == nil then return nil end
	local weapon = Player.actor.activeWeapon.activeSubWeapon ~= nil and Player.actor.activeWeapon.activeSubWeapon or Player.actor.activeWeapon
	return weapon.ammo
end
function BF2042Hud:OnPlayerAmmoChange()
	self:AmmoText()
end
function BF2042Hud:MonitorPlayerSpareAmmo()
	if Player.actor.activeWeapon == nil then return nil end
	local weapon = Player.actor.activeWeapon.activeSubWeapon ~= nil and Player.actor.activeWeapon.activeSubWeapon or Player.actor.activeWeapon
	return weapon.spareAmmo
end
function BF2042Hud:OnPlayerSpareAmmoChange()
	self:AmmoText()
end

-- function BF2042Hud:MonitorPlayerOrder()
-- 	if Player.actor.isDead or Player.squad == nil then print("aaa") return nil end
-- 	print(Player.squad.order)
-- 	return Player.squad.order
-- end
-- function BF2042Hud:OnPlayerOrder(order)
-- 	print("Player order: "..tostring(order))
-- 	if order == nil then return end
-- 	if not (order.type == OrderType.Attack or order.type == OrderType.Defend) then return end
-- 	local blipData = SCREEN_BLIPS[order.targetPoint.capturePoint]
-- 	if blipData == nil then return end
-- 	blipData.orderAnimation.SetTrigger("play")
-- 	self:PlayWithDelay("alert", 0, 1)
-- end

function BF2042Hud:OnSquadNewOrder(squad, order)
	--if squad ~= Player.actor.squad or not self.script.mutator.GetConfigurationBool("flagBlips") then return end
	if squad.leader.team ~= Player.team then return end
	if not (order.type == OrderType.Attack or order.type == OrderType.Defend) then return end
	local blipData = SCREEN_BLIPS[order.targetPoint.capturePoint]
	print(order.targetPoint.capturePoint)
	print(blipData)
	if blipData == nil then return end
	blipData.orderAnimation.SetTrigger("play")
	self:PlayWithDelay("alert", 0, 1)
end

function BF2042Hud:OnFlagCaptured(point, newOwner)
	print(point)
	print(newOwner)
	local isPositive = newOwner == Player.team and true or false
	local teamText = isPositive and "We took " or "Enemy took "
	teamText = teamText..point.name
	local obj = self:CreateMessageObject(isPositive, teamText)

	if newOwner == Player.team and Player.actor.currentCapturePoint == point and not Player.actor.isDead then
		self:InstantiatePlayerKillfeedMessageObj("FLAG CAPTURED")
		self:PlayerExperienceNonCor(Color.white, "flagCapture")

		self:InstantiateKillstreakObj(self.targets.playerFlagCaptureObject)

		self.targets.killlogAnimator.SetTrigger("start")
		KILLSTREAK_TIMER = 3.17
	end
end

function BF2042Hud:OnFlagNeutralized(point, prevOwner)
	local text = ""
	if prevOwner == Player.team then
		text = "!  Enemy Neutralized "..point.name
	else
		text = "!  Neutralized "..point.name

		if Player.actor.currentCapturePoint == point and not Player.actor.isDead then
			self:InstantiatePlayerKillfeedMessageObj("FLAG NEUTRALIZED")
			self:PlayerExperienceNonCor(Color.white, "flagNeutralize")
		
			self.targets.killlogAnimator.SetTrigger("start")
			KILLSTREAK_TIMER = 3.17
		end
	end
	self:InstantiateKillfeedMessageObj(text)

end

function BF2042Hud:CreateMessageObject(positive, messageText)
	local obj = GameObject.Instantiate(self.targets.flagCaptureObject)
	obj.transform.SetParent(self.targets.chatContainer.transform, false)

	local blurColor = positive and Color(0, 0.9960784, 0.9058824, 0.2980392) or Color(1, 0.08018869, 0.09535022, 0.509804)
	obj.transform.GetChild(0).GetChild(0).gameObject.GetComponent(Image).color = blurColor
	obj.transform.GetChild(0).GetChild(1).gameObject.GetComponent(Image).color = blurColor

	local infoColor = positive and LOADOUT_COLORS.normal.primary or LOADOUT_COLORS.hurt.primary

	obj.transform.GetChild(0).GetChild(0).GetChild(0).GetChild(0).gameObject.GetComponent(Image).color = infoColor
	obj.transform.GetChild(0).GetChild(0).GetChild(0).GetChild(1).gameObject.GetComponent(Image).color = infoColor
	local text = obj.transform.GetChild(0).GetChild(1).GetChild(0).gameObject.GetComponent(Text)
	text.color = infoColor

	text.text = messageText

	GameObject.Destroy(obj, 10)

	return obj
end

function BF2042Hud:UILoop()
	if not Player.actor.isDead then
		self:UpdateBlips()
	end
	coroutine.yield(WaitForSeconds(0.033))
	self.script.StartCoroutine("UILoop")
	--BFPrint("UI loop")
end

function BF2042Hud:MapLoop()
	if not Player.actor.isDead then
		self:UpdateMinimap()
	end
	coroutine.yield(WaitForSeconds(1 / self.script.mutator.GetConfigurationInt("minimapUpdateRate")))
	self.script.StartCoroutine("MapLoop")
	--BFPrint("Minimap loop")
end

function BF2042Hud:UpdateBlips(orderInput)
	if BLIP_TIMER > 0 then
		BLIP_TIMER = BLIP_TIMER - Time.deltaTime
		return
	else
		BLIP_TIMER = 0.1
	end

	local camera = PlayerCamera.activeCamera

	local currentFlag = Player.actor.currentCapturePoint

	local halfScreenHeight = Screen.height/2
	local halfScreenWidth = Screen.width/2
	local focusSize = halfScreenHeight/8
	local fixedSize = 0.005

	local flagOrderAssigned = false

	--for k, flag in pairs(ActorManager.capturePoints) do
	for k=1, #ActorManager.capturePoints do
		local flag = ActorManager.capturePoints[k]
		local insideFlag = false
		local distance = Vector3.Distance(Player.actor.position, flag.gameObject.transform.position)

		--Flag blips stuff
		if self.script.mutator.GetConfigurationBool("flagBlips") then
			local dir = flag.gameObject.transform.position - camera.transform.position
			local isInView = Vector3.Dot(camera.transform.forward, dir)
			local shouldDraw = isInView > 0

			if shouldDraw then
				local blipData = SCREEN_BLIPS[flag]
				blipData.blip.gameObject.SetActive(true)
				--local anchorWorldPos = flag.gameObject.transform.position;
				--anchorWorldPos.y = anchorWorldPos.y + 7.5
				--local anchorScreenPos = worldToScreenMatrix.MultiplyPoint(anchorWorldPos)
				--local anchorScreenPos = camera.WorldToScreenPoint(anchorWorldPos)
				local anchorScreenPos = blipData.rect.anchoredPosition
				-- local size = dir.magnitude * fixedSize * camera.fieldOfView
				-- blipData.rect.localScale = Vector3.one * size / 50

				--local clampX = Mathf.Clamp(anchorScreenPos.x, 62.5, Screen.width - 62.5)
				--local clampY = Mathf.Clamp(anchorScreenPos.y, 62.5, Screen.height - 62.5)

				--blipData.blip.gameObject.transform.position = Vector3(clampX, clampY, 0)


				local isInFocus = math.abs(anchorScreenPos.x - halfScreenWidth) < Screen.height and math.abs(anchorScreenPos.y - halfScreenHeight) < Screen.height
				local isInCloseFocus = math.abs(anchorScreenPos.x - halfScreenWidth) < focusSize and math.abs(anchorScreenPos.y - halfScreenHeight) < focusSize

				local style = blipData.styles[flag.owner]

				--blipData.distanceText.gameObject.SetActive(isInFocus)
				--blipData.directionImage.gameObject.SetActive(not isInFocus)
				blipData.flagNameText.gameObject.SetActive(isInCloseFocus)


				if blipData.distanceText.gameObject.activeInHierarchy then
					local distanceText = distance < 20 and Mathf.Round(distance) or Mathf.Round(distance / 10) * 10
					blipData.distanceText.text = distanceText.." m"
					blipData.distanceText.color = style.color
				end

				if blipData.directionImage.gameObject.activeInHierarchy then
					--print("a")
					local vector = PlayerCamera.activeCamera.transform.worldToLocalMatrix.MultiplyVector(-dir)
					local angle = Mathf.Atan2(vector.z, vector.x) * Mathf.Rad2Deg

					local blipPos = blipData.blip.gameObject.transform.position
					blipData.directionImage.transform.parent.rotation = Quaternion.Euler(0, 0, blipPos.y < 0 and -angle or angle)
					blipData.directionImage.color = style.color
				end


				if isInCloseFocus then
					blipData.flagNameText.text = flag.name:upper()
					blipData.flagNameText.color = style.color

					if orderInput and not flagOrderAssigned and Player.squad ~= nil then
						local flags = ActorManager.GetCapturePointsOwnedByTeam(Player.team)
						local source = #flags > 0 and flags[1].neighoursOutgoing[1] or nil

						local order = Order.Create(flag.owner == Player.team and OrderType.Defend or OrderType.Attack, source, flag.neighoursIncoming[1])
						Player.squad.AssignOrder(order)

						blipData.orderAnimation.SetTrigger("play")
						self:PlayWithDelay("alert", 0, 1)
						flagOrderAssigned = true
					end
				end

				for v=0, 2 do
					blipData.blip.transform.GetChild(v).gameObject.SetActive(false)
				end
				style.control.transform.parent.gameObject.SetActive(true)

				style.control.fillAmount = flag.captureProgress
				style.control.color = flag.pendingOwner == Player.team and blipData.styles[Player.team].color or blipData.styles[Player.enemyTeam].color

				local sub = flag.name:sub(1, 1)
				style.headerText.text = sub..tostring(blipData.header)
			else
				SCREEN_BLIPS[flag].blip.gameObject.SetActive(false)
			end
		end

		--Minimap stuff
		if self.script.mutator.GetConfigurationBool("minimap") then

			local colors = FLAG_INDICATOR_STYLES[flag.owner]
			local backgroundColor = colors.backgroundColor
			local headerColor = colors.headerColor


			local indicator = FLAG_INDICATORS[flag]

			indicator.animator.SetBool("insideFlag", flag == currentFlag)

			-- backgroundColor = insideFlag and backgroundColor or backgroundColor / 1.3
			-- backgroundColor.a = 1
			indicator.background.color = backgroundColor
			indicator.triangle.color = backgroundColor

			headerColor.a = 1
			indicator.headerText.color = headerColor
		end
	end

	if currentFlag ~= nil then
		self.targets.mapImage.color = Color.Lerp(self.targets.mapImage.color, self.minimapOverlayColor[currentFlag.owner], 6 * Time.deltaTime)

		self.targets.nearbyFlagText.text = currentFlag.name
		self.targets.nearbyFlagText.color = FLAG_INDICATOR_STYLES[currentFlag.owner].nearbyFlagColor
		self.targets.nearbyFlagTextShadow.SetActive(true)

		local style = nil

		if currentFlag.owner == Player.team and currentFlag.captureProgress == 1 then
			style = FLAG_CAPTURE_STYLES["defend"]
		elseif currentFlag.owner == Player.enemyTeam then
			style = FLAG_CAPTURE_STYLES["neutralize"]
		else
			style = FLAG_CAPTURE_STYLES["capture"]
			style.control.color = currentFlag.pendingOwner == Player.team and COLORS.primary or COLORS.red
		end

		style.control.fillAmount = currentFlag.captureProgress
		local sub = currentFlag.name:sub(1, 1)
		style.header.text = sub..tostring(SCREEN_BLIPS[currentFlag].header)

		for k=0, 2 do
			self.targets.flagCaptureBlip.transform.GetChild(k).gameObject.SetActive(false)
		end
		style.parent.SetActive(true)
		self.targets.flagCaptureBlip.SetActive(true)
	else
		self.targets.mapImage.color = Color.Lerp(self.targets.mapImage.color, self.minimapOverlayColor[Team.Neutral], 6 * Time.deltaTime)
		self.targets.nearbyFlagText.text = ""
		self.targets.nearbyFlagTextShadow.SetActive(false)
		self.targets.flagCaptureBlip.SetActive(false)
	end
end

function BF2042Hud:UpdateMinimap()
	MAP_VIEW_RANGE.current = Player.actor.isSeated and MAP_VIEW_RANGE.vehicle or MAP_VIEW_RANGE.foot
	local size = Vector2(MAP_VIEW_RANGE.current.mapRange, MAP_VIEW_RANGE.current.mapRange)
	self.mapImageRect.sizeDelta = Vector2.Lerp(self.mapImageRect.sizeDelta, size, 6 * Time.deltaTime)

	local normalizedPos = Minimap.camera.WorldToViewportPoint(Player.actor.position)
	local pos = Vector3(-normalizedPos.x * self.mapImageRect.rect.size.x, -normalizedPos.y * self.mapImageRect.rect.size.y, 0)

	local mapOffset = self.mapImageRect.rect.size / 2
	self.mapImage.transform.localPosition = Vector3(pos.x + mapOffset.x, pos.y + mapOffset.y, 0)
	self.targets.mapHolder.transform.eulerAngles = Vector3(0, 0, PlayerCamera.activeCamera.gameObject.transform.eulerAngles.y - Minimap.camera.gameObject.transform.eulerAngles.y)

	-- local fadeTarget = 0.01
	-- local toDelete = {}
	-- for k=1, #MAP_BLIPS do
	-- 	local blip = MAP_BLIPS[k]
	-- 	if blip.type == "actor" then
	-- 		if blip.target == Player.actor then
	-- 			if Player.actor.isSeated and self.script.mutator.GetConfigurationBool("vehicleBlips") then
	-- 				fadeTarget = 0.0
	-- 			else
	-- 				fadeTarget = 1
	-- 				self:UpdateMapBlip(blip.target, blip)
	-- 			end
	-- 		elseif not blip.target.isDead then
	-- 			if ActorManager.ActorDistanceToPlayer(blip.target) < MAP_VIEW_RANGE.current.blipRangeHor then
	-- 			-- local vertDistance, horDistance = self:CalculateDistances(Player.actor.position, blip.target.position)
	-- 			-- if self:InRange(vertDistance, horDistance) then
	-- 				if blip.target.isSeated and self.script.mutator.GetConfigurationBool("vehicleBlips") then
	-- 					fadeTarget = 0.0
	-- 				else
	-- 					if blip.target.team == Player.team then
	-- 						fadeTarget = 1
	-- 						self:UpdateMapBlip(blip.target, blip)
	-- 					else
	-- 						if ActorManager.ActorsCanSeeEachOther(blip.target, Player.actor) then
	-- 							fadeTarget = 1
	-- 							self:UpdateMapBlip(blip.target, blip)
	-- 						else
	-- 							fadeTarget = 0.0
	-- 						end
	-- 					end
	-- 				end
	-- 			else
	-- 				fadeTarget = 0.0
	-- 			end
	-- 		else
	-- 			fadeTarget = 0.0
	-- 		end
	-- 		blip.image.CrossFadeAlpha(fadeTarget, 0.3, false)
	-- 	elseif blip.type == "vehicle" then
	-- 		if not blip.target.isDead then
	-- 			local vertDistance, horDistance = self:CalculateDistances(Player.actor.position, blip.target.gameObject.transform.position)
	-- 			if self:InRange(vertDistance, horDistance) then
	-- 				fadeTarget = 1
	-- 				self:UpdateMapBlip(blip.target, blip)
	-- 			else
	-- 				fadeTarget = 0.0
	-- 			end
	-- 		else
	-- 			fadeTarget = 0.0
	-- 			toDelete[#toDelete+1] = k
	-- 		end
	-- 		blip.image.CrossFadeAlpha(fadeTarget, 0.3, false)
	-- 	end
	-- end
	-- for k=1, #toDelete do
	-- 	GameObject.Destroy(MAP_BLIPS[toDelete[k] - (k-1)].blip.gameObject, 0.3)
	-- 	table.remove(MAP_BLIPS, toDelete[k] - (k-1))
	-- 	--MAP_BLIPS[toDelete[k]] = nil
	-- end
end

function BF2042Hud:InRange(vertDistance, horDistance)
	if (vertDistance < MAP_VIEW_RANGE.current.blipRangeVer and horDistance < MAP_VIEW_RANGE.current.blipRangeHor)
		or (vertDistance > MAP_VIEW_RANGE.current.blipRangeVer and horDistance < MAP_VIEW_RANGE.current.blipRangeHor) then
		return true
	else
		return false
	end
end

function BF2042Hud:CalculateDistances(pos1, pos2)
	return Mathf.Abs(pos1.y - pos2.y), Vector3.Distance(Vector3(pos1.x, 0, pos1.z), Vector3(pos2.x, 0, pos2.z))
end

function BF2042Hud:UpdateMapBlip(k, blip)
	if blip.type == "actor" then
		if k ~= Player.actor then
			blip.blip.gameObject.transform.localPosition = self:WorldToMinimapScreenPosition(k.position)
		end
		local dir = nil
		if k.isSeated then
			if k.activeVehicle.isTurret and k.activeVehicle.hasDriver then
				dir = k.activeVehicle.driver == Player.actor and PlayerCamera.activeCamera.transform.forward or k.activeVehicle.driver.activeSeat.activeWeapon.currentMuzzleTransform.forward
			else
				dir = k.activeVehicle.gameObject.transform.forward
			end
		else
			dir = k.facingDirection
		end
		--local dir = (k.isTurret and k.hasDriver) and (k.driver == Player.actor and PlayerCamera.activeCamera.transform.forward or k.driver.activeSeat.activeWeapon.currentMuzzleTransform.forward) or
		local rot = Quaternion.LookRotation(dir, Vector3.up).eulerAngles
		blip.rect.localRotation = Quaternion.Euler(0, 0, -rot.y + Minimap.camera.gameObject.transform.eulerAngles.y)

		if k.squad == Player.squad then
			blip.image.color = COLORS.green
		else
			blip.image.color = COLORS.blue
		end
		if k.team == Player.enemyTeam then
			blip.image.color = COLORS.red
		end
		--blip.rect.SetAsLastSibling()
	elseif blip.type == "vehicle" then
		blip.blip.gameObject.transform.localPosition = self:WorldToMinimapScreenPosition(k.gameObject.transform.position)
		local dir = (k.isTurret and k.hasDriver) and (k.driver == Player.actor and PlayerCamera.activeCamera.transform.forward or k.driver.activeSeat.activeWeapon.currentMuzzleTransform.forward) or k.gameObject.transform.forward
		local rot = Quaternion.LookRotation(dir, Vector3.up).eulerAngles
		blip.rect.localRotation = Quaternion.Euler(0, 0, -rot.y + Minimap.camera.gameObject.transform.eulerAngles.y)
		if not k.hasDriver then
			blip.image.color = Color.white
			--print("empty", k.name)
		else
			if k.driver.team == Player.team then
				if k.driver.squad == Player.squad then
					blip.image.color = COLORS.green
				else
					blip.image.color = COLORS.blue
				end
			else
				blip.image.color = COLORS.red
			end
		end
	end
	--blip.image.color.a = 0.6078432
end

function BF2042Hud:WorldToMinimapScreenPosition(worldPosition)
	local normalizedPos = Minimap.camera.WorldToViewportPoint(worldPosition)
	--local normalizedPos = self:WorldToViewportPoint(worldPosition)
	local pos = Vector3(normalizedPos.x * self.mapImageRect.rect.size.x, normalizedPos.y * self.mapImageRect.rect.size.y, 0)

	local mapOffset = self.mapImageRect.rect.size / 2

	return Vector3(pos.x - mapOffset.x, pos.y - mapOffset.y, 0)
end

function BF2042Hud:WorldToViewportPoint(point3D)
	local P = Minimap.camera.projectionMatrix
	local V = Minimap.camera.transform.worldToLocalMatrix
	local VP = P * V

	local point4 = Vector4(point3D.x, point3D.y, point3D.z, 1)
	local result4 = VP * point4

	local result = Vector3(result4.x, result4.y, result4.z)

	result = result / -result4.w

	result.x = result.x / 2 + 0.5
	result.y = result.y / 2 + 0.5

	result.z = -result4.w

	return result
end

function BF2042Hud:WorldToScreenPoint(wp)
	local mat = PlayerCamera.activeCamera.projectionMatrix * PlayerCamera.activeCamera.worldToCameraMatrix

	local temp = mat * Vector4(wp.x, wp.y, wp.z, 1.0)

	if temp.w == 0 then
		return Vector3.zero
	else
		temp.x = (temp.x/temp.w + 1.0)*0.5 * PlayerCamera.activeCamera.pixelWidth
		temp.y = (temp.y/temp.w + 1.0)*0.5 * PlayerCamera.activeCamera.pixelHeight
		return Vector3(temp.x, temp.y, wp.z)
	end
end

function BF2042Hud:CreateVehicleBlip(vehicle)
	if not self.script.mutator.GetConfigurationBool("minimap") then return end
	if not self.script.mutator.GetConfigurationBool("vehicleBlips") then return end
	local blipData = {}
	blipData.type = "vehicle"
	blipData.target = vehicle
	blipData.blip = GameObject.Instantiate(self.targets.vehicleBlip)

	blipData.rect = blipData.blip.GetComponent(RectTransform)
	blipData.image = blipData.blip.transform.GetChild(0).gameObject.GetComponent(RawImage)

	blipData.image.texture = vehicle.minimapBlip

	blipData.image.color = Color.white

	blipData.blip.transform.SetParent(self.mapImage.transform, false)

	blipData.blip.transform.localPosition = Vector3.zero

	MAP_BLIPS[#MAP_BLIPS+1] = blipData
end

function BF2042Hud:OnVehicleSpawn(vehicle, spawner)
	self:CreateVehicleBlip(vehicle)
end

function BF2042Hud:MonitorPlayerSquad()
	if Player.squad == nil then return nil end
	return #Player.squad.members
end

function BF2042Hud:Length(table)
	if table == nil then return end
	local count = 0
	for k, val in pairs(table) do
		count = count + 1
	end
	return count
end

function BF2042Hud:SquadUpdate()
	-- if Player.squad == nil then
	-- 	self.targets.squadContainer.SetActive(false)
	-- elseif #Player.squad.members == 0 then
	-- 	self.targets.squadContainer.SetActive(false)
	-- else
	-- 	self.targets.squadContainer.SetActive(true)
	-- end

	local state = PlayerHud.playerOrderState
	if self.targets.squadContainer.activeSelf and Player.squad ~= nil then
		local status = #Player.squad.members > 5 and " + "..(#Player.squad.members-5).." " or " "
		--local text = self.squadText.text
		if state == PlayerOrderState.Goto then
			status = status.."[MOVING]"
		elseif state == PlayerOrderState.Hold then
			status = status.."[HOLDING]"
		elseif state == PlayerOrderState.Follow then
			status = status.."[FOLLOWING]"
		end
		self.targets.squadSizeText.text = status
	end

	-- if self.squadTextTextObj == nil then
	-- 	self.squadTextTextObj = GameObject.Find("Squad Text")
	-- 	self.squadText = self.squadTextTextObj.GetComponent(Text)
	-- else
		
	-- end
end

function BF2042Hud:OnPlayerSquadChange(new)
	-- for k=0, self.targets.squadContainer.transform.childCount-1 do
	-- 	if k ~= self.targets.squadContainer.transform.childCount-2 then
	-- 		GameObject.Destroy(self.targets.squadContainer.transform.GetChild(k).gameObject)
	-- 	end
	-- end
	if new == nil then
		self.targets.squadContainer.gameObject.SetActive(false)
		self.targets.squadSizeText.gameObject.SetActive(false)
		return
	end
	if Player.actor.isDead then return end
	self.targets.squadContainer.gameObject.SetActive(not (new <= 1))
	self.targets.squadSizeText.gameObject.SetActive(new > 1)

	for k, actor in pairs(Player.squad.members) do
		if actor ~= Player.actor then
		if self:Length(SQUADMATES) < 4 then
			if SQUADMATES[actor] == nil then
				local squadmate = {}
				squadmate.obj = GameObject.Instantiate(self.targets.squadmateObj)
				squadmate.obj.transform.SetParent(self.targets.squadContainer.transform, false)

				local posOffset = Vector3(Random.Range(-100, 100) / 1000, 0.05, -0.5)
				local rotOffset = Quaternion.Euler(Random.Range(0, 750) / 100, Random.Range(0, 60) / 100, Random.Range(0, 75) / 100)
				squadmate.actorPortraitImg = squadmate.obj.transform.Find("ActorImage").gameObject.GetComponent(RawImage)
				PortraitGenerator.SetPortraitRenderOffset(posOffset, rotOffset)
				squadmate.actorPortraitImg.texture = PortraitGenerator.RenderTeamPortrait(actor.team)
				PortraitGenerator.ResetPortraitRenderOffset()

				squadmate.healthSlider = squadmate.actorPortraitImg.gameObject.transform.Find("HealthSlider").gameObject.GetComponent(Slider)
				squadmate.healthFill = squadmate.healthSlider.gameObject.transform.Find("Fill Area").GetChild(0).gameObject.GetComponent(Image)
				squadmate.healthBackground = squadmate.healthSlider.gameObject.transform.Find("Background").gameObject.GetComponent(Image)
				squadmate.obj.transform.Find("ActorName").gameObject.GetComponent(Text).text = actor.name
				local backgroundColor = actor.team == Team.Blue and Color(0.06848522, 0.4470753, 0.5377358, 0.8156863) or Color(0.5471698, 0.06452473, 0.06452473, 0.8156863)
				squadmate.obj.transform.Find("ActorBackground").gameObject.GetComponent(Image).color = backgroundColor
				self.targets.squadSizeText.gameObject.transform.SetAsLastSibling()

				SQUADMATES[actor] = squadmate
			end
		end
		end
	end
end

function BF2042Hud:IndexOfKey(table, key)
	if table == nil then return nil end
	local count = 1
	for k, val in pairs(table) do
		if k == key then return count end
		count = count + 1
	end
	return nil
end

function BF2042Hud:OnActorDied(actor, info, isSilent)
	if actor == Player.actor then
		self:ResetSquad()
		self:ClearKilllog()
		return
	end
	print(info.isCriticalHit)
	print(info.sourceWeapon)
	if not isSilent and actor ~= nil and info.sourceActor ~= nil then
		if ActorManager.ActorDistanceToPlayer(actor) < 100 then
			self:InstantiateKillfeedObj(actor, info)
		end
		if info.sourceActor == Player.actor then
			self:InstantiatePlayerKillfeedObj(actor, info)

			local target = info.isCriticalHit and self.targets.headshotKillstreakObject or self.targets.normalKillstreakObject
			self:InstantiateKillstreakObj(target)

			self.targets.killlogAnimator.SetTrigger("start")
			KILLSTREAK_TIMER = 3.17

			PLAYER_KILLSTREAK = PLAYER_KILLSTREAK + 1


			if TIME_SINCE_LAST_KILL > 0 then
				if info.isCriticalHit then
					self:PlayWithDelay("headshotKill", 0.1, 1)
				else
					self:PlayWithDelay("normalKill", 0.1, 1)
				end

				local obj = GameObject.Instantiate(PLAYER_KILLSTREAK == 2 and self.targets.hitmarkerKillDouble or self.targets.hitmarkerKill)
				obj.transform.SetParent(self.targets.hitmarkerContainer.transform, false)
				obj.GetComponent(RectTransform).anchoredPosition = Vector2.zero
				GameObject.Destroy(obj, 0.35)

				TIME_SINCE_LAST_KILL = 0
			end
		else
			if self.actors[actor].damageDealtByPlayer / actor.maxHealth > 0.15 and not Player.actor.isDead then
				self:InstantiatePlayerAssistObj(actor)

				self:PlayerExperienceNonCor(Color(1, 0.07843138, 0.09411765, 1), "assist")


				self:InstantiateKillstreakObj(self.targets.assistObject)

				self.targets.killlogAnimator.SetTrigger("start")
				KILLSTREAK_TIMER = 3.17
			end
		end
		self.actors[actor].damageDealtByPlayer = 0
	end
	if SQUADMATES[actor] ~= nil then
		GameObject.Destroy(SQUADMATES[actor].obj)
		--table.remove(SQUADMATES, self:IndexOfKey(SQUADMATES, actor))
		SQUADMATES[actor] = nil
	end
end

function BF2042Hud:OnPlayerDealtDamage(damageInfo, hitInfo)
	if self:HasSpecialtyWeapon() then return end
	if TIME_SINCE_LAST_HIT > 0 then
		if hitInfo.vehicle ~= nil then
			self.targets.hitmarkerVehicle.SetActive(false)
			self.targets.hitmarkerVehicle.SetActive(true)
		elseif hitInfo.actor ~= nil and damageInfo.healthDamage < hitInfo.actor.health then
			self.targets.hitmarkerNormal.SetActive(false)
			self.targets.hitmarkerNormal.SetActive(true)
		end
		self:PlayWithDelay("hit", 0, 1)
		TIME_SINCE_LAST_HIT = 0
	end
end

function BF2042Hud:PlayWithDelay(clip, delay, volume)
	self.script.StartCoroutine(self:PlaySoundCor(clip, delay, volume))
end

function BF2042Hud:PlaySoundCor(clip, delay, volume)
	return function()
		coroutine.yield(WaitForSeconds(delay))
		local list = self.data.GetAudioClipArray(clip)
		local toPlay = list and list[Mathf.Floor(Random.Range(1, #list+1))] or self.data.GetAudioClip(clip)
		self.targets.audioSource.PlayOneShot(toPlay, volume)
	end
end

function BF2042Hud:OnDamage(actor, source, damageInfo)
	if actor == Player.actor and not actor.isDead then
		DAMAGE_TIMER = 7

		if source ~= nil and source ~= Player.actor then
			self.damageIndicatorImage.gameObject.SetActive(false)

			LAST_HIT_POINT = source.position

			-- local vector = PlayerCamera.activeCamera.transform.worldToLocalMatrix.MultiplyVector(-damageInfo.direction)
			-- local angle = Mathf.Atan2(vector.z, vector.x) * 57.29578
			--print(angle)

			local color = nil
			if damageInfo.healthDamage <= 0 and damageInfo.balanceDamage > 0 then
				color = COLORS.yellow
			elseif damageInfo.healthDamage > 0 then
				color = COLORS.red
				self:PlayWithDelay("playerHit", 0, 1)
			end

			--self.targets.damageIndicatorContainer.rotation = Quaternion.Euler(0, 0, angle)

			self.damageIndicatorImage.color = color
			self.damageIndicatorImage.gameObject.SetActive(true)
		end
	end

	if source ~= Player.actor or actor.isDead then return end


	if actor.team ~= source.team then
		self.actors[actor].damageDealtByPlayer = self.actors[actor].damageDealtByPlayer + damageInfo.healthDamage
	end
end

function BF2042Hud:PlayerKillfeedFullCheck()
	if self.playerKillfeedQueue >= 5 then return false end
	-- if self.targets.killfeedContainer.transform.childCount >= 5 then
	-- 	GameObject.Destroy(self.targets.killfeedContainer.transform.GetChild(0).gameObject)
	-- end
	return true
end
function BF2042Hud:PlayerExperienceFullCheck()
	-- if self.targets.experienceContainer.transform.childCount >= 5 then
	-- 	GameObject.Destroy(self.targets.experienceContainer.transform.GetChild(0).gameObject)
	-- end
	return true
end

function BF2042Hud:InstantiatePlayerAssistObj(actor)
	--if not self:PlayerKillfeedFullCheck() then return end
	local obj = GameObject.Instantiate(self.targets.playerKillfeedObject)
	local actorColor = "<color=#FF2100>"
	local prefix = ""
	obj.transform.GetChild(0).GetChild(0).gameObject.GetComponent(Text).text = prefix..actor.name
	local text = obj.transform.GetChild(0).GetChild(1)
	local textText = text.gameObject.GetComponent(Text)
	textText.text = prefix..actorColor..actor.name.."</color>"
	textText.color = COLORS.blue
	text.GetChild(0).gameObject.GetComponent(Image).color = Color(1, 0.07843138, 0.09411765, 1)

	local background = obj.transform.GetChild(0).GetChild(0).GetChild(0).gameObject.GetComponent(RectTransform)
	background.gameObject.GetComponent(Image).color = Color(1, 0.07843138, 0.09411765, 0.254902)

	obj.transform.SetParent(self.targets.killfeedContainer.transform, false)

	if self.targets.killfeedContainer.transform.childCount >= 6 then
		GameObject.Destroy(self.targets.killfeedContainer.transform.GetChild(0).gameObject)
	end
end

function BF2042Hud:InstantiatePlayerKillfeedMessageObj(text)
	--if not self:PlayerKillfeedFullCheck() then return end
	local obj = GameObject.Instantiate(self.targets.playerKillfeedMessageObject)

	obj.transform.GetChild(0).GetChild(0).gameObject.GetComponent(Text).text = text
	obj.transform.GetChild(0).GetChild(1).gameObject.GetComponent(Text).text = text

	obj.transform.SetParent(self.targets.killfeedContainer.transform, false)
	
	if self.targets.killfeedContainer.transform.childCount >= 6 then
		GameObject.Destroy(self.targets.killfeedContainer.transform.GetChild(0).gameObject)
	end
end

function BF2042Hud:KillstreakCor(target)
return function()
	coroutine.yield(WaitForSeconds(0.2 * self.killstreakQueue * (KILLSTREAK_TIMER == 3.17 and 1 or 0)))
	local obj = GameObject.Instantiate(target)
	obj.transform.SetParent(self.targets.killstreakContainer.transform, false)
end
end
function BF2042Hud:InstantiateKillstreakObj(target)
	if self.killstreakQueue >= 10 then return end
	self.killstreakQueue = self.killstreakQueue + 1
	self.script.StartCoroutine(self:KillstreakCor(target))
	--GameObject.Destroy(obj, 3.5)
end

function BF2042Hud:PlayerKillfeedCor(actor, info)
return function()
	coroutine.yield(WaitForSeconds(0.2 * self.playerKillfeedQueue * (KILLSTREAK_TIMER == 3.17 and 1 or 0)))
	local obj = GameObject.Instantiate(self.targets.playerKillfeedObject)
	local actorColor = actor.team == Player.team and "<color=#00FE00>" or "<color=#FF2100>"
	local itemName = "["
	if Player.actor.isSeated then
		if Player.actor.activeSeat.hasWeapons then
			itemName = itemName..Player.actor.activeVehicle.name.."] "
		else
			itemName = info.sourceWeapon ~= nil and itemName..info.sourceWeapon.weaponEntry.name.."] " or itemName..Player.actor.activeVehicle.name.."] "
		end
	else
		itemName = info.sourceWeapon ~= nil and itemName..info.sourceWeapon.weaponEntry.name.."] " or ""
	end

	local text = obj.transform.GetChild(0).GetChild(1)
	local textText = text.gameObject.GetComponent(Text)
	textText.text = itemName..actorColor..actor.name.."</color>"
	text.GetChild(0).gameObject.GetComponent(Image).color = actor.team == Player.team and Color(0, 0.9960784, 0, 1) or Color(1, 0.07843138, 0.09411765, 1)

	local impostor = obj.transform.GetChild(0).GetChild(0).gameObject
	impostor.GetComponent(Text).text = itemName..actor.name

	local impostorCol = actor.team == Player.team and Color(0, 0.9960784, 0, 0.254902) or Color(1, 0.07843138, 0.09411765, 0.254902)
	impostor.transform.GetChild(0).gameObject.GetComponent(Image).color = impostorCol
	impostorCol.a = 1
	impostor.transform.GetChild(1).gameObject.GetComponent(Image).color = impostorCol

	obj.transform.SetParent(self.targets.killfeedContainer.transform, false)

	if self.targets.killfeedContainer.transform.childCount >= 6 then
		GameObject.Destroy(self.targets.killfeedContainer.transform.GetChild(0).gameObject)
	end

	local type = ""
	if actor.team == Player.team then
		type = "teamKill"
	else
		type = info.isCriticalHit and "killHeadshot" or "kill"
	end
	self:PlayerExperienceNonCor(impostorCol, type)
end
end
function BF2042Hud:PlayerExperienceNonCor(impostorCol, rewardType)
	--if not self:PlayerExperienceFullCheck() then return end
	local obj = GameObject.Instantiate(self.targets.experienceObject)

	local reward = self.progression:GetRewardForType(rewardType)
	local rewardText = reward ~= 0 and tostring(reward).." XP" or ""

	obj.transform.GetChild(0).GetChild(1).gameObject.GetComponent(Text).text = rewardText
	obj.transform.GetChild(0).GetChild(0).gameObject.GetComponent(Text).text = rewardText

	local impostor = obj.transform.GetChild(0).GetChild(0).gameObject
	impostor.GetComponent(Text).text = rewardText

	impostor.transform.GetChild(1).gameObject.GetComponent(Image).color = impostorCol

	obj.transform.SetParent(self.targets.experienceContainer.transform, false)

	if self.targets.experienceContainer.transform.childCount >= 6 then
		GameObject.Destroy(self.targets.experienceContainer.transform.GetChild(0).gameObject)
	end
end
function BF2042Hud:PlayerExperienceCor(impostorCol, rewardType)
	return function()
		coroutine.yield(WaitForSeconds(0.2 * self.playerKillfeedQueue * (KILLSTREAK_TIMER == 3.17 and 1 or 0)))
		local obj = GameObject.Instantiate(self.targets.experienceObject)

		local reward = self.progression:GetRewardForType(rewardType)
		local rewardText = reward ~= 0 and tostring(reward).." XP" or ""

		obj.transform.GetChild(0).GetChild(0).gameObject.GetComponent(Text).text = rewardText

		local impostor = obj.transform.GetChild(0).GetChild(0).gameObject
		impostor.GetComponent(Text).text = rewardText

		impostor.transform.GetChild(1).gameObject.GetComponent(Image).color = impostorCol

		obj.transform.SetParent(self.targets.experienceContainer.transform, false)
	end
end
function BF2042Hud:InstantiatePlayerKillfeedObj(actor, info)
	--if not self:PlayerKillfeedFullCheck() then return end
	self.playerKillfeedQueue = self.playerKillfeedQueue + 1
	self.script.StartCoroutine(self:PlayerKillfeedCor(actor, info))
	--if actor.team ~= Player.team then
		-- local impostorCol = actor.team == Player.team and Color(0, 0.9960784, 0, 1) or Color(1, 0.07843138, 0.09411765, 1)
		-- local type = ""
		-- if actor.team == Player.team then
		-- 	type = "teamKill"
		-- else
		-- 	type = info.isCriticalHit and "killHeadshot" or "kill"
		-- end
		-- self.script.StartCoroutine(self:PlayerExperienceCor(impostorCol, type))
	--end
	--GameObject.Destroy(obj, 3.5)
end

function BF2042Hud:ClearKilllog()
	KILLSTREAK_TIMER = 0
	self.killstreakQueue = 0
	self.playerKillfeedQueue = 0
	PLAYER_KILLSTREAK = 0
	if self.targets.killfeedContainer.transform.childCount > 0 then
		for k=0, self.targets.killfeedContainer.transform.childCount-1 do
			GameObject.Destroy(self.targets.killfeedContainer.transform.GetChild(k).gameObject)
		end
	end
	if self.targets.experienceContainer.transform.childCount > 0 then
		for k=0, self.targets.experienceContainer.transform.childCount-1 do
			GameObject.Destroy(self.targets.experienceContainer.transform.GetChild(k).gameObject)
		end
	end

	if self.targets.killstreakContainer.transform.childCount > 0 then
		for k=0, self.targets.killstreakContainer.transform.childCount-1 do
			GameObject.Destroy(self.targets.killstreakContainer.transform.GetChild(k).gameObject)
		end
	end
end

function BF2042Hud:InstantiateKillfeedObj(actor, info)
	--local actorColor = actor.team == Player.team and "<color=#00FE00>" or "<color=#FF2100>"
	--local killerColor = killer.team == Player.team and "<color=#00FE00>" or "<color=#FF2100>"
	if self.targets.chatContainer.transform.childCount >= 10 then return end
	local itemName = "["
	if info.sourceActor == actor then
		itemName = "[TERMINATED]"
	elseif info.sourceActor.isSeated then
		if info.sourceActor.activeSeat.hasWeapons then
			itemName = itemName..info.sourceActor.activeVehicle.name.."]"
		else
			itemName = info.sourceWeapon ~= nil and itemName..info.sourceWeapon.weaponEntry.name.."]" or itemName..info.sourceActor.activeVehicle.name.."]"
		end
	else
		itemName = info.sourceWeapon ~= nil and itemName..info.sourceWeapon.weaponEntry.name.."]" or "[KILLED]"
	end

	local target = nil

	if info.sourceActor.team == actor.team and info.sourceActor ~= actor then
		if info.sourceActor.team == Player.team then
			target = self.targets.killfeedObjectPlayerTK
		else
			target = self.targets.killfeedObjectEnemyTK
		end
	elseif info.sourceActor.team == Player.team or info.sourceActor == actor then
		target = self.targets.killfeedObjectPlayerTeam
	else
		target = self.targets.killfeedObjectEnemyTeam
	end

	local obj = GameObject.Instantiate(target)
	local parent = obj.transform.GetChild(0).gameObject.transform

	local killerText = parent.GetChild(0).gameObject.GetComponent(Text)
	local itemText = parent.GetChild(1).gameObject.GetComponent(Text)
	local skull = parent.GetChild(2).gameObject
	local actorText = parent.GetChild(3).gameObject.GetComponent(Text)

	itemText.text = itemName

	if info.sourceActor == actor then
		local targetText = nil
		local otherText = nil
		if actor.team == Player.team then
			targetText = killerText
			otherText = actorText
		else
			targetText = actorText
			otherText = killerText
		end
		targetText.text = actor.name

		otherText.gameObject.SetActive(false)

		targetText.transform.SetAsFirstSibling()

	else
		killerText.text = info.sourceActor.name
		actorText.text = actor.name
	end

	skull.gameObject.SetActive(info.isCriticalHit)

	--obj.transform.GetChild(0).gameObject.GetComponent(Text).text = killerColor..killer.name.."</color> "..itemName..actorColor..actor.name.."</color>"
	obj.transform.SetParent(self.targets.chatContainer.transform, false)
	GameObject.Destroy(obj, 10)
end

function BF2042Hud:InstantiateKillfeedMessageObj(text)
	if self.targets.chatContainer.transform.childCount >= 10 then return end
	local obj = GameObject.Instantiate(self.targets.killfeedMessageObject)
	obj.transform.GetChild(0).gameObject.GetComponent(Text).text = text
	obj.transform.SetParent(self.targets.chatContainer.transform, false)
	GameObject.Destroy(obj, 10)
end

function BF2042Hud:DestroyAfterTime(object, time)
	return function()
		coroutine.yield(WaitForSeconds(time))
		GameObject.Destroy(object)
	end
end

function BF2042Hud:ResetSquad()
	for k, squadmate in pairs(SQUADMATES) do
		GameObject.Destroy(squadmate.obj)
	end
	self.targets.squadContainer.gameObject.SetActive(false)
	self.targets.squadSizeText.gameObject.SetActive(false)
	SQUADMATES = {}
end

function BF2042Hud:MonitorActiveWeapon()
	return Player.actor.activeWeapon
end

function BF2042Hud:OnActiveWeaponChange(new)
	BFPrint("--------------")
	local toDestroy = {}
	local count = 0
	for k = self.targets.loadoutLayout.transform.childCount-1, 0, -1 do
		BFPrint(self.targets.loadoutLayout.transform.childCount-count)
		if self.targets.loadoutLayout.transform.childCount-count > 5 then
			BFPrint(k)
			local obj = self.targets.loadoutLayout.transform.GetChild(k).gameObject
			self.targets.loadoutLayout.transform.GetChild(k).SetParent(nil)
			GameObject.Destroy(obj)
			count = count + 1
		else
			break
		end
	end
	BFPrint(self.targets.loadoutLayout.transform.childCount)
	for k = 0, self.targets.loadoutLayout.transform.childCount-1 do
		if k > 4 then
			table.insert(toDestroy, self.targets.loadoutLayout.transform.GetChild(k).gameObject)
		end
	end
	for k, obj in pairs(toDestroy) do
		obj.transform.SetParent(nil)
		GameObject.Destroy(obj)
	end
	-- for k, obj in pairs(GameObject.FindGameObjectsWithTag("BF2042WeaponSlot")) do
	-- 	obj.transform.GetChild(k).SetParent(nil)
	-- 	GameObject.Destroy(obj)
	-- end
	BFPrint(self.targets.loadoutLayout.transform.childCount)
	if Player.actor.activeSeat == nil then
		for k=0, self.targets.loadoutLayout.transform.childCount-1 do
			self.targets.loadoutLayout.transform.GetChild(k).gameObject.SetActive(false)
		end
		for k=0, 4 do
			self.targets.loadoutLayout.transform.GetChild(k).gameObject.SetActive(Player.actor.weaponSlots[k+1] ~= nil)
		end
	else
		if #Player.actor.activeSeat.weapons > 0 then
			for k=0, self.targets.loadoutLayout.transform.childCount-1 do
				self.targets.loadoutLayout.transform.GetChild(k).gameObject.SetActive(false)
			end
			for k, weapon in pairs(Player.actor.activeSeat.weapons) do
				BFPrint(k, weapon)
				local weaponSlot = GameObject.Instantiate(self.targets.weaponSlot)
				weaponSlot.transform.SetParent(self.targets.loadoutLayout.transform, false)
				--weaponSlot.GetComponent(RectTransform).eulerAngles = Vector3(0, 0, -1.23)
				BFPrint(self.targets.loadoutLayout.transform.childCount)
			end
		else
			for k=0, self.targets.loadoutLayout.transform.childCount-1 do
				self.targets.loadoutLayout.transform.GetChild(k).gameObject.SetActive(false)
			end
			for k=0, 4 do
				self.targets.loadoutLayout.transform.GetChild(k).gameObject.SetActive(Player.actor.weaponSlots[k+1] ~= nil)
			end
		end
	end
	BFPrint("--------------")
	self:UpdateLoadout()

	if new ~= nil then
		self.currentWeaponRole = new.GenerateWeaponRoleFromStats()
	else
		self.currentWeaponRole = nil
	end
end

function BF2042Hud:UpdateLoadout()
	if Player.actor.activeSeat == nil then
		for k=0, self.targets.loadoutLayout.transform.childCount-1 do
			self.targets.loadoutLayout.transform.GetChild(k).gameObject.SetActive(false)
		end
		for k=0, 4 do
			self.targets.loadoutLayout.transform.GetChild(k).gameObject.SetActive(Player.actor.weaponSlots[k+1] ~= nil)
		end
	end
	BFPrint(self.targets.loadoutLayout.transform.childCount)
	for k=0, self.targets.loadoutLayout.transform.childCount-1 do
		BFPrint(k)
		local weapon = nil
		if k < 5 then
			weapon = Player.actor.weaponSlots[k+1]
		elseif k >= 5 and Player.actor.activeSeat ~= nil then
			weapon = Player.actor.activeSeat.weapons[k-4]
		end
		BFPrint(weapon)
		local wep = self.targets.loadoutLayout.transform.GetChild(k).gameObject
		BFPrint(wep)

		if weapon ~= nil then
			wep.transform.GetChild(0).gameObject.GetComponent(Text).text = (weapon.maxAmmo < 0 or weapon.maxSpareAmmo < 0) and "∞" or tostring(weapon.ammo + weapon.spareAmmo)
			wep.transform.GetChild(2).gameObject.GetComponent(Image).sprite = weapon.uiSprite

			BFPrint("Active Weapon: "..tostring(Player.actor.activeWeapon))
			BFPrint("Current Weapon: "..tostring(weapon))
			local check = (Player.actor.isSeated and Player.actor.activeSeat.hasWeapons) and weapon.gameObject == Player.actor.activeWeapon.gameObject or Player.actor.activeWeapon ~= nil and weapon == Player.actor.activeWeapon
			if check then
			--if Player.actor.activeWeapon ~= nil and weapon == Player.actor.activeWeapon then
				wep.GetComponent(Image).color = LOADOUT_COLORS.theme.primaryDarker
				wep.transform.GetChild(0).gameObject.GetComponent(Text).material = LOADOUT_COLORS.theme.ammoText.mat

				wep.transform.GetChild(2).gameObject.GetComponent(Image).material = LOADOUT_COLORS.theme.selected.iconMat
				wep.transform.GetChild(2).gameObject.GetComponent(Image).color = LOADOUT_COLORS.theme.selected.iconColor
			else
				wep.GetComponent(Image).color = LOADOUT_COLORS.theme.secondary
				wep.transform.GetChild(0).gameObject.GetComponent(Text).material = nil

				wep.transform.GetChild(2).gameObject.GetComponent(Image).material = LOADOUT_COLORS.theme.notSelected.iconMat
				wep.transform.GetChild(2).gameObject.GetComponent(Image).color = LOADOUT_COLORS.theme.notSelected.iconColor
			end
			wep.transform.GetChild(0).gameObject.GetComponent(Text).color = LOADOUT_COLORS.theme.primary
			wep.transform.GetChild(1).gameObject.GetComponent(Text).material = LOADOUT_COLORS.theme.primaryEmissionMat
		end
		if k > 4 then
			wep.transform.GetChild(1).gameObject.GetComponent(Text).text = k - 4
		end
	-- elseif Player.actor.activeSeat ~= nil and Player.actor.activeSeat.hasWeapons then
	-- 	if self.targets.loadoutLayout.transform.childCount > 5 then
	-- 		for k=5, self.targets.loadoutLayout.transform.childCount-1 do
	-- 			GameObject.Destroy(self.targets.loadoutLayout.transform.GetChild(k).gameObject)
	-- 		end
	-- 	end
	-- 	for k, weapon in pairs(Player.actor.activeSeat.weapons) do
	-- 		BFPrint(k, weapon)
	-- 		local weaponSlot = GameObject.Instantiate(weapon.gameObject == Player.actor.activeWeapon.gameObject and self.targets.weaponSlotSelected or self.targets.weaponSlot)
	-- 		weaponSlot.transform.SetParent(self.targets.loadoutLayout.transform)
	-- 		weaponSlot.transform.GetChild(0).gameObject.GetComponent(Text).text = (weapon.maxAmmo < 0 or weapon.maxSpareAmmo < 0) and "∞" or tostring(weapon.ammo + weapon.spareAmmo)
	-- 		weaponSlot.transform.GetChild(1).gameObject.GetComponent(Image).sprite = weapon.uiSprite

	-- 		weaponSlot.transform.GetChild(0).gameObject.GetComponent(Text).color = LOADOUT_COLORS.theme.primary
	-- 		weaponSlot.transform.GetChild(2).gameObject.GetComponent(Text).color = LOADOUT_COLORS.theme.primary

	-- 		weaponSlot.transform.GetChild(2).gameObject.GetComponent(Text).text = self.targets.loadoutLayout.transform.childCount - 5

	-- 		--weaponSlot.GetComponent(RectTransform).eulerAngles = Vector3(0, 0, -1.23)
	-- 		BFPrint(self.targets.loadoutLayout.transform.childCount)
	-- 	end
	end

	self.targets.ammo.color = LOADOUT_COLORS.theme.textBright
	self.targets.spareAmmo.color = LOADOUT_COLORS.theme.textBright

	--self.targets.ammo.material = LOADOUT_COLORS.theme.primaryEmissionMat
	--self.targets.spareAmmo.material = LOADOUT_COLORS.theme.primaryEmissionMat


	local separatorColor = Color(LOADOUT_COLORS.theme.primary.r, LOADOUT_COLORS.theme.primary.g, LOADOUT_COLORS.theme.primary.b, 0.33)
	self.targets.separator.color = separatorColor
	self.targets.extraSeparator.color = separatorColor

	self.targets.heatRing.material = LOADOUT_COLORS.theme.primaryEmissionMatDarker
	self.targets.heatRingBackground.color = LOADOUT_COLORS.theme.secondary
	self.targets.heatImage.material = LOADOUT_COLORS.theme.primaryEmissionMat

	-- local blurColor = LOADOUT_COLORS.theme == LOADOUT_COLORS.normal
	-- 	and Color(0.4625756, 0.5188679, 0.5165224, 1)
	-- 	or Color(0.5176471, 0.4637988, 0.4627451, 1)
	for k=0, self.targets.glowContainer.transform.childCount-1 do
		self.targets.glowContainer.transform.GetChild(k).gameObject.GetComponent(Image).color = LOADOUT_COLORS.theme.primary
	end

	for k=1, self.targets.shadowContainer.transform.childCount-1 do
		local shadow = self.targets.shadowContainer.transform.GetChild(k).gameObject
		if k == 1 then
			shadow.SetActive(self.targets.sightText.text ~= "")
		elseif k == 2 then
			shadow.SetActive(self.targets.vehicleNameText.text ~= "")
		end
	end

	self.targets.sightText.material = LOADOUT_COLORS.theme.primaryEmissionMat
	self.targets.vehicleNameText.material = LOADOUT_COLORS.theme.primaryEmissionMat
	self.targets.weaponName.material = LOADOUT_COLORS.theme.primaryEmissionMat

	--self.targets.compassDegreeText.material = LOADOUT_COLORS.theme.primaryEmissionMatDarker
	self.targets.compassDegreeText.color = LOADOUT_COLORS.theme.textBright

	local compassColor = LOADOUT_COLORS.theme == LOADOUT_COLORS.normal
	and Color(0, 0.9960784, 0.9058824, 0.5607843)
	or Color(0.9058824, 0.09411765, 0.003921569, 0.5607843)
	self.targets.compassRenderer.sharedMaterials[1].SetColor("_Color", LOADOUT_COLORS.theme.textBright)
	self.targets.compassArrow.color = LOADOUT_COLORS.theme.textBright

	self.targets.compassImage.color = compassColor

	Canvas.ForceUpdateCanvases()
	self:AmmoText()
end

function BF2042Hud:MonitorLoadoutTheme()
	return LOADOUT_COLORS.theme
end

function BF2042Hud:OnLoadoutThemeChange()
	self:UpdateLoadout()
end

function BF2042Hud:MonitorPlayerCamY()
	if Player.actor.isSeated or Player.actor.isDead or not self.enabled or Player.actor.isDeactivated then
		self.targets.compassContainer.SetActive(false)
	else
		self.targets.compassContainer.SetActive(true)
	end
	return PlayerCamera.activeCamera.transform.eulerAngles.y
end
function BF2042Hud:OnPlayerCamYChange()
	self:UpdateCompass()
end
function BF2042Hud:UpdateCompass()
	local headingAngle = Quaternion.LookRotation(PlayerCamera.activeCamera.gameObject.transform.forward).eulerAngles.y
	headingAngle = Mathf.Floor(headingAngle)

	-- local blend = 0
	-- local dif = Mathf.Abs(self.targets.compassAnimator.GetFloat("compass") - headingAngle/360)
	-- BFPrint(dif)
	-- local dif = 1
	-- if dif >= 0.95 then
	-- 	blend = headingAngle/360
	-- else
	-- 	blend = Mathf.Lerp(self.targets.compassAnimator.GetFloat("compass"), headingAngle/360, 15 * Time.deltaTime)
	-- 	blend = Mathf.MoveTowards(self.targets.compassImage.uvRect.x, headingAngle/360, 15 * Time.deltaTime)
	-- end
	--self.targets.compassImage.uvRect = Rect(Mathf.MoveTowards(self.targets.compassImage.uvRect.x, headingAngle/360, 3 * Time.deltaTime), 0, 1, 1)
	--self.targets.compassImage.uvRect = Rect(headingAngle/360, 0, 1, 1)

	self.targets.compassRenderer.sharedMaterials[1].SetTextureOffset("_MainTex", Vector2((headingAngle/360)+0.00175, -0.28))

	local headingText = ""
	if headingAngle < 45 then
		headingText = tostring(headingAngle).." N"
	end
	if headingAngle >= 45 then
		headingText = tostring(headingAngle).." E"
	end
	if headingAngle >= 135 then
		headingText = tostring(headingAngle).." S"
	end
	if headingAngle >= 225 then
		headingText = tostring(headingAngle).." W"
	end
	if headingAngle >= 315 then
		headingText = tostring(headingAngle).." N"
	end
	if headingAngle == -1 then
		headingText = "0 N"
	end
	self.targets.compassDegreeText.text = headingText
end

function BF2042Hud:HasSpecialtyWeapon()
	return self.loadoutScreen ~= nil and self.loadoutScreen.selectedSpecialty ~= nil and self.loadoutScreen.selectedSpecialty.specialty.CustomCrosshair and Player.actor.activeWeapon ~= nil and Player.actor.activeWeapon.weaponEntry == self.loadoutScreen.selectedSpecialty.weapon
end

function BF2042Hud:Update()
	--GameManager.hudPlayerEnabled = false
	PlayerHud.HideUIElement(UIElement.PlayerHealth)
	PlayerHud.HideUIElement(UIElement.VehicleInfo)
	PlayerHud.HideUIElement(UIElement.VehicleRepairInfo)
	PlayerHud.HideUIElement(UIElement.SquadMemberInfo)
	PlayerHud.HideUIElement(UIElement.SquadOrderLabel)
	PlayerHud.HideUIElement(UIElement.WeaponInfo)
	PlayerHud.HideUIElement(UIElement.DamageVignette)
	PlayerHud.HideUIElement(UIElement.DamageDirectionInfo)
	PlayerHud.HideUIElement(UIElement.Hitmarker)
	PlayerHud.HideUIElement(UIElement.FlagCaptureProgress)
	PlayerHud.HideUIElement(UIElement.OverlayText)
	PlayerHud.HideUIElement(UIElement.KillFeed)

	if not self.overrideState then
		if Player.actor.isDead and not Player.actor.isDeactivated then
			DAMAGE_MOVE = 0
			DAMAGE_TIMER = 0

			TIME_SINCE_LAST_HIT = 0
			TIME_SINCE_LAST_KILL = 0

			self:SetCanvas(false)

			return
		elseif Input.GetKeyDown(KeyCode.End) then
			self.enabled = not self.enabled
			self:SetCanvas(self.enabled)
		end
	end

	self.targets.weaponName.text = (Player.actor.activeWeapon ~= nil and Player.actor.activeWeapon.weaponEntry ~= nil) and Player.actor.activeWeapon.weaponEntry.name or ""
	if self.sightTextTextObj == nil then
		self.sightTextTextObj = GameObject.Find("Ingame UI Container(Clone)/New Ingame UI/Loadout Panel/Loadout Fade Group/Top Panel/Text Panel/Scope Text")
		self.sightText = self.sightTextTextObj.GetComponent(Text)
		print("First")
		print(self.sightText)
	else
		print(self.sightText)
		self.targets.sightText.text = self.sightText.text
	end

	if self.damageVignetteObj == nil then
		self.damageVignetteObj = GameObject.Find("Damage Vignette")
		self.damageVignetteTarget = self.damageVignetteObj.GetComponent(RawImage)
	else
		if Player.actor.health <= 20 then
			self.targets.damageVignette.color = Color.Lerp(self.targets.damageVignette.color, Color(0.3490566, 0, 0, self.damageVignetteTarget.color.a/1.5), 3*Time.deltaTime)
		else
			self.targets.damageVignette.color = Color.Lerp(self.targets.damageVignette.color, Color(0, 0, 0, self.damageVignetteTarget.color.a/1.5), 3*Time.deltaTime)
		end
		if self.damageVignetteTarget.color.a > 0.6 then
			self.targets.bloodScreen.color = Color.Lerp(self.targets.bloodScreen.color, Color(1, 1, 1, self.damageVignetteTarget.color.a/3), 3*Time.deltaTime)
		else
			self.targets.bloodScreen.color = Color.Lerp(self.targets.bloodScreen.color, Color(1, 1, 1, 0), 3*Time.deltaTime)
		end
		self.targets.lensDirt.color = Color(1, 1, 1, self.damageVignetteTarget.color.a/2)
	end

	self.targets.vehicleNameText.text = Player.actor.activeVehicle ~= nil and Player.actor.activeVehicle.name or ""

	--Heat stuff
	local hasHeat = Player.actor.activeWeapon ~= nil and Player.actor.activeWeapon.applyHeat or false
	self.targets.extraGlow.SetActive(hasHeat)
	self.targets.extraSeparator.gameObject.SetActive(hasHeat)
	self.targets.heatContainer.SetActive(hasHeat)
	if hasHeat then
		self.targets.heatRing.fillAmount = Player.actor.activeWeapon.heat
	end

	--self:UpdateCompass()

	if self.script.mutator.GetConfigurationBool("crosshair") then
		local enableCrosshair = true
		if self:HasSpecialtyWeapon() then
			enableCrosshair = false
		elseif Player.actor.isSeated then
			if Player.actor.activeSeat.hasWeapons then
				enableCrosshair = false
			else
				enableCrosshair = true
			end
		else
			enableCrosshair = true
		end

		if enableCrosshair and not Player.actor.isAiming and not Player.actor.isFallenOver and Player.actor.activeWeapon ~= nil  then
			local size = 0
			if self.currentWeaponRole == WeaponRole.Sniper then
				self.targets.crosshairTopArm.SetActive(false)
			else
				self.targets.crosshairTopArm.SetActive(true)
			end

			if self.currentWeaponRole == WeaponRole.Grenade or self.currentWeaponRole == WeaponRole.Melee then
				self.targets.crosshairArms.SetActive(false)
			elseif Player.actor.isSprinting then
				self.targets.crosshairArms.SetActive(false)
			else
				self.targets.crosshairArms.SetActive(true)
			end

			if not Player.actor.isSprinting and (Player.actorIsGrounded and not Player.actor.isParachuteDeployed) then
				-- Calculate the crosshair size based on the current weapon spread angle and the player camera FOV.
				local weapon = Player.actor.activeWeapon
				local fovRatio = (weapon.currentSpreadMaxAngleRadians * Mathf.Rad2Deg) / PlayerCamera.activeCamera.fieldOfView
				size = Mathf.Max(60, fovRatio * Screen.height * 2)
			elseif not Player.actorIsGrounded or Player.actor.isParachuteDeployed then
				size = 200
			else
				size = 120.2
			end

			-- Assign the point and size to the transform.
			self.targets.crosshair.sizeDelta = Vector2.MoveTowards(self.targets.crosshair.sizeDelta, Vector2(size, size), 500 * Time.deltaTime)
			self.targets.crosshair.gameObject.SetActive(true)
		else
			self.targets.crosshair.gameObject.SetActive(false)
		end
	else
		self.targets.crosshair.gameObject.SetActive(false)
	end

	self.targets.healthText.text = Player.actor.activeVehicle == nil and Mathf.Round(Player.actor.health) or Mathf.Round(Player.actor.activeVehicle.health)

	local suitableVehicle = Player.actor.isSeated and not Player.actor.activeVehicle.isTurret and (Player.actor.activeVehicle.isAirplane or Player.actor.activeVehicle.isHelicopter)
	self.targets.radarCone.SetActive(suitableVehicle)
	if suitableVehicle then
		self.targets.radarCone.transform.Rotate(Vector3.forward * 75 * Time.deltaTime)
	end

	if self.damageIndicatorImage.color.a > 0 then
		local dir = LAST_HIT_POINT - PlayerCamera.activeCamera.transform.position

		local vector = PlayerCamera.activeCamera.transform.worldToLocalMatrix.MultiplyVector(dir)
		local angle = Mathf.Atan2(vector.z, vector.x) * 57.29578
		self.targets.damageIndicatorContainer.rotation = Quaternion.Euler(0, 0, angle)
	end

	-- for k, weapon in pairs(Player.actor.weaponSlots) do
	-- 	local wep = self.targets.loadoutLayout.transform.GetChild(k-1).gameObject
	-- 	if weapon.maxAmmo < 0 or weapon.maxSpareAmmo < 0 then
	-- 		wep.transform.GetChild(0).gameObject.GetComponent(Text).text = "∞"
	-- 	else
	-- 		wep.transform.GetChild(0).gameObject.GetComponent(Text).text = tostring(weapon.ammo + weapon.spareAmmo)
	-- 	end
	-- end

	self:SquadUpdate()

	for k, squadmate in pairs(SQUADMATES) do
		squadmate.healthSlider.value = k.health / k.maxHealth

		if k.health <= 60 and k.health > 20 then
			squadmate.healthFill.color = COLORS.yellow
			squadmate.healthBackground.color = COLORS.dark_yellow
		elseif k.health <= 20 then
			squadmate.healthFill.color = COLORS.red
			squadmate.healthBackground.color = COLORS.dark_red
		else
			squadmate.healthFill.color = COLORS.green
			squadmate.healthBackground.color = COLORS.dark_green
		end
	end

	if DAMAGE_TIMER > 0 then
		DAMAGE_MOVE = Mathf.MoveTowards(DAMAGE_MOVE, 1, 4 * Time.deltaTime)
		DAMAGE_TIMER = DAMAGE_TIMER - Time.deltaTime
	else
		DAMAGE_MOVE = Mathf.MoveTowards(DAMAGE_MOVE, 0, 1 * Time.deltaTime)
	end

	if MAP_TIMER > 0 then
		MAP_TIMER = MAP_TIMER - Time.deltaTime
	else
		self:UpdateMinimap()
		MAP_TIMER = 1 / self.script.mutator.GetConfigurationInt("minimapUpdateRate")
	end
	--self:UpdateMinimap()

	-- if BLIP_TIMER > 0 then
	-- 	BLIP_TIMER = BLIP_TIMER - Time.deltaTime
	-- else
	-- 	self:UpdateBlips(Input.GetKeyDown(KeyCode.H))
	-- 	BLIP_TIMER = 0.1
	-- end

	if Player.actor.activeWeapon ~= nil and not Player.actor.activeWeapon.isReloading then
		if (Player.actor.activeSeat ~= nil and not Player.actor.activeSeat.hasWeapons) or not Player.actor.isSeated then
			local weapon = Player.actor.activeWeapon

			local text = ""
			local color = nil

			local selected = false

			local lowOnMag = weapon.ammo <= weapon.maxAmmo * 0.25 and weapon.ammo + weapon.spareAmmo > 0
			
			if lowOnMag and weapon.spareAmmo == 0 then
				color = Color(0.9960784, 0.8509804, 0, 1)
				text = "LOW AMMO"
				selected = true
			elseif lowOnMag then
				color = COLORS.primary
				text = "[R] RELOAD"
				selected = true
			elseif weapon.ammo + weapon.spareAmmo == 0 then
				color = COLORS.red
				text = "OUT OF AMMO"
				selected = true
			end

			if selected then
				self.targets.ammoIndicator.color = color
				self.targets.ammoIndicatorText.color = color

				self.targets.ammoIndicatorText.text = text

				self.targets.ammoIndicator.gameObject.SetActive(true)
			else
				self.targets.ammoIndicator.gameObject.SetActive(false)
			end
		else
			self.targets.ammoIndicator.gameObject.SetActive(false)
		end
	else
		self.targets.ammoIndicator.gameObject.SetActive(false)
	end

	self:UpdateBlips(Input.GetKeyDown(KeyCode.H))

	TIME_SINCE_LAST_HIT = TIME_SINCE_LAST_HIT + Time.deltaTime
	TIME_SINCE_LAST_KILL = TIME_SINCE_LAST_KILL + Time.deltaTime

	if KILLSTREAK_TIMER > 0 then
		KILLSTREAK_TIMER = KILLSTREAK_TIMER - Time.deltaTime
	else
		self:ClearKilllog()
	end

	self.targets.healthSlider.gameObject.GetComponent(RectTransform).sizeDelta = Vector2(self.targets.healthSlider.gameObject.GetComponent(RectTransform).sizeDelta.x, self.data.GetAnimationCurve("healthUpdateCurve").Evaluate(DAMAGE_MOVE))
	self.targets.healthText.gameObject.SetActive(false)
	self.targets.healthText.gameObject.SetActive(true)
	--Canvas.ForceUpdateCanvases()

	-- if Input.GetKeyDown(KeyCode.H) then
	-- 	self:InstantiatePlayerKillfeedMessageObj("YOU SUCK")
	-- 	self:InstantiateKillfeedMessageObj("YOU SUCK")
	-- 	self:CreateMessageObject(false, "YOU SUCK")
	-- 	self:PlayerExperienceNonCor(Color.magenta, "youSuck")
	-- end

	-- if Input.GetKeyDown(KeyCode.K) then
	-- 	LOADOUT_COLORS.theme = LOADOUT_COLORS.normal
	-- end

	local updateArmor = true
	if self.armorMod ~= nil then
		if Player.actor.isSeated then
			if Player.actor.activeSeat.hasWeapons then
				updateArmor = false
			else
				updateArmor = true
			end
		else
			updateArmor = true
		end
	else
		updateArmor = false
	end

	if updateArmor then
		self.targets.armorText.text = Mathf.CeilToInt(self.armorMod.armorHealth)
		self.targets.armorSlider.value = self.armorMod.armorHealth / self.armorMod.maxArmorHealth
	end

	self.targets.armorText.gameObject.SetActive(updateArmor)
	self.targets.armorIcon.gameObject.SetActive(updateArmor)
	self.targets.armorSlider.gameObject.SetActive(updateArmor)

	if Player.actor.health <= 20 then
		LOADOUT_COLORS.theme = LOADOUT_COLORS.hurt
	else
		LOADOUT_COLORS.theme = LOADOUT_COLORS.normal
	end

	local lerp = Player.actor.activeVehicle == nil and Player.actor.health / Player.actor.maxHealth or Player.actor.activeVehicle.health / Player.actor.activeVehicle.maxHealth
	self.targets.healthSlider.value = Mathf.Lerp(self.targets.healthSlider.value, lerp, 9 * Time.deltaTime)

	local fillLerp = Player.actor.activeVehicle == nil
					and	Color.Lerp(self.targets.healthSliderFill.color, self.data.GetGradient("healthFillGradient").Evaluate(1 - lerp), 15 * Time.deltaTime)
					or LOADOUT_COLORS.theme.primary

	local backgroundLerp = Player.actor.activeVehicle == nil
					and Color.Lerp(self.targets.healthSliderBackground.color, self.data.GetGradient("healthBackgroundGradient").Evaluate(1 - lerp), 15 * Time.deltaTime)
					or LOADOUT_COLORS.theme.secondary

	self.targets.healthSliderFill.color = fillLerp
	self.targets.healthSliderBackground.color = backgroundLerp
	self.targets.healthText.color = fillLerp
	local crossParent = self.targets.healthText.gameObject.transform.parent.Find("HealthCross").GetChild(0)
	for k=0, crossParent.childCount-1 do
		crossParent.GetChild(k).gameObject.GetComponent(Image).color = fillLerp
	end
end

function BF2042Hud:SetCanvas(state)
	for k=0, self.gameObject.transform.GetChild(0).childCount-1 do
		self.gameObject.transform.GetChild(0).GetChild(k).gameObject.GetComponent(Canvas).enabled = state
	end
end

function BF2042Hud:AmmoText()
	--local colorString = LOADOUT_COLORS.theme == LOADOUT_COLORS.normal and "#00CDBA" or "#981000"
	local colorString = LOADOUT_COLORS.theme == LOADOUT_COLORS.normal and "#00CDBA" or "#D2534E"
	--print(LOADOUT_COLORS.theme == LOADOUT_COLORS.normal)
	if Player.actor.activeWeapon == nil or (Player.actor.activeWeapon == nil and Player.actor.isSeated and not Player.actor.activeSeat.hasWeapons) then
		--print("yes", Time.time)
		local ammoText = "-"
		self.targets.ammo.text = ammoText
		self.targets.spareAmmo.text = ammoText

		self.targets.extraGlow.SetActive(false)
		self.targets.extraSeparator.gameObject.SetActive(false)
		self.targets.heatContainer.SetActive(false)
		return "-"
	end
	local weapon = Player.actor.activeWeapon.activeSubWeapon ~= nil and Player.actor.activeWeapon.activeSubWeapon or Player.actor.activeWeapon
	local ammo = weapon.ammo
	local maxAmmo = weapon.maxAmmo
	local spareAmmo = weapon.spareAmmo
	local maxSpareAmmo = weapon.maxSpareAmmo
	local ammoText = ""
	local spareAmmoText = ""

	if maxAmmo < 0 or ammo < 0 or maxAmmo >= 99999999 or ammo >= 99999999 then
		ammoText = "∞"
	else
		if ammo < 10 then
			ammoText = "<color="..colorString..">00</color>"..ammo
		elseif ammo < 100 then
			ammoText = "<color="..colorString..">0</color>"..ammo
		else
			ammoText = ammo
		end
	end
	if maxSpareAmmo < 0 or spareAmmo < 0 or maxSpareAmmo >= 99999999 or spareAmmo >= 99999999 then
		spareAmmoText = "∞"
	else
		if spareAmmo < 10 then
			spareAmmoText = "<color="..colorString..">00</color>"..spareAmmo
		elseif spareAmmo < 100 then
			spareAmmoText = "<color="..colorString..">0</color>"..spareAmmo
		else
			spareAmmoText = spareAmmo
		end
	end

	self.targets.ammo.text = ammoText
	self.targets.spareAmmo.text = spareAmmoText


	if not Player.actor.isDead then
		for k=0, self.targets.loadoutLayout.transform.childCount-1 do
			local weapon = nil
			if k < 5 then
				weapon = Player.actor.weaponSlots[k+1]
			elseif k >= 5 and Player.actor.activeSeat ~= nil then
				weapon = Player.actor.activeSeat.weapons[k-4]
			end
			if weapon ~= nil then
				local wep = self.targets.loadoutLayout.transform.GetChild(k).gameObject
				if weapon.maxAmmo < 0 or weapon.maxSpareAmmo < 0 or weapon.maxAmmo >= 99999990 or weapon.maxSpareAmmo >= 99999990  then
					wep.transform.GetChild(0).gameObject.GetComponent(Text).text = "∞"
				else
					wep.transform.GetChild(0).gameObject.GetComponent(Text).text = tostring(weapon.ammo + weapon.spareAmmo)
				end
			end
		end
	end
end

function BF2042Hud:OnSpawn(actor)
	if actor ~= Player.actor then return end
	self.targets.hudAnimator.SetTrigger("spawn")
	self:UpdateLoadout()
	self:ResetSquad()
	self:SetCanvas(self.enabled)
end

function BF2042Hud:GetColors()
	return COLORS
end

function BF2042Hud:GetAudioSource()
	return self.targets.audioSource
end

function BF2042Hud:Contains(table, val)
	for k, value in pairs(table) do
		if value == val then
			return true
		end
	end
	return false
end
