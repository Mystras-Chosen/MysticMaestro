local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local colors = {
  ["aliceblue"] = "|cfff0f8ff",
  ["antiquewhite"] = "|cfffaebd7",
  ["aqua"] = "|cff00ffff",
  ["aquamarine"] = "|cff7fffd4",
  ["azure"] = "|cfff0ffff",
  ["beige"] = "|cfff5f5dc",
  ["bisque"] = "|cffffe4c4",
  ["black"] = "|cff000000",
  ["blanchedalmond"] = "|cffffebcd",
  ["blue"] = "|cff0000ff",
  ["blueviolet"] = "|cff8a2be2",
  ["brown"] = "|cffa52a2a",
  ["burlywood"] = "|cffdeb887",
  ["cadetblue"] = "|cff5f9ea0",
  ["chartreuse"] = "|cff7fff00",
  ["chocolate"] = "|cffd2691e",
  ["coral"] = "|cffff7f50",
  ["cornflowerblue"] = "|cff6495ed",
  ["cornsilk"] = "|cfffff8dc",
  ["crimson"] = "|cffdc143c",
  ["cyan"] = "|cff00ffff",
  ["darkblue"] = "|cff00008b",
  ["darkcyan"] = "|cff008b8b",
  ["darkgoldenrod"] = "|cffb8860b",
  ["darkgray"] = "|cffa9a9a9",
  ["darkgreen"] = "|cff006400",
  ["darkgrey"] = "|cffa9a9a9",
  ["darkkhaki"] = "|cffbdb76b",
  ["darkmagenta"] = "|cff8b008b",
  ["darkolivegreen"] = "|cff556b2f",
  ["darkorange"] = "|cffff8c00",
  ["darkorchid"] = "|cff9932cc",
  ["darkred"] = "|cff8b0000",
  ["darksalmon"] = "|cffe9967a",
  ["darkseagreen"] = "|cff8fbc8f",
  ["darkslateblue"] = "|cff483d8b",
  ["darkslategray"] = "|cff2f4f4f",
  ["darkslategrey"] = "|cff2f4f4f",
  ["darkturquoise"] = "|cff00ced1",
  ["darkviolet"] = "|cff9400d3",
  ["deeppink"] = "|cffff1493",
  ["deepskyblue"] = "|cff00bfff",
  ["dimgray"] = "|cff696969",
  ["dimgrey"] = "|cff696969",
  ["dodgerblue"] = "|cff1e90ff",
  ["firebrick"] = "|cffb22222",
  ["floralwhite"] = "|cfffffaf0",
  ["forestgreen"] = "|cff228b22",
  ["fuchsia"] = "|cffff00ff",
  ["gainsboro"] = "|cffdcdcdc",
  ["ghostwhite"] = "|cfff8f8ff",
  ["gold"] = "|cffffd700",
  ["goldenrod"] = "|cffdaa520",
  ["gray"] = "|cff808080",
  ["green"] = "|cff008000",
  ["greenyellow"] = "|cffadff2f",
  ["grey"] = "|cff808080",
  ["honeydew"] = "|cfff0fff0",
  ["hotpink"] = "|cffff69b4",
  ["indianred"] = "|cffcd5c5c",
  ["indigo"] = "|cff4b0082",
  ["ivory"] = "|cfffffff0",
  ["khaki"] = "|cfff0e68c",
  ["lavender"] = "|cffe6e6fa",
  ["lavenderblush"] = "|cfffff0f5",
  ["lawngreen"] = "|cff7cfc00",
  ["lemonchiffon"] = "|cfffffacd",
  ["lightblue"] = "|cffadd8e6",
  ["lightcoral"] = "|cfff08080",
  ["lightcyan"] = "|cffe0ffff",
  ["lightgoldenrodyellow"] = "|cfffafad2",
  ["lightgray"] = "|cffd3d3d3",
  ["lightgreen"] = "|cff90ee90",
  ["lightgrey"] = "|cffd3d3d3",
  ["lightpink"] = "|cffffb6c1",
  ["lightsalmon"] = "|cffffa07a",
  ["lightseagreen"] = "|cff20b2aa",
  ["lightskyblue"] = "|cff87cefa",
  ["lightslategray"] = "|cff778899",
  ["lightslategrey"] = "|cff778899",
  ["lightsteelblue"] = "|cffb0c4de",
  ["lightyellow"] = "|cffffffe0",
  ["lime"] = "|cff00ff00",
  ["limegreen"] = "|cff32cd32",
  ["linen"] = "|cfffaf0e6",
  ["magenta"] = "|cffff00ff",
  ["maroon"] = "|cff800000",
  ["mediumaquamarine"] = "|cff66cdaa",
  ["mediumblue"] = "|cff0000cd",
  ["mediumorchid"] = "|cffba55d3",
  ["mediumpurple"] = "|cff9370db",
  ["mediumseagreen"] = "|cff3cb371",
  ["mediumslateblue"] = "|cff7b68ee",
  ["mediumspringgreen"] = "|cff00fa9a",
  ["mediumturquoise"] = "|cff48d1cc",
  ["mediumvioletred"] = "|cffc71585",
  ["midnightblue"] = "|cff191970",
  ["mintcream"] = "|cfff5fffa",
  ["mistyrose"] = "|cffffe4e1",
  ["moccasin"] = "|cffffe4b5",
  ["navajowhite"] = "|cffffdead",
  ["navy"] = "|cff000080",
  ["oldlace"] = "|cfffdf5e6",
  ["olive"] = "|cff808000",
  ["olivedrab"] = "|cff6b8e23",
  ["orange"] = "|cffffa500",
  ["orangered"] = "|cffff4500",
  ["orchid"] = "|cffda70d6",
  ["palegoldenrod"] = "|cffeee8aa",
  ["palegreen"] = "|cff98fb98",
  ["paleturquoise"] = "|cffafeeee",
  ["palevioletred"] = "|cffdb7093",
  ["papayawhip"] = "|cffffefd5",
  ["peachpuff"] = "|cffffdab9",
  ["peru"] = "|cffcd853f",
  ["pink"] = "|cffffc0cb",
  ["plum"] = "|cffdda0dd",
  ["powderblue"] = "|cffb0e0e6",
  ["purple"] = "|cff800080",
  ["red"] = "|cffff0000",
  ["rosybrown"] = "|cffbc8f8f",
  ["royalblue"] = "|cff4169e1",
  ["saddlebrown"] = "|cff8b4513",
  ["salmon"] = "|cfffa8072",
  ["sandybrown"] = "|cfff4a460",
  ["seagreen"] = "|cff2e8b57",
  ["seashell"] = "|cfffff5ee",
  ["sienna"] = "|cffa0522d",
  ["silver"] = "|cffc0c0c0",
  ["skyblue"] = "|cff87ceeb",
  ["slateblue"] = "|cff6a5acd",
  ["slategray"] = "|cff708090",
  ["slategrey"] = "|cff708090",
  ["snow"] = "|cfffffafa",
  ["springgreen"] = "|cff00ff7f",
  ["steelblue"] = "|cff4682b4",
  ["tan"] = "|cffd2b48c",
  ["teal"] = "|cff008080",
  ["thistle"] = "|cffd8bfd8",
  ["tomato"] = "|cffff6347",
  ["turquoise"] = "|cff40e0d0",
  ["violet"] = "|cffee82ee",
  ["wheat"] = "|cfff5deb3",
  ["white"] = "|cffffffff",
  ["whitesmoke"] = "|cfff5f5f5",
  ["yellow"] = "|cffffff00",
  ["yellowgreen"] = "|cff9acd32",
  ["min"] = "|cff03fffb",
  ["med"] = "|cff00c25e",
  ["avg"] = "|cffc29e00",
  ["top"] = "|cffff0000",
  ["2"] = "|cff1eff00",
  ["3"] = "|cff0070dd",
  ["4"] = "|cffa335ee",
  ["5"] = "|cffff8000"
}

