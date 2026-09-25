# Desarrollo

## Una única copia de trabajo

El repositorio es el lugar donde se edita, se hacen commits y se publica. `Interface/AddOns` contiene enlaces simbólicos a las carpetas de los addons:

```text
WoW Forever Addons/
├── TDL/                 ← Interface/AddOns/TDL
├── Revenge/             ← Interface/AddOns/Revenge
├── docs/
├── AGENTS.md
└── .local/              (privado, excluido de Git)
```

El juego lee los mismos archivos que editas. No hay que copiar cambios ni mantener dos versiones sincronizadas. GitHub guarda el historial y permite compartirlos; el trabajo diario ocurre en tu clon local.

En este equipo los enlaces ya están preparados. Abre la carpeta **WoW Forever Addons** del escritorio como proyecto en tu editor o en Codex para trabajar también con las instrucciones comunes.

Para preparar otro Mac o una instalación Linux, sustituye las rutas de este ejemplo:

```sh
repo="$HOME/Desktop/WoW Forever Addons"
addons="/Applications/World of Warcraft/_classic_beta_/Interface/AddOns"
ln -s "$repo/TDL" "$addons/TDL"
ln -s "$repo/Revenge" "$addons/Revenge"
```

Los destinos deben estar libres: si ya existen carpetas, conserva antes una copia fuera de `AddOns`. No uses `ln -sf` para reemplazarlas a ciegas. En Windows se puede usar una unión de directorios con `mklink /J`. Si mueves el repositorio, actualiza los enlaces.

## Ciclo de trabajo

1. Edita el addon dentro del repositorio.
2. Comprueba sintaxis y lógica fuera del juego.
3. Usa `/reload` para recargar Lua. Reinicia el cliente al incorporar un addon nuevo o si no detecta cambios del manifiesto.
4. Prueba el comportamiento y la persistencia real con el cliente de la build indicada.
5. Revisa `git diff`, haz commit y push desde este repositorio.

Cambiar de rama cambia inmediatamente los archivos que leerá el próximo `/reload`. Cada addon mantiene su propio `.toc`, versión y SavedVariables. Sus nombres se conservan para que WoW siga encontrando los datos existentes en `WTF`; esos datos no forman parte del repositorio.

## Comprobaciones

Desde la raíz, con Lua 5.1 o LuaJIT instalado:

```sh
luajit -e 'for _, p in ipairs({"TDL/Locales.lua", "TDL/TDL.lua", "Revenge/Revenge.lua", "Revenge/Revenge.test.lua"}) do assert(loadfile(p)) end'
(cd Revenge && luajit Revenge.test.lua)
```

Puedes sustituir `luajit` por `lua5.1`. GitHub Actions ejecuta estas mismas comprobaciones. No emulan la API de WoW: hay que probar TDL, las placas de Revenge, la entrada y salida de combate, los cambios de zona y el guardado tras `/reload` y reinicio en el juego.

## Recuperación privada de esta instalación

Durante la migración se conservaron los originales en `.local/originals/`. Revenge contenía una recuperación específica de un personaje. Sus datos se movieron a un addon local opcional, `.local/WoWForeverLocal/`, enlazado también desde `Interface/AddOns` y excluido de Git.

Revenge funciona sin ese addon; su dependencia es opcional. En este equipo, mantén **WoW Forever Local** activado para conservar la recuperación de la beta. Solo se aplica al personaje configurado, con lista vacía y revisión anterior. No sustituye una copia de seguridad de `WTF` y no garantiza que el cliente corrija su cargador de SavedVariables. Reinicia el juego después de esta migración para que descubra el addon local.

No distribuyas `.local/`. Retira el mecanismo cuando la persistencia nativa se haya validado; conserva antes los datos. Las copias originales son una fotografía de la migración, no una segunda carpeta de trabajo.

## Seguimiento de la API

`docs/BLIZZARD_API.md` mantiene el historial por producto y build, las fuentes y las pruebas pendientes. Una tarea diaria de Codex revisa la versión instalada y el código de la interfaz publicado en la rama `forever` del espejo Gethe/wow-ui-source. La programación está vinculada a esta instalación de Codex; clonar el repositorio no la instala.

La revisión está programada a las **10:00, hora de Madrid**. Para acceder a los archivos locales, el ordenador debe estar encendido y la aplicación ejecutándose; consulta la [documentación de tareas programadas](https://learn.chatgpt.com/docs/automations?surface=app).

Cuando encuentra una build nueva o evidencia relevante, actualiza la documentación y publica únicamente esos cambios, si el estado de Git permite hacerlo sin mezclar trabajo pendiente. No cambia automáticamente el código de los addons ni el número de interfaz de sus `.toc`. No declara una validación en el juego que no se haya realizado. Si una fuente no está disponible, conserva la última evidencia y comunica el bloqueo.
