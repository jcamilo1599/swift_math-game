# MIGRATION.md — Pasos manuales para MathGame v2.0.0

Este documento lista **todo lo que NO se puede automatizar** desde código y que tú debes hacer en Xcode / App Store Connect / Apple Developer antes de poder publicar la v2.0.0.

El código fuente de iPhone + iPad ya está completo, integrado al target y **compila** (`xcodebuild ... BUILD SUCCEEDED`). watchOS y Mac están como **código listo** pero requieren que crees los targets en Xcode (no se puede hacer editando `project.pbxproj` a mano sin corromperlo).

> **App Store Connect en español.** Las instrucciones usan los nombres de campo tal como aparecen en App Store Connect en español. Donde un campo pide texto que el código necesita literalmente (los IDs), te doy el valor exacto para copiar/pegar.

---

## 0. Resumen — qué está hecho vs. qué falta

| Área | Estado | Acción tuya |
|---|---|---|
| Arquitectura, SwiftData, progresión, Daily, modos, polish | ✅ Hecho y compilando | Ninguna |
| Localización en/es/pt-BR/fr (todas las strings de UI) | ✅ Hecho | Revisar traducciones AI de fr/pt-BR |
| Audio (10 sonidos `.caf` sintetizados + en el target) | ✅ Hecho | Opcional: reemplazar por sonidos propios (§3) |
| Haptics | ✅ Hecho | Ninguna |
| Game Center (código + capability) | ✅ Hecho | Solo falta registrar IDs en App Store Connect (§4.2) |
| Notificaciones locales (código) | ✅ Hecho | Nada obligatorio (permiso se pide en runtime) |
| Watch app (código) | 🟡 Scaffolding | Crear target (§5) |
| Mac Catalyst | 🟡 Listo para activar | Activar capability (§6) |
| Iconos / paleta de assets | 🟡 Fallback embebido | Agregar colorsets + icono (§7) |
| Screenshots / App Preview | ❌ Manual | Generar (§8) |
| Subida y submit | ❌ Manual | App Store Connect (§9) |

---

## 1. Abrir y verificar

```bash
open MathGame.xcodeproj
# ⌘B para compilar, ⌘R para correr en simulador.
```

La versión ya está en **2.0.0** (build 10) en `project.pbxproj` (`MARKETING_VERSION` y `CURRENT_PROJECT_VERSION`).

> La carpeta `scripts/` contiene los helpers que ya se ejecutaron:
> - `inject_pbxproj.py` + `pbx_plan.json` — registró los 24 `.swift` nuevos en el target.
> - `generate_audio.py` — generó los 10 `.caf` (re-ejecutable para regenerar el audio).
> - `inject_audio_pbxproj.py` — registró los 10 `.caf` en la fase de Resources.
>
> Puedes conservarlos (útiles si agregas más archivos/sonidos) o borrar la carpeta; ya cumplieron su función. Tras `inject_*`, valida con `plutil -lint MathGame.xcodeproj/project.pbxproj`.

---

## 2. Categoría de App Store (¡importante!)

Cambié `INFOPLIST_KEY_LSApplicationCategoryType` de `public.app-category.kids-games` a **`public.app-category.education`**.

**Razón:** la categoría *Kids* de Apple **prohíbe Game Center y enlaces externos**, y tú pediste audiencia universal + leaderboards. Si insistes en la categoría Kids, hay que quitar Game Center y los `Link()` de Ajustes. Decide esto antes de subir.

---

## 3. Archivos de audio (`.caf`) — ✅ YA INCLUIDOS

Los 10 efectos de sonido **ya están creados e integrados al target** en `MathGame/Audio/Resources/` y se copian al bundle (verificado: aparecen en `MathGame.app/*.caf`). Son **sintetizados** (ondas senoidales con envolvente e intervalos musicales) vía `scripts/generate_audio.py`:

| Archivo | Diseño |
|---|---|
| `correct.caf` | Campanita ascendente C5→E5 |
| `wrong.caf` | Zumbido suave descendente (triangular) |
| `level_up.caf` | Arpegio ascendente C5-E5-G5-C6 |
| `streak_milestone.caf` | Dos destellos agudos E6, B6 |
| `daily_complete.caf` | Fanfarria C5-E5-G5 + acorde C6 |
| `tap.caf` | Clic corto suave |
| `navigation.caf` | Blip corto de navegación |
| `achievement.caf` | Tríada brillante sostenida |
| `time_tick.caf` | Tic agudo corto (últimos 5 s) |
| `game_over.caf` | Tres notas descendentes G4-E4-C4 |

`AudioEngine.swift` los precarga por nombre (busca `.caf` → `.m4a` → `.wav`) y respeta el toggle de Ajustes y el modo silencio del sistema (categoría `.ambient`).

