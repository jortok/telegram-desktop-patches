# Guía de mantenimiento del parche 0002-Disable-saving-restrictions

Este documento explica qué funciones modifica el parche, cómo actualizarlo cuando cambia
el código fuente de Telegram Desktop, y el proceso completo de compilación.

---

## Qué hace el parche

Elimina las restricciones del lado del cliente que impiden:
- Descargar media de Stories protegidas
- Copiar/seleccionar mensajes en canales con `no-forwards`
- Guardar media en chats con restricciones
- Ver el toolbar de selección aunque no se pueda reenviar

El servidor sigue enviando los flags de restricción; el cliente simplemente los ignora.

---

## Funciones modificadas

### `Telegram/SourceFiles/data/data_story.cpp`

| Función | Original | Parcheada |
|---|---|---|
| `Story::canDownloadIfPremium()` | `return !forbidsForward() \|\| _peer->isSelf()` | `return true` |
| `Story::canDownloadChecked()` | comprueba Premium + isSelf | `return true` |

Controlan si el botón de descarga de una Story aparece activo o bloqueado.

---

### `Telegram/SourceFiles/history/history_item.cpp`

| Función | Original | Parcheada |
|---|---|---|
| `HistoryItem::forbidsSaving()` | devuelve `true` si `forbidsForward()` o tiene `ExtendedMedia` | `return false` |

Determina si se puede guardar el media adjunto a un mensaje.

---

### `Telegram/SourceFiles/history/history_inner_widget.cpp`

| Función | Original | Parcheada |
|---|---|---|
| `HistoryInner::hasSelectRestriction()` | comprueba `session().frozen()` + `_sharingDisallowed` + permisos de chat | conserva solo el check de `frozen()` |
| `HistoryInner::hasCopyRestriction()` | `!_peer->allowsForwarding() \|\| item->forbidsForward()` | `return false` |
| `HistoryInner::hasCopyMediaRestriction()` | `hasCopyRestriction(item) \|\| item->forbidsSaving()` | `return false` |

Controla si el usuario puede seleccionar/copiar mensajes en la vista de historial clásica.

> **Variación por versión (importante):** `hasCopyRestriction`/`hasCopyMediaRestriction` de
> `HistoryInner` **desaparecieron en 6.6.4** (no había que parchearlas) pero **reaparecieron con
> lógica de restricción en 6.8.2** → en 6.8.2 sí hay que parchearlas. Verificar en cada versión.

> **Nota importante:** `session().frozen()` devuelve `Main::FreezeInfo`, no `bool`.
> Tiene `explicit operator bool()`, por lo que **no se puede usar `return session().frozen()`**.
> Hay que usar la forma `if (session().frozen()) { return true; } return false;`.

---

### `Telegram/SourceFiles/history/view/history_view_list_widget.cpp`

| Función | Original | Parcheada |
|---|---|---|
| `ListWidget::hasCopyRestriction()` | delega en `_delegate->listCopyRestrictionType()` | `return false` |
| `ListWidget::hasCopyMediaRestriction()` | delega en `_delegate->listCopyMediaRestrictionType()` | `return false` |
| `ListWidget::hasCopyRestrictionForSelected()` | recorre mensajes seleccionados buscando `forbidsForward()` | `return false` |
| `ListWidget::hasSelectRestriction()` | `session().frozen() \|\| delegate != None` | conserva solo el check de `frozen()` (misma nota anterior) |

Vista de mensajes usada en canales y chats normales (no el widget de historial clásico).

---

### `Telegram/SourceFiles/history/view/history_view_top_bar_widget.cpp`

| Función / Línea | Original | Parcheada |
|---|---|---|
| `TopBarWidget::showSelectedState()` | `_selectedCount > 0 && (_canDelete \|\| _canForward \|\| _canSendNow)` | `return _selectedCount > 0` |
| `auto count = ...` en `showSelected()` | `(!canDelete && !canForward && !canSendNow) ? 0 : state.count` | `state.count` |

Sin este cambio, la barra superior de selección desaparece si ninguna acción está disponible,
aunque haya mensajes seleccionados.

---

### `Telegram/SourceFiles/media/view/media_view_overlay_widget.cpp`

| Función | Original | Parcheada |
|---|---|---|
| `OverlayWidget::saveControlLocked()` | devuelve `true` si la Story tiene Premium-lock | `return false` |

Controla si el icono de guardado aparece con candado en el visor de media.

> **Diferencia con 5.10.3:** En versiones anteriores existía `hasCopyMediaRestriction()`.
> En 6.x fue reemplazada por `saveControlLocked()`. Si el parche de una versión anterior
> menciona `hasCopyMediaRestriction` en `media_view_overlay_widget.cpp`, buscar `saveControlLocked`.

