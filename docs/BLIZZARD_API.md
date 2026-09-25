# Compatibilidad y limitaciones de la API Lua de Blizzard

Este registro trata de la **API dentro del cliente de WoW**: funciones Lua, eventos, frames, valores secretos y SavedVariables. No trata de la API HTTP de Battle.net.

Se amplía por cada versión y build que afecte a nuestros addons. No pretende certificar todas las versiones históricas de WoW. Una versión comercial puede contener varias builds con diferencias de API aunque el número `Interface` no cambie.

## Referencia actual

| Dato | Valor |
| --- | --- |
| Producto de desarrollo | `wow_classic_beta` · WoW Forever |
| Cliente instalado observado el 25 de septiembre de 2026 | `1.60.1.70009` |
| Interfaz declarada por TDL y Revenge | `16001` |
| Fuente del código de Blizzard | [Gethe/wow-ui-source, rama forever](https://github.com/Gethe/wow-ui-source/tree/forever) |
| Revisión documental consultada | [`bd2470a` · 1.60.1 (70009), 24 de septiembre de 2026](https://github.com/Gethe/wow-ui-source/commit/bd2470aed543f72697a044e989285b6c83e63f73) |
| Última revisión de este registro | 25 de septiembre de 2026 |

La versión instalada procede de la fila del producto `wow_classic_beta` en `.build.info`. El valor de interfaz procede de nuestros `.toc`; no equivale a una prueba en el cliente. En el juego, `/dump GetBuildInfo()` permite contrastar versión, build y número de interfaz.

Gethe es un **espejo comunitario del código de la interfaz de Blizzard**, no un servicio oficial ni una garantía de publicación inmediata. Elegimos `forever` porque su commit identifica la misma build que el cliente instalado. No asumir que la rama `classic_beta` siga representando Forever.

## Historial

| Producto / versión / build | Evidencia | Limitaciones y estado |
| --- | --- | --- |
| Forever beta · 1.60.1 · 69913 | Nota previa incluida en [TDL/README.txt](../TDL/README.txt) | Se documentó un fallo al recuperar SavedVariables tras recarga o salida. Registro histórico del proyecto; no es confirmación oficial ni una nueva reproducción. |
| Forever beta · 1.60.1 · 70009 | Instalación local y revisión de fuentes `bd2470a` | Restricciones de identidad y firmas revisadas en fuentes. Persistencia, combate y placas pendientes de validación dentro de esta build. No se da por corregido el fallo anterior. |

## Forever 1.60.1 · build 70009

| Área | Evidencia o limitación | Impacto y criterio |
| --- | --- | --- |
| Nombre de unidad | `UnitName` declara `SecretWhenUnitNameIdentityRestricted`. | Revenge necesita el nombre para comparar con su lista. Si no es accesible, omitir la identificación; probar el comportamiento en combate y PvP. |
| Identidad y clase | `UnitNameUnmodified`, `UnitClassBase` y `UnitGUID` declaran `SecretWhenUnitIdentityRestricted`. `UnitClassBase` puede no devolver resultados. | No tratar la existencia de la función como permiso para procesar el resultado. Revisar también las rutas de inicialización. |
| Placas de nombre | `C_NamePlate.GetNamePlateForUnit` declara `SecretArguments = "AllowedWhenUntainted"`. | Es una condición sobre los argumentos, no permiso general para modificar cualquier frame. Las estructuras internas que usa Revenge requieren una prueba visual por build. |
| Nombre y apellido | La implementación Camelot de `NameUtil` usa nombre y apellido al componer la identidad. | No trasladar sin comprobar la interpretación nombre/reino de otras ramas. La documentación generada conserva nombres genéricos para los retornos. |
| Datos guardados | La nota histórica de TDL describe un fallo del cargador. Revenge conserva una copia por personaje en una variable de cuenta y admite recuperación local opcional. | Son mitigaciones del proyecto, no evidencia de que Blizzard haya corregido el fallo. Verificar que añadir y borrar entradas persiste tras recarga y reinicio. |
| Dependencias de UI | Revenge declara `Blizzard_NamePlates` y usa `plate.UnitFrame`, `healthBar` y `CompactUnitFrame_UpdateHealthColor`. | Estas referencias se han identificado en nuestro código; no se certifica estabilidad contractual de las estructuras de FrameXML. |

Fuentes de la build exacta: [UnitDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua), [NamePlateDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_APIDocumentationGenerated/NamePlateDocumentation.lua) y [Camelot/NameUtil.lua](https://github.com/Gethe/wow-ui-source/blob/bd2470aed543f72697a044e989285b6c83e63f73/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua).

Blizzard explica el objetivo de los valores secretos en su [artículo sobre combate y addons en Midnight](https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight): ciertos datos pueden presentarse mediante operaciones permitidas sin quedar disponibles para decisiones del addon. Ese artículo da contexto; las restricciones concretas de Forever se contrastan con su propia build.

## Pruebas que faltan en 70009

- **TDL:** crear, editar, completar y borrar tareas; comprobar idioma; recargar y reiniciar sin perder cambios.
- **Revenge:** añadir manualmente y desde objetivo; observar placas al entrar y salir de alcance; comprobar jugadores cuya identidad no sea accesible, combate y cambios de zona.
- **Persistencia de Revenge:** verificar altas y bajas tras `/reload` y reinicio, tanto sin recuperación local como con ella. No realizar pruebas destructivas sobre la lista personal.
- **Errores y taint:** registrar mensaje exacto, pasos, build y contexto si se produce un fallo. Nunca incluir nombres reales, GUID de jugadores o contenido personal de SavedVariables.

## Cómo se mantiene

La revisión diaria de Codex compara la versión instalada y el último commit de la rama `forever` con este registro. También comprueba evidencia nueva relevante para problemas abiertos, aunque la build no cambie. Mantiene separadas la build instalada y la publicada en el espejo.

Ante una novedad, añade una entrada con producto, versión, build, interfaz si está comprobada, fecha, fuente permanente, cambio relevante y addons afectados. Conserva el historial y las conclusiones anteriores en su build. Clasifica la evidencia como **documentada en fuentes**, **reproducida en el juego**, **reporte externo** o **pendiente de verificar**.

El proceso puede documentar automáticamente cambios de firmas y restricciones declaradas. No puede demostrar por sí solo que una función se comporte correctamente durante una sesión de juego. No eleva la compatibilidad ni modifica los `.toc` por el mero hecho de detectar una build nueva.

Si aparecen otras ramas del juego como objetivos del proyecto, tendrán sus propias entradas. No copiar conclusiones de Retail, Classic Era o una beta a otra sin evidencia.