**Si quieres reemplazarlos** por sonidos propios (recomendado para una sensación más "cara"):
1. Crea/consigue 10 efectos cortos (< 1 s) con los **mismos nombres** de la tabla.
2. Conviértelos a `.caf`: `afconvert -f caff -d LEI16@44100 input.wav correct.caf`
3. Reemplaza los archivos en `MathGame/Audio/Resources/` (ya están en el target; no hay que reañadirlos).
4. O re-ejecuta `python3 scripts/generate_audio.py` para regenerar los sintetizados.
5. Fuentes libres: freesound.org (CC0), Apple "iOS UI Sounds".

---

## 4. Game Center

El código (`MathGame/Data/GameCenterService.swift`) ya autentica al lanzar y envía scores/achievements, **pero no hace nada hasta que**:

### 4.1 Capability en Xcode — ✅ YA HECHO
- La capability **Game Center** ya está activada: existe `MathGame/MathGame.entitlements` con `com.apple.developer.game-center` y el `project.pbxproj` ya tiene `CODE_SIGN_ENTITLEMENTS` (Debug + Release). No necesitas hacer nada aquí.

### 4.2 Registrar en App Store Connect (en español)

Ruta: **App Store Connect → tu app → Servicios → Game Center**.

> ⚠️ **Los IDs deben copiarse EXACTOS** (distinguen mayúsculas/minúsculas). Fíjate que `timeAttack` va en *camelCase*. Si un ID no coincide con el código, ese envío de puntuación/logro simplemente no aparece (no crashea).

#### A. Clasificaciones (Leaderboards)

Botón **Clasificaciones → (+) → Clasificación única**. Para cada fila, llena:
- **Tipo de clasificación:** Clásica
- **Orden de clasificación de puntuaciones:** *De la más alta a la más baja*
- **Tipo de puntuación / Formato:** *Entero*
- **Nombre de referencia** y **ID de la clasificación** (de la tabla)
- En **Localización** (idioma *Español*): **Nombre para mostrar** (de la tabla) y **Formato de puntuación** = `Entero`, sufijo de unidad `puntos`.

| Nombre de referencia | ID de la clasificación | Nombre para mostrar (ES) |
|---|---|---|
| Reto Diario | `com.faacil.MathGame.leaderboard.daily` | Reto Diario |
| Suma | `com.faacil.MathGame.leaderboard.addition` | Suma |
| Resta | `com.faacil.MathGame.leaderboard.subtraction` | Resta |
| Multiplicación | `com.faacil.MathGame.leaderboard.multiplication` | Multiplicación |
| División | `com.faacil.MathGame.leaderboard.division` | División |
| Cuadrado | `com.faacil.MathGame.leaderboard.power` | Cuadrado |
| Raíz Cuadrada | `com.faacil.MathGame.leaderboard.root` | Raíz Cuadrada |
| Contrarreloj | `com.faacil.MathGame.leaderboard.timeAttack` | Contrarreloj |
| Supervivencia | `com.faacil.MathGame.leaderboard.survival` | Supervivencia |
| Mezclado | `com.faacil.MathGame.leaderboard.mixed` | Mezclado |
| Secuencia | `com.faacil.MathGame.leaderboard.sequence` | Secuencia |

> Recomendado destacar **Reto Diario** como la clasificación principal (es la única con puntuaciones comparables entre usuarios, gracias al seed determinístico por fecha). Para nombres en otros idiomas (en/fr/pt-BR) usa los de `mode.<modo>` en `APP_STORE.md` / `Localizable.xcstrings`.

#### B. Logros (Achievements)

Botón **Logros → (+)**. Por cada fila:
- **Nombre de referencia** e **ID del logro** (tabla).
- **Puntos** (tabla; el total de los 20 es **870/1000**, dentro del límite de Apple).
- **¿Es recurrente?** No.
- **Visibilidad:** *Mostrar* (todos visibles para invitar a completarlos).
- **Imagen del logro:** PNG 1024×1024 (obligatoria por logro — ver nota al final).
- **Localización** (Español): **Título**, **Descripción antes de obtenerlo** y **Descripción después de obtenerlo** (puedes repetir la descripción en ambas).