---

### `Telegram/SourceFiles/info/media/info_media_provider.cpp`

| Función | Estado por versión |
|---|---|
| `Provider::hasSelectRestriction()` | 6.6.4: ya solo `frozen()`, **no necesitaba parche**. 6.8.2: **volvió** a traer `allowsForwarding()` + chat/channel → **sí hay que parchearla** (conservar solo `frozen()`). |

Esta función fluctúa entre versiones: ≤5.x y 6.8.2 incluyen `allowsForwarding()`; 6.6.4 estaba
limpia. **Verificar siempre** y no asumir el estado de la versión anterior.

---

## Cómo actualizar el parche a una nueva versión

### 1. Identificar qué cambió

Para cada función de la tabla anterior, leer el fuente nuevo y comparar con la versión parcheada:

```bash
# Ver el cuerpo de una función en el fuente nuevo
grep -n "hasSelectRestriction\|hasCopyRestriction\|saveControlLocked\|canDownloadIfPremium\|forbidsSaving" \
    tdesktop-X.Y.Z-full/Telegram/SourceFiles/**/*.cpp
```

Preguntas clave al revisar cada función:
- ¿Sigue existiendo con el mismo nombre?
- ¿Tiene guards nuevos como `session().frozen()`?
- ¿Fue renombrada o dividida en otra función?

### 2. Construir el parche

El parche usa formato unified diff estándar. Para cada función:

```diff
@@ -<linea_old>,<total_old> +<linea_new>,<total_new> @@
 // 3 líneas de contexto antes
-// líneas originales a reemplazar
+// líneas nuevas
 // 3 líneas de contexto después
```

El conteo de líneas del `@@` debe ser exacto:
- `total_old` = líneas de contexto + líneas eliminadas
- `total_new` = líneas de contexto + líneas añadidas

Verificar siempre con dry-run antes de aplicar:

```bash
patch --dry-run --forward --strip=1 \
    -d tdesktop-X.Y.Z-full \
    --input 0002-Disable-saving-restrictions-X.Y.Z.patch
```

`fuzz 1` en el output es aceptable. Cualquier `FAILED` hay que corregirlo.

### 3. Trampas conocidas

- **`session().frozen()` → no es `bool`**: Usar siempre `if (session().frozen()) { return true; }`.
- **`hasCopyRestriction`/`hasCopyMediaRestriction` en `history_inner_widget.cpp`**: fluctúan entre versiones — ausentes/limpias en 6.6.4, pero en 6.8.2 traen lógica de restricción y hay que parchearlas. Verificar siempre.
- **Conteo de líneas `@@`**: Los blancos entre funciones cuentan como líneas de contexto.
  Un error de ±1 en el conteo causa "malformed patch".
- **`minizip` headers**: El `pkg-config` de minizip da `-I/usr/include` pero los headers
  están en `/usr/include/minizip/`. Ver sección de compilación.

---

## Proceso de compilación

### Requisitos de RAM

La compilación requiere **≥ 48 GB** de memoria (RAM + swap). Con menos, `cc1plus` muere por OOM.

Si tienes < 48 GB de RAM, configurar zram antes de compilar:

```bash
sudo modprobe zram
echo 20G | sudo tee /sys/block/zram0/disksize
sudo mkswap /dev/zram0
sudo swapon --priority 100 /dev/zram0
```

Verificar:
```bash
free -h   # Swap debe mostrar ~20G
```

Desactivar después de compilar:
```bash
sudo swapoff /dev/zram0
echo 1 | sudo tee /sys/block/zram0/reset
```

### Compilación (flujo del repo: m4 + makepkg)

Este repo es **autocontenido**. La fuente de verdad es `PKGBUILD.m4`; `make` regenera
`PKGBUILD` a partir de él, y `makepkg` baja el tarball, parchea y compila dentro del repo.

**Mecanismo m4 importante:** la macro `patches` se define como `sha512sum *.patch`, así que
**todos los `*.patch` del directorio** se inyectan en `source=()` y se aplican en `prepare()`.
Los hashes de los parches se autocalculan; solo el sha512 del **tarball** se edita a mano.

