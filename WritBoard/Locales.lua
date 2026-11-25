local _, addon = ...
-- Writ data (Data.lua) is English only; these tables translate the window chrome.
local translations = {
    esES = {
        ["All"] = "Todos",
        ["In bags"] = "En bolsas",
        ["Item"] = "Objeto",
        ["Rep"] = "Repu",
        ["Profession"] = "Profesión",
        ["Deliver to"] = "Entregar a",
        ["Item price"] = "Precio objeto",
        ["Writ price"] = "Precio contrato",
        ["Total"] = "Total",
        ["Unknown"] = "Desconocido",
        ["Show on map"] = "Mostrar en el mapa",
        ["Journeyman"] = "Oficial",
        ["Expert"] = "Experto",
        ["Artisan"] = "Artesano",
        ["Alchemy"] = "Alquimia",
        ["Blacksmithing"] = "Herrería",
        ["Engineering"] = "Ingeniería",
        ["Leatherworking"] = "Peletería",
        ["Tailoring"] = "Sastrería",
        ["You have %d / %d"] = "Tienes %d / %d",
        ["Skill %d"] = "Habilidad %d",
        ["Price for %d"] = "Precio de %d",
        ["No Auctionator price yet: scan the auction house with Auctionator."] = "Sin precio de Auctionator: escanea la casa de subastas con Auctionator.",
        ["Writs in bags: %d · %d reputation · cost %s"] = "Contratos en bolsas: %d · %d de reputación · coste %s",
        ["%d writs"] = "%d contratos",
        ["Sources: conquestcapped.com and foreverchanges.pro · prices from Auctionator"] = "Fuentes: conquestcapped.com y foreverchanges.pro · precios de Auctionator",
    },
}
translations.esMX = translations.esES
-- English keys also provide the fallback for unsupported locales or missing text.
addon.L = setmetatable(translations[GetLocale()] or {}, {
    __index = function(_, text) return text end,
})