| Nombre de referencia | ID del logro | Puntos | Título (ES) | Descripción (ES) |
|---|---|---|---|---|
| Primera victoria | `com.faacil.MathGame.achievement.first_win` | 10 | Primera victoria | Termina tu primera partida. |
| Primer reto diario | `com.faacil.MathGame.achievement.first_daily` | 10 | Primer reto diario | Completa un Reto Diario. |
| Impecable | `com.faacil.MathGame.achievement.perfect_daily` | 25 | Impecable | Completa un reto sin errores. |
| Racha 3 | `com.faacil.MathGame.achievement.streak_3` | 20 | Tres seguidos | Racha de 3 días en el Reto Diario. |
| Racha 7 | `com.faacil.MathGame.achievement.streak_7` | 40 | Una semana firme | Racha de 7 días. |
| Racha 30 | `com.faacil.MathGame.achievement.streak_30` | 75 | Un mes seguido | Racha de 30 días. |
| Racha 100 | `com.faacil.MathGame.achievement.streak_100` | 100 | Centenario | Racha de 100 días. |
| 100 aciertos | `com.faacil.MathGame.achievement.correct_100` | 20 | Calentando motores | 100 respuestas correctas. |
| 1000 aciertos | `com.faacil.MathGame.achievement.correct_1000` | 50 | Cerebro calculadora | 1.000 respuestas correctas. |
| 10000 aciertos | `com.faacil.MathGame.achievement.correct_10000` | 100 | Ábaco viviente | 10.000 respuestas correctas. |
| Maestro Suma | `com.faacil.MathGame.achievement.master_addition` | 30 | Maestro de la suma | 500 puntos en Suma. |
| Maestro Resta | `com.faacil.MathGame.achievement.master_subtraction` | 30 | Maestro de la resta | 500 puntos en Resta. |
| Maestro Multiplicación | `com.faacil.MathGame.achievement.master_multiplication` | 30 | Maestro de la multiplicación | 500 puntos en Multiplicación. |
| Maestro División | `com.faacil.MathGame.achievement.master_division` | 30 | Maestro de la división | 500 puntos en División. |
| Maestro Cuadrado | `com.faacil.MathGame.achievement.master_power` | 30 | Maestro del cuadrado | 500 puntos en Cuadrado. |
| Maestro Raíz | `com.faacil.MathGame.achievement.master_root` | 30 | Maestro de la raíz | 500 puntos en Raíz Cuadrada. |
| Superviviente | `com.faacil.MathGame.achievement.survival_50` | 60 | Sobreviviente | 50 aciertos en Supervivencia en una sola partida. |
| Relámpago | `com.faacil.MathGame.achievement.timeattack_30` | 50 | Cerebro relámpago | 30 aciertos en Contrarreloj en una sola partida. |
| Nivel 10 | `com.faacil.MathGame.achievement.level_10` | 50 | Nivel 10 | Alcanza el nivel 10. |
| Nivel 25 | `com.faacil.MathGame.achievement.level_25` | 80 | Nivel 25 | Alcanza el nivel 25. |

> Títulos/descripciones en **en/fr/pt-BR** ya están en `Localizable.xcstrings` (keys `ach.<key>.title` y `ach.<key>.desc`); pégalos en las localizaciones correspondientes de cada logro.

**Imágenes de logros (obligatorias):** Apple exige un PNG 1024×1024 por logro. Mientras diseñas iconos propios, puedes reutilizar una sola imagen de marca para los 20 al inicio y refinarlos después (se pueden actualizar sin nueva revisión de la app). El código ya asocia un símbolo SF a cada logro (`AchievementCatalog.swift`) para mostrarlos dentro de la app aunque no subas imágenes a Game Center.

> Mientras no registres estos IDs, el código no envía nada (las llamadas fallan en silencio). No crashea.

---

## 5. Target watchOS (app de Apple Watch)

El código vive en `MathGameWatch/` (`MathGameWatchApp.swift`, `WatchHomeView.swift`, `WatchGameView.swift`, `ComplicationProvider.swift`). **No están en ningún target** todavía.

1. Xcode → **File → New → Target → watchOS → Watch App** (no "Watch App with New Companion App"; ya tienes la app iOS). Nombre: `MathGameWatch`. Bundle ID: `com.faacil.MathGame.watchkitapp`. Companion: `com.faacil.MathGame`.
2. Borra los archivos de plantilla que Xcode genera y **arrastra** los 4 archivos de `MathGameWatch/` al nuevo target.
3. **Comparte el dominio**: selecciona `MathGame/Domain/Models.swift`, `QuestionGenerator.swift`, `Scoring.swift` → en el inspector de archivo, marca **Target Membership** también para `MathGameWatch`. Así el Watch reutiliza la lógica sin duplicar.
4. `ComplicationProvider.swift` necesita un **Widget Extension** propio (watchOS) si quieres complications; o quítalo si solo quieres la app. Lee §5.1.
5. Para sincronizar la racha al Watch (complication), implementa App Group (§5.1).

### 5.1 App Group para compartir la racha (opcional pero recomendado)
- Capability **App Groups** en target iOS y target Watch, ID `group.com.faacil.MathGame`.
- En el lado iOS, tras completar el Daily, escribe:
  ```swift
  UserDefaults(suiteName: "group.com.faacil.MathGame")?.set(player.currentStreak, forKey: "currentStreak")
  ```
  (Agrégalo en `ProgressionEngine.recordDailyCompletion` o en `DailyViewModel.commitResults`.)
