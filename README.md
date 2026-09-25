# WoW Forever Addons

Pequeños addons para disfrutar de Azeroth a tu manera: organizar lo que quieres hacer y recordar a quién te has encontrado por el camino.

Esta colección reúne los addons de [luisjedev](https://github.com/luisjedev) para **World of Warcraft: Forever**. Puedes instalar cada uno por separado.

## Los addons

| Addon | ¿Para qué sirve? | Cómo abrirlo |
| --- | --- | --- |
| **[TDL](TDL)** | Tu lista de tareas dentro del juego. Añade planes, edítalos y marca lo que ya has completado. | Botón del minimapa, `/tdl` o `/todo` |
| **[Revenge](Revenge)** | Guarda una lista de jugadores enemigos y reconoce sus placas con una marca y un estilo especial cuando el juego permite identificarlos. | Botón del minimapa o `/rvg` |

### TDL · Que no se te olvide nada

Misiones pendientes, materiales que reunir o ese plan para tu próxima sesión. Crea, edita, completa y elimina tareas desde una ventana que puedes mover. La lista muestra ocho tareas por página y adapta el idioma al de tu juego.

### Revenge · Algunas caras se recuerdan

Añade al objetivo actual con un clic o escribe su nombre y apellido. Consulta tu lista, elimina entradas y distingue a los jugadores guardados cuando aparecen en las placas de nombre. La interfaz está en español.

## Instalación

1. Descarga el repositorio desde **Code → Download ZIP** y descomprímelo.
2. Copia la carpeta `TDL`, `Revenge` o ambas dentro de `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. Comprueba que queden así: `AddOns/TDL/TDL.toc` y `AddOns/Revenge/Revenge.toc`.
4. Reinicia el juego y activa los addons en la pantalla de selección de personaje.

No copies la carpeta completa del repositorio dentro de `AddOns`. No necesitas instalar herramientas de desarrollo para jugar.

## Estado actual

Los addons están en desarrollo para **WoW Forever beta**, con interfaz `16001`. No se da por hecha su compatibilidad con Retail, Classic Era u otras versiones.

En algunas builds de la beta se han observado problemas al recuperar los datos guardados tras recargar la interfaz o cerrar el juego. Esto puede afectar a las tareas y a la lista de enemigos. Las restricciones del juego también pueden impedir que Revenge identifique a determinados jugadores. Consulta el [registro de compatibilidad](docs/BLIZZARD_API.md) para ver las builds revisadas y lo que sigue pendiente de probar.

## Ideas y problemas

Puedes [abrir una incidencia](https://github.com/luisjedev/wow-forever-addons/issues/new) para proponer mejoras o contar qué falla. Indica el addon, la versión del juego y los pasos para reproducirlo. Si incluyes una captura o un error, elimina antes los datos personales.

Para colaborar con el código, consulta la [guía de desarrollo](docs/DEVELOPMENT.md).

Proyecto independiente, sin afiliación con Blizzard Entertainment. World of Warcraft pertenece a Blizzard Entertainment.