function MM:cTxt(text, color)
  return (colors[color] or "|cffffffff") .. text .. "|r"
end

local tGold = MM:cTxt("g","gold")

local function getNameAndID(input)
  local nameRE, idRE
  if type(input) == "number" then
    idRE = input
    nameRE = GetSpellInfo(MYSTIC_ENCHANTS[input].spellID)
  else
    idRE = MM.RE_LOOKUP[input]
    nameRE = input
  end
  return nameRE, idRE
end

local function addLinesTooltip(tt, input)
  local name, reID = getNameAndID(input)
  local stats = MM.db.realm.RE_AH_STATISTICS[name]["current"]
  local dataRE = MYSTIC_ENCHANTS[reID]
  local indicator
  if dataRE then
    mmText = MM:cTxt(dataRE.known and "Known " or "Unknown " , dataRE.known and "green" or "red")
    name = MM:cTxt(name, tostring(dataRE.quality))
    if dataRE.known then
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_green", 64, 64, 16, 16, 0, 1, 0, 1)
    else
      indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_red", 64, 64, 16, 16, 0, 1, 0, 1)
    end
    tt:AppendText("   "..indicator)
  end
  tt:AddDoubleLine("Mystic Maestro:",(mmText and mmText or ""),1,1,0)
  local demoString = MM:cTxt("Min","min").."("..MM:cTxt("Med","med").."/"..MM:cTxt("Mean","avg").."/"..MM:cTxt("Max","top")..")"
  tt:AddDoubleLine("RE: " ..name, (stats and demoString or "None Listed" ))
  if stats ~= nil then
    if stats.latest ~= nil then
      local ttMin = MM:round((stats.minVal or 0.0) / 10000)
      local ttMed = MM:round((stats.medVal or 0.0) / 10000)
      local ttAvg = MM:round((stats.avgVal or 0.0) / 10000)
      local ttTop = MM:round((stats.topVal or 0.0) / 10000)
      tt:AddDoubleLine("("..stats.listed..") Trinket ("..MM:DaysAgoString(stats.latest)..")"
      , MM:cTxt(ttMin,"min")..tGold.." ("..MM:cTxt(ttMed,"med")..tGold.."/"..MM:cTxt(ttAvg,"avg")..tGold.."/"..MM:cTxt(ttTop,"top")..tGold..")"
      , 1, 1, 0)
    end
    if stats.latestOther ~= nil then
      local ttoMin = MM:round((stats.minOther or 0.0) / 10000)
      local ttoMed = MM:round((stats.medOther or 0.0) / 10000)
      local ttoAvg = MM:round((stats.avgOther or 0.0) / 10000)
      local ttoTop = MM:round((stats.topOther or 0.0) / 10000)
      local ttoListed = stats.listedOther or 0.0
      tt:AddDoubleLine("("..ttoListed..") Non-Trinket ("..MM:DaysAgoString(stats.latestOther)..")"
      , MM:cTxt(ttoMin,"min")..tGold.." ("..MM:cTxt(ttoMed,"med")..tGold.."/"..MM:cTxt(ttoAvg,"avg")..tGold.."/"..MM:cTxt(ttoTop,"top")..tGold..")"
      , 1, 1, 0)
    end
  end
  tt:AddLine(" ")
end

function MM:TooltipHandlerItem(tooltip)
  local enchant
  enchant = MM:MatchTooltipRE(tooltip)
  if enchant then
    addLinesTooltip(tooltip, enchant)
  end
end

function MM:TooltipHandlerSpell(tooltip)
  local enchant
  enchant = select(3 , tooltip:GetSpell())
  if MYSTIC_ENCHANTS[enchant] == nil then
    local swapID = MM.RE_ID[enchant]
    if swapID and MYSTIC_ENCHANTS[swapID] ~= nil then
      enchant = swapID
    else
      return
    end
  end
  if enchant then
    addLinesTooltip(tooltip, enchant)
  end
end
