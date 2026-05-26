# MIGRATION.md — Pasos manuales para MathGame v2.0.0

Este documento lista **todo lo que NO se puede automatizar** desde código y que tú debes hacer en Xcode / App Store Connect / Apple Developer antes de poder publicar la v2.0.0.

El código fuente de iPhone + iPad ya está completo, integrado al target y **compila** (`xcodebuild ... BUILD SUCCEEDED`). watchOS y Mac están como **código listo** pero requieren que crees los targets en Xcode (no se puede hacer editando `project.pbxproj` a mano sin corromperlo).

---

## 0. Resumen — qué está hecho vs. qué falta

| Área | Estado | Acción tuya |
|---|---|---|
| Arquitectura, SwiftData, progresión, Daily, modos, polish | ✅ Hecho y compilando | Ninguna |
| Localización en/es/pt-BR/fr (todas las strings de UI) | ✅ Hecho | Revisar traducciones AI de fr/pt-BR |
| Audio (código) | ✅ Hecho | Agregar archivos `.caf` (§3) |
| Haptics | ✅ Hecho | Ninguna |
| Game Center (código) | ✅ Hecho | Capability + registrar IDs (§4) |
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

> El proyecto incluye `scripts/inject_pbxproj.py` + `scripts/pbx_plan.json`, que fue lo que registró los 24 archivos nuevos en el target. Puedes borrar la carpeta `scripts/` si no la necesitas; ya cumplió su función. El backup `MathGame.xcodeproj/project.pbxproj.bak` también se puede borrar una vez confirmes que todo abre bien en Xcode.

---

## 2. Categoría de App Store (¡importante!)

Cambié `INFOPLIST_KEY_LSApplicationCategoryType` de `public.app-category.kids-games` a **`public.app-category.education`**.

**Razón:** la categoría *Kids* de Apple **prohíbe Game Center y enlaces externos**, y tú pediste audiencia universal + leaderboards. Si insistes en la categoría Kids, hay que quitar Game Center y los `Link()` de Ajustes. Decide esto antes de subir.

---

## 3. Archivos de audio (`.caf`)

`MathGame/Services/AudioEngine.swift` precarga estos nombres (busca `.caf`, luego `.m4a`, luego `.wav`). **Si los archivos no existen, el juego funciona sin sonido** (degradación elegante). Para activar sonido:

1. Consigue/crea 10 efectos cortos (< 1 s) y nómbralos exactamente:
   `correct`, `wrong`, `level_up`, `streak_milestone`, `daily_complete`, `tap`, `navigation`, `achievement`, `time_tick`, `game_over`.
2. Conviértelos a `.caf` (formato recomendado iOS):
   ```bash
   afconvert -f caff -d LEI16 input.wav correct.caf
   ```
3. Arrástralos a un grupo nuevo `MathGame/Audio/Resources` en Xcode, marcando **Target Membership: MathGame**.
4. Fuentes libres sugeridas: freesound.org (CC0), Apple's "iOS UI Sounds", o genera con un sintetizador.

---

## 4. Game Center

El código (`MathGame/Data/GameCenterService.swift`) ya autentica al lanzar y envía scores/achievements, **pero no hace nada hasta que**:

### 4.1 Capability en Xcode
- Target `MathGame` → **Signing & Capabilities** → **+ Capability** → **Game Center**.
- Esto crea `MathGame.entitlements` con `com.apple.developer.game-center`.

### 4.2 Registrar en App Store Connect
En App Store Connect → tu app → **Features → Game Center**, crea:

**Leaderboards** (IDs deben coincidir con `GameCenterService.leaderboardPrefix`):
- `com.faacil.MathGame.leaderboard.addition`
- `...subtraction`, `...multiplication`, `...division`, `...power`, `...root`
- `...timeAttack`, `...survival`, `...mixed`, `...sequence`
- `com.faacil.MathGame.leaderboard.daily`  ← el principal (Daily Challenge)

Todos: tipo *Classic*, *High to Low*, formato *Integer*.

**Achievements** (IDs = `achievementPrefix` + `.` + key). Las 20 keys están en `MathGame/Data/AchievementCatalog.swift`:
```
first_win, first_daily, perfect_daily,
streak_3, streak_7, streak_30, streak_100,
correct_100, correct_1000, correct_10000,
master_addition, master_subtraction, master_multiplication,
master_division, master_power, master_root,
survival_50, timeattack_30, level_10, level_25
```
Es decir: `com.faacil.MathGame.achievement.first_win`, etc. Usa los títulos/descripciones de `Localizable.xcstrings` (keys `ach.<key>.title` / `.desc`).

> Mientras no registres los IDs, el código simplemente no enviará nada (las llamadas fallan en silencio). No crashea.

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
