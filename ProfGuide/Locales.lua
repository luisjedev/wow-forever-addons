local _, addon = ...
-- Guide content (Data/*.lua) is English only; these tables translate the window chrome.
local translations = {
    esES = {
        ["Leveling"] = "Subida de nivel",
        ["Shopping List"] = "Lista de compras",
        ["Trainers"] = "Instructores",
        ["Extras"] = "Extras",
        ["Previous"] = "Anterior",
        ["Next"] = "Siguiente",
        ["Page %d / %d"] = "Página %d / %d",
        ["Materials:"] = "Materiales:",
        ["Alternative:"] = "Alternativa:",
        ["Show on map"] = "Mostrar en el mapa",
        ["Professions"] = "Profesiones",
        ["Back"] = "Volver",
        ["Now"] = "Ahora",
        ["Done"] = "Hecho",
        ["Not learned"] = "No aprendida",
        ["Based on wow-professions.com · Forever beta"] = "Basado en wow-professions.com · beta de Forever",
        ["Left-click: Open / close"] = "Clic izquierdo: abrir / cerrar",
        ["Drag: Move"] = "Arrastrar: mover",
    },
}
translations.esMX = translations.esES
-- English keys also provide the fallback for unsupported locales or missing text.
addon.L = setmetatable(translations[GetLocale()] or {}, {
    __index = function(_, text) return text end,
})
