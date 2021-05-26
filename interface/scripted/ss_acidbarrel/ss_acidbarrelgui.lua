require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  itemList = "itemScrollArea.itemList"
	
  defaultCost = config.getParameter("defaultCost", 0)
  upgradeTag = config.getParameter("upgradeTag")
	sb.logInfo(upgradeTag)
  upgradeItem = config.getParameter("upgradeItem")
	
  self.upgradeableItems = {}
  selectedItem = nil
  populateItemList()
	
	repopulateTimer = 1
	
	animation = config.getParameter("animation")
	animationTimer = 0
end

function update(dt)
	repopulateTimer = math.max(0, repopulateTimer - dt)
	if repopulateTimer == 0 then
		itemSelected()
		populateItemList()
		repopulateTimer = 1
	end
	
	if animation then
		animationTimer = (animationTimer + dt / animation.time) % 1
		local frame = math.floor(animationTimer * animation.frames)
		local image = animation.image..":"..frame
		widget.setImage("animatedImage", image)
	end
end

function upgradeCost(itemConfig)
  if itemConfig == nil then return 0 end
	return math.floor(itemConfig.config.upgradeCost or defaultCost)
end

function populateItemList(forceRepop)
  local upgradeableItems = player.itemsWithTag(upgradeTag)
  for i = 1, #upgradeableItems do
    upgradeableItems[i].count = 1
  end

  if forceRepop or not compare(upgradeableItems, self.upgradeableItems) then
    self.upgradeableItems = upgradeableItems
    widget.clearListItems(itemList)
    widget.setButtonEnabled("btnUpgrade", false)

    local showEmptyLabel = true

    for i, item in pairs(self.upgradeableItems) do
      local config = root.itemConfig(item)
			
			showEmptyLabel = false

			local listItem = string.format("%s.%s", itemList, widget.addListItem(itemList))
			local name = config.config.shortdescription

			widget.setText(string.format("%s.itemName", listItem), name)
			widget.setItemSlotItem(string.format("%s.itemIcon", listItem), item)

			local price = upgradeCost(config)
			widget.setData(listItem, {index = i, price = price})
			
			local available = player.hasCountOfItem({name = upgradeItem})
			widget.setVisible(string.format("%s.unavailableoverlay", listItem), available < price)
    end

    selectedItem = nil
    showItem(nil)

    widget.setVisible("emptyLabel", showEmptyLabel)
  end
end

function showItem(item, price)
	local available = player.hasCountOfItem({name = upgradeItem})
  local enableButton = false
	
  if item then
    enableButton = available >= price
    local directive = enableButton and "^green;" or "^red;"
    widget.setText("scourgeCost", string.format("%s%s / %s", directive, available, price))
  else
    widget.setText("scourgeCost", string.format("%s / --", available))
  end

  widget.setButtonEnabled("btnUpgrade", enableButton)
end

function itemSelected()
  local listItem = widget.getListSelected(itemList)
  selectedItem = listItem

  if listItem then
    local itemData = widget.getData(string.format("%s.%s", itemList, listItem))
    local item = self.upgradeableItems[itemData.index]
    showItem(item, itemData.price)
  end
end

function doUpgrade()
  if selectedItem then
    local selectedData = widget.getData(string.format("%s.%s", itemList, selectedItem))
    local item = self.upgradeableItems[selectedData.index]

    if item then
      local consumedItem = player.consumeItem(item, false, true)
			
      if consumedItem then
        local consumedUpgradeItem = player.consumeItem({name = upgradeItem, count = selectedData.price}, false, false)
				
        if consumedUpgradeItem then
					local consumedConfig = root.itemConfig(consumedItem).config
					local newItem = consumedConfig.upgradeItem
					if type(newItem) == "string" then
						newItem = {name = newItem}
					end
					player.giveItem(newItem)
        else
					player.giveItem(consumedItem)
				end
      end
    end
		
    populateItemList(true)
  end
end