- El `StreakProvider` ya lee de ese App Group.

---

## 6. Mac (Mac Catalyst)

1. Target `MathGame` → **General → Supported Destinations → + → Mac (Mac Catalyst)**.
2. Marca **Optimize interface for Mac** (recomendado) o **Scale interface to match iPad**.
3. El código ya es adaptativo: `ContentView` usa `NavigationSplitView` en `horizontalSizeClass == .regular` (Mac e iPad), y `MathGameApp` ya define un bloque `.commands`. Los atajos 1–4 para responder ya funcionan con teclado.
4. Game Center y SwiftData funcionan en Catalyst sin cambios.
5. Si distribuyes en Mac App Store con el mismo pago único: en App Store Connect la app universal (iOS + Mac) comparte compra automáticamente.

---

## 7. Assets visuales (paleta + icono)

El tema (`MathGame/Presentation/Theme/AppTheme.swift`) usa **colores fallback embebidos en código**, así que la app se ve bien sin assets. Para control fino:

1. En `Assets.xcassets`, crea Color Sets nombrados: `Background`, `Surface`, `Primary`, `Secondary`, `Accent` (los lee `AppTheme` vía `Color("...")`). Define variantes Any/Dark.
2. **Icono:** el `AppIcon` actual sigue siendo el de v1. Para el "refresh premium" del plan, reemplaza `Assets.xcassets/AppIcon.appiconset` con un set nuevo (1024×1024 + tamaños). Mantén el estilo pero más limpio.

> Nota: `Color("Background")` con asset ausente cae al color del sistema, no al `fallbackBackground`. Por eso `Color.appBackground` (lo que usan las vistas) apunta directo a los fallback embebidos. Si creas los colorsets y quieres usarlos, cambia los accessors en `AppTheme.swift` para devolver `background` en vez de `fallbackBackground`.

---

## 8. Screenshots y App Preview

Necesarios para App Store (por tamaño de pantalla). Tamaños mínimos: 6.7" (iPhone), 13"/11" (iPad), y Watch/Mac si publicas ahí.

- Genera con **Xcode → Product → Scheme → MathGame** corriendo en cada simulador y `⌘S` para screenshot, o automatiza con **Fastlane Snapshot**.
- Captura: Daily Challenge, Profile/Racha, Time Attack, vista iPad split, pantalla de logros.
- App Preview: graba 15–30 s con `xcrun simctl io booted recordVideo demo.mov` mostrando daily → racha → multi-device.
- Los textos de captions están en `APP_STORE.md`.

---

## 9. Subir y enviar a revisión

1. Selecciona destino **Any iOS Device (arm64)**, configuración **Release**.
2. **Product → Archive**.
3. En el Organizer: **Validate App**, luego **Distribute App → App Store Connect**.
4. En App Store Connect:
   - Pega la metadata desde `APP_STORE.md` (descripción, keywords, promo, what's new) en cada idioma (en, es, fr, pt-BR).
   - Sube screenshots.
   - Sube la build.
   - **Precio:** sube el tier respecto a v1 (justificado por el cambio mayor). Usuarios v1 reciben la actualización gratis (mismo bundle ID).
   - **Privacidad:** declara Game Center (identificador de jugador) y que no recoges datos personales. Notificaciones locales no requieren declaración de datos.
   - Reemplaza la URL de política de privacidad y el email de soporte en `SettingsView.swift` (ahora apuntan a `example.com`).
5. Envía a revisión.

---

## 10. Cosas a tocar en código antes de publicar (rápidas)

- `MathGame/Presentation/Pages/SettingsView.swift`: cambia `https://example.com/privacy` y `mailto:support@example.com` por los reales.
- Revisa traducciones **fr** y **pt-BR** en `Localizable.xcstrings` (las generé yo; conviene una revisión humana, especialmente plurales).
- Opcional: el modo selector de dificultad existe en el dominio (`Difficulty`) pero la UI siempre usa `.normal`. Si quieres exponerlo, agrega un `Picker` en `CalculationView`.

---

## 11. Riesgos conocidos / notas

- **Plurales:** las strings tipo `daily.result.streak.%lld` usan formato simple, no `.stringsdict` con reglas de plural. Para 6+ idiomas con plurales complejos, considera migrar a variaciones de plural en el catálogo.
- **SwiftData primera migración:** v1 no tenía store, así que el primer arranque de v2 crea un `Player` vacío. No hay datos que migrar. Si en el futuro cambias el esquema `@Model`, necesitarás un `VersionedSchema` + `SchemaMigrationPlan`.
- **Game Center en simulador:** requiere iniciar sesión en el simulador (Settings → Game Center). En dispositivo real funciona con tu Apple ID de sandbox.