```bash
cd ~/git/telegram-desktop-patches

# 1. Dejar UN SOLO 0002-*.patch activo (mover los versionados fuera del dir):
mkdir -p .archive && mv 0002-Disable-saving-restrictions-*.patch .archive/ 2>/dev/null
cp .archive/0002-Disable-saving-restrictions-X.Y.Z.patch 0002-Disable-saving-restrictions.patch

# 2. En PKGBUILD.m4: pkgver=X.Y.Z y pegar el sha512 nuevo del tarball.
#    Obtener el sha512 sin guardar el tarball aparte:
curl -L "https://github.com/telegramdesktop/tdesktop/releases/download/vX.Y.Z/tdesktop-X.Y.Z-full.tar.gz" | sha512sum

# 3. Sincronizar depends/makedepends/build() con el PKGBUILD oficial de Arch de esa versión
#    (6.x necesita tde2e y flags que el .m4 heredado de 5.10.3 no tiene):
#    https://gitlab.archlinux.org/archlinux/packaging/packages/telegram-desktop/-/blob/main/PKGBUILD

# 4. Regenerar PKGBUILD y compilar+instalar:
make            # m4 PKGBUILD.m4 > PKGBUILD
makepkg -si     # baja tarball, prepare() aplica parches, build(), instala
```

### Iterar el parche sin re-descargar (cmake manual)

Tras un `makepkg` el fuente queda extraído en `src/tdesktop-X.Y.Z-full/` dentro del repo. Para
re-probar cambios al parche sin re-bajar:

```bash
cd ~/git/telegram-desktop-patches/src
patch --forward --strip=1 -d tdesktop-X.Y.Z-full \
    --input ../0002-Disable-saving-restrictions.patch
cmake --build build   # reusa el build/ existente
```

### Fix permanente para minizip (Arch Linux) — **OBSOLETO desde 6.9.3**

A partir de 6.9.3, el upstream de tdesktop ya incluye los headers `<minizip/zip.h>` y
`<minizip/unzip.h>` en `Telegram/lib_base/base/zlib_help.h`. El parche
`tdesktop-fix-minizip-includes.patch` (movido a `.archive/`) ya **no se aplica** en el
`prepare()` y se eliminó tanto del `source=()` como de `sha512sums()` del PKGBUILD.m4.

Para versiones ≤ 6.8.2, mantener el fix:
```cmake
foreach(_inc ${DESKTOP_APP_MINIZIP_INCLUDE_DIRS})
    if (EXISTS "${_inc}/minizip/unzip.h")
        target_include_directories(external_minizip SYSTEM INTERFACE "${_inc}/minizip")
    endif()
endforeach()
```

### Instalar

```bash
# Opción A: instalar directo al sistema
sudo cmake --install /tmp/makepkg/telegram-desktop/src/build

# Opción B: crear paquete para pacman (recomendado)
mkdir -p /tmp/tg-pkg
DESTDIR=/tmp/tg-pkg cmake --install /tmp/makepkg/telegram-desktop/src/build
cd /tmp/tg-pkg
sudo tar -cJf /tmp/telegram-desktop-X.Y.Z-patched.pkg.tar.zst --owner=0 --group=0 .
sudo pacman -U /tmp/telegram-desktop-X.Y.Z-patched.pkg.tar.zst
```

### Prevenir actualizaciones automáticas

Añadir a `/etc/pacman.conf`:

```
IgnorePkg = telegram-desktop
```

Así `pacman -Syu` advertirá de la nueva versión pero no la instalará sin permiso explícito.

---

## Checklist para nueva versión

- [ ] Leer `data_story.cpp` → `canDownloadIfPremium` y `canDownloadChecked`
- [ ] Leer `history_item.cpp` → `forbidsSaving`
- [ ] Leer `history_inner_widget.cpp` → `hasSelectRestriction`, **y `hasCopyRestriction`/`hasCopyMediaRestriction` (presentes en 6.8.2, ausentes en 6.6.4)**
- [ ] Leer `history_view_list_widget.cpp` → `hasCopyRestriction`, `hasCopyMediaRestriction`, `hasCopyRestrictionForSelected`, `hasSelectRestriction`
- [ ] Leer `history_view_top_bar_widget.cpp` → `showSelectedState`, asignación de `count`
- [ ] Leer `media_view_overlay_widget.cpp` → buscar `saveControlLocked` (o `hasCopyMediaRestriction` si volvió)
- [ ] Leer `info/media/info_media_provider.cpp` → `hasSelectRestriction` (**en 6.8.2 sí necesita parche**)
- [ ] Verificar que `session().frozen()` se use con `if`, no con `return` directo
- [ ] `patch --dry-run` sin errores (exit 0, sin `FAILED`; `fuzz 1` tolerable)
- [ ] **Un solo `0002-*.patch` en el directorio** antes de `makepkg` (el m4 aplica todos los `*.patch`)
- [ ] `pkgver` y sha512 del tarball actualizados en `PKGBUILD.m4`
- [ ] `depends`/`makedepends`/`build()` sincronizados con el PKGBUILD oficial de Arch de la versión
- [ ] Fix de `minizip/CMakeLists.txt` aplicado (si makepkg no lo cubre)
- [ ] Compilación completa sin errores
