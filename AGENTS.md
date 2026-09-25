# Contexto común

Colección de addons Lua para WoW Forever. Leer `README.md`, `docs/DEVELOPMENT.md` y `docs/BLIZZARD_API.md` antes de cambiar código. El README principal está dirigido a jugadores y se mantiene en español.

- Cada carpeta de addon es instalable de forma independiente. Conservar los nombres de carpetas y las rutas `Interface\\AddOns\\...`.
- Usar la API del cliente y patrones existentes. Compartir criterios y documentación; extraer una biblioteca común solo si existe duplicación real que lo justifique.
- Identificar producto, versión, build e interfaz antes de asumir compatibilidad. Forever no equivale a Classic Era ni a Retail.
- Consultar fuentes de la build correspondiente y registrar en `docs/BLIZZARD_API.md` las limitaciones descubiertas, evidencia, addon afectado y prueba pendiente. No declarar arreglado un fallo por un simple cambio de versión.
- Respetar valores secretos, restricciones de combate y marcos protegidos. No intentar eludirlos. La presencia de una función no garantiza permiso para operar con su resultado.
- Conservar SavedVariables, revisar todos los puntos de inicialización y no sobrescribir datos válidos durante recuperaciones o migraciones.
- `.local/` contiene copias y recuperación privadas. Nunca publicarla, leerla para redactar documentación pública ni usar `git add -f`. No subir WTF, cuentas, GUID reales, listas de jugadores, tokens o rutas personales.
- Trabajar en el repositorio; los enlaces de `Interface/AddOns` apuntan aquí. Las pruebas pueden afectar al cliente local: verificar dentro del juego con `/reload` y reiniciarlo cuando se añadan addons.
- Ejecutar la comprobación de sintaxis y los tests descritos en `docs/DEVELOPMENT.md`. Los tests fuera del juego no validan placas, combate ni persistencia real.
- Cambios pequeños, sin dependencias ni capas compartidas anticipadas. Mantener los tests de lógica afectados y no modificar otros addons sin necesidad.
