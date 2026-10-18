# Analiza plików Lua — `prompt_sandy_illegal_garage`

Data: 2026-10-18 · Zasób: Prompt Studio „Sandy Shores Illegal Garage & Gas Station & Car Wash” v1.1.4

## 1. Zakres i metoda

- Przeanalizowano **wszystkie 9 plików Lua** (4203 linie przed czyszczeniem) + `readme.txt`.
- Folderu **`stream/` nie odczytywano i nic w nim nie zapisywano** (zgodnie z poleceniem) — dlatego
  nie weryfikowano zgodności nazw modeli/animacji z `config.lua` z fizycznymi plikami `.ydr/.ycd/.ymap`,
  kolizji wbudowanych w modele ani poprawności MLO.
- Wyjątek pozakodowy: **pobrano do wglądu (tylko odczyt)** zdalny skrypt, który `sv_loader.lua`
  ściąga i wykonuje na serwerze — bo bez tego nie da się rzetelnie ocenić tego pliku (rozdział 7.1).
- Weryfikacja po czyszczeniu (rozdział 9): parsowanie składni wszystkich plików + automatyczne
  testy równoważności „stary vs nowy kod” na mockach API FiveM (Lua poza FXServerem).
  Zachowań wymagających prawdziwego FXServera/gry nie dało się potwierdzić — są oznaczone
  jako „do zweryfikowania w grze”.

## 2. Co zostało zrobione (czyszczenie zapisu dekompilatora)

Zapis typu `L0_1`, `A0_2`, `goto lbl_16` występował w **3 z 9 plików**. Przepisano je na normalny,
czytelny kod Lua z nazwanymi zmiennymi i komentarzami, **zachowując wszystkie nazwy globalne,
eventy, eksporty, stringi i kolejność rejestracji**:

| Plik | Przed | Po | Uwagi |
|---|---|---|---|
| `client/utils.lua` | 734 linie | 304 | krzywe Beziera + animowanie encji |
| `server/server.lua` | 1527 linii | 631 | stan, uprawnienia, AutoOpen, komenda testowa |
| `sv_loader.lua` | 232 linie | 99 | zdalny checker + wersja |

Pozostałe pliki były już w normalnym zapisie i **nie były edytowane w rundzie czyszczenia**
(tylko przeanalizowane): `client/client.lua` (1131), `client/target_wrapper.lua` (83),
`config.lua` (226), `open_config.lua` (54), `open_functions.lua` (173), `fxmanifest.lua` (43).
Znalezione w nich problemy są opisane w rozdziale 7 jako lista do naprawy — świadomie ich
nie poprawiano „przy okazji”, żeby nie mieszać czyszczenia z naprawami.

### Rekonstrukcje po dekompilacji (świadome odstępstwa od dosłownego zapisu!)

Dekompilator w kilku miejscach **uszkodził warunki logiczne** (typowy artefakt przy wyrażeniach
`a and b or c` i złożonych koniunkcjach). Odtworzono intencję z kontekstu i opisano to w kodzie.
Te miejsca zachowują się **inaczej niż dosłowny zdekompilowany kod** (który był po prostu zepsuty):

1. **`toggleLock` (server)** — zdekompilowane `newLocked = not old and old` jest w Lua **zawsze**
   `false/nil`, więc rolety nie dało się nigdy zablokować. Odtworzono `newLocked = not locks[propName]`.
   Potwierdzają to: notify locked/unlocked oraz gałęzie „po odblokowaniu otwórz / po zablokowaniu zamknij”.
2. **Komenda testowa (server)** — warunki „can auto-open” / „can auto-close” były zdekompilowane
   jako nadpisujące się odczyty kończące się `not x and x`. Odtworzono koniunkcje z opisów testów.
3. **`getPlayerJobName` (server, gałęzie qb/qbox)** — zdekompilowany kod mógł zwrócić **całą tabelę
   `job`** zamiast nazwy/`nil`, gdy `job.name` było `nil`. Znormalizowano do „nazwa małymi lub nil”.
4. **`math.pow` → `^` (utils, krzywe elastyczne)** — `math.pow` usunięto ze standardu Lua 5.4;
   `2 ^ x` daje identyczny wynik i działa niezależnie od libów kompatybilności FXServera.
5. **Usunięte martwe wywołania bez skutków ubocznych**: zbędne `calcBezier(...)` w `getTForX`,
   nieużyte `GetEntityRotation` w `AnimateObjectRotation`, odczyt poprzedniego `busy` w teście,
   dodatkowe `nil`-e przekazywane do `print` w ostrzeżeniu „standalone”, zduplikowany zapis `busy`
   w handlerze `setPropBusy` (zastąpiony istniejącym helperem `setBusy`).

## 3. Architektura i przepływy

Kolejność ładowania (`fxmanifest.lua`): shared `@ox_lib/init.lua` → `config.lua` → `open_config.lua`;
client: `open_functions.lua` → `client/target_wrapper.lua` → `client/utils.lua` → `client/client.lua`;
server: `server/*.lua` → `sv_loader.lua`. Kolejność jest poprawna względem zależności
(`Config` powstaje, zanim ktokolwiek go czyta; wrapper targetu czyta `Config.UseOxTarget` synchronicznie).

**Stan współdzielony (GlobalState, pisze wyłącznie serwer, klient tylko czyta):**
`ilegal_carwash` (prop → otwarty?), `ilegal_carwash_busy` (prop → animacja w toku),
`ilegal_carwash_locks` (roleta → zablokowana?, tylko przy AutoOpen).

**Eventy klient → serwer (10, pełna zgodność obu stron):**
`initializeState`, `updatePropState`, `setPropBusy`, `syncAnimation`, `requestPlayerAnimation`,
`zoneEnter`, `zoneExit`, `requestAutoOpen`, `requestAutoClose`, `toggleLock`
(wszystkie z prefiksem `ilegal_anims:`).

**Eventy serwer → klient (2 + zewnętrzny):** `ilegal_anims:syncAnimation` (retransmisja),
`ilegal_anims:animatePropAfterPlayerAnim`, `ox_lib:notify` (event ox_lib).
**Callback ox_lib:** `ilegal_anims:playPlayerAnimation` (serwer → klient źródłowy) — para się zgadza.
**Eksporty:** klient `getLiftState`/`isLiftBusy`/`setLiftState`; serwer `getLiftState`/`isLiftBusy`/`isDoorLocked`.

**Typowy przepływ ręcznego propa** (lift/floorgate/secret/engine): target lub klawisz E na kliencie →
`OnPropInteraction` + `onExecute` → `setPropBusy(true)` → lokalne `animateProp` → (opcjonalna animacja
gracza przez serwerowy callback) → `animatePropObject` gra animację propa, animuje kolizję i wysyła
`updatePropState` → serwer zapisuje GlobalState → inni klienci animują przez handler state-baga →
po `duration` ms klient-inicjator (i każdy synchronizujący!) wysyła `setPropBusy(false)`.

**AutoOpen (tylko roleta):** osobna strefa `lib.zones` na kliencie → `zoneEnter` + `requestAutoOpen`
→ serwer sprawdza job/zamek/busy/stan → `setBusy(true)` + stan `true` → klienci animują ze state-baga.
Wyjście ze strefy → po `AutoOpenCloseDelay` `requestAutoClose` → serwer wymaga 0 osób w strefie.
Interakcja zmienia się na lock/unlock (`toggleLock`).

## 4. Co jest spójne (potwierdzone)

- Zbiory nazw eventów po obu stronach zgadzają się **1:1** (brak eventów widmo, brak literówek w parach);
  callback ox_lib i event `animatePropAfterPlayerAnim` też są obustronnie kompletne.
- Klucze GlobalState: każdy zapisywany przez serwer klucz ma konsumentów na kliencie i odwrotnie;
  klient nigdzie nie pisze do GlobalState bezpośrednio (prawidłowo).
- Handler state-baga na kliencie porównujący **nową `value`** ze „starym” `GlobalState` jest poprawny:
  wg dokumentacji CFX w trakcie callbacka w bagu jest jeszcze stara wartość
  ([AddStateBagChangeHandler](https://docs.fivem.net/natives/?_0xA5EDC40EF369B48D=)).
  Drugi handler (locks) niezależnie trzyma własny `previousLocks` — dwa podejścia, oba działają.
- `Config.Props` (5 propów: lift, garage_rollup, floorgate, secret_door, engine_full): wszystkie mają
  `name/model/coords/rotation/label/animations/interactionZone`, których klient wymaga; współrzędne
  tworzą zwarty klaster w Sandy (x 1990–2003, y 3779–3793), spójny z `garageCoords` wnętrza;
  nazwy `name` są unikalne i to one są kluczami stanu po obu stronach.
- Wrapper targetu: `TargetRemoveZone(name)` jest zgodne z API ox_target (przyjmuje nazwę lub id),
  tłumaczenie opcji na qb-target (`onSelect`→`action`) jest poprawne; fallback „E” przy braku targetu kompletny.
- Uprawnienia: klient (ukrywanie UI) i serwer (decyzja dla AutoOpen/lock) korzystają z tych samych
  `Config.Permissions` + `allowedJobs`; nazwy jobów są porównywane po `lower()` po obu stronach.
- `createCollision` odtwarza pozycję kolizji ze stanu GlobalState przy spawnie, a `createProp`
  odtwarza animację do stanu z GlobalState — późne wejście w zasięg jest przemyślane.

## 5. Mapa plików (krótko o każdym)

| Plik | Rola | Najważniejsze uwagi |
|---|---|---|
| `fxmanifest.lua` | manifest, kolejność skryptów | brak zależności `ox_lib`; zdublowany `dependency '/assetpacks'` |
| `config.lua` (shared) | definicje 5 propów | `onExecute` floorgate woła nieistniejący global; kształty `playerAnimation` niespójne; komentarze czasów niezgodne z wartościami |
| `open_config.lua` (shared) | przełączniki, Permissions, Messages | `EnablePlayerAnimations` nigdy nieczytane; część `Messages` martwa |
| `open_functions.lua` (klient) | hooki: `CanPlayerInteract`, `HasJobAccess`, `GetCustomLabel`, `OnPropInteraction` | ACE używa natywki serwerowej na kliencie |
| `client/target_wrapper.lua` | wykrywanie ox/qb-target, `TargetAddBoxZone/RemoveZone` | wykrywanie tylko przy starcie zasobu; qb-target: podwójna wysokość strefy |
| `client/utils.lua` ✅ przepisany | easing Beziera, `AnimateObjectCoords/Rotation`, `MovePlayerToPosition` | 2 z 3 funkcji animujących nieużywane w zasobie; martwa tabela presetów |
| `client/client.lua` | spawn propów, strefy, animacje, sync, komendy testowe | najwięcej ustaleń funkcjonalnych (rozdział 7) |
| `server/server.lua` ✅ przepisany | stan GlobalState, uprawnienia, AutoOpen, testy | serwer ufa klientowi przy propach ręcznych; test mutuje żywy stan |
| `sv_loader.lua` ✅ przepisany | zdalny checker map + check wersji | **wykonuje zdalny kod; telemetria — patrz 7.1** |
| `readme.txt` | 1 linia z linkiem do dokumentacji Prompt | brak opisu instalacji/zależności w repo |

## 6. Legenda ważności

🔴 krytyczne (bezpieczeństwo / decyzja świadoma) · 🟠 wysokie (funkcja zepsuta) ·
🟡 średnie (niespójność / kruchość) · ⚪ niskie (martwy kod, kosmetyka)

## 7. Ustalenia

### 7.1. 🔴 `sv_loader.lua` — zdalne wykonywanie kodu + telemetria (świadoma decyzja potrzebna)

- `sv_loader.lua:45–51` pobiera `script.lua` z GitHuba (`Prompt-Coder/mapdatachecker`, gałąź `main` —
  **mutowalna**) i wykonuje go przez `load(body)()` z pełnymi uprawnieniami serwera, bez żadnej
  kontroli integralności. Kompromitacja tego repo = kompromitacja każdego serwera z tą mapą.
- Zdalny skrypt (stan na 2026-10-18) robi głównie to, do czego służy: sprawdza zgodność zainstalowanych
  map Prompt z „mapdata” i drukuje linki; działa na globalach `Debug/MapId/Urls` z `sv_loader.lua`,
  pobiera i `load()`-uje kolejny plik (`all_data_full`).
- **Zawiera też telemetrię:** jeśli pierwsze 4 bajty `sv_loader.lua` to nie `FXAP` (magia zaszyfrowanego
  escrow) — a nasz plik jest jawny („Decrypted & Fixed by LuaClear”) — wysyła POST na
  `prompt-mapdata-api.vertex-hub.com/performance-metrics` z nazwa hosta serwera (`sv_hostname`),
  nazwą projektu (`sv_projectName`), zasobem oraz nazwą+ID konta CFX wyciągniętymi z bufora konsoli.
  W praktyce: **każdy start serwera z tą kopią „dzwoni do domu” i identyfikuje właściciela.**
- Rekomendacja: usunąć `'sv_loader.lua'` z `server_scripts` w `fxmanifest.lua` (mapa działa bez tego;
  znika tylko checker zgodności mapdata i powiadomienia o wersji) **albo** zostawić checker,
  ale zablokować telemetrię/własnoręcznie hostować kod. **W rundzie czyszczenia pliku nie usuwano
  ani manifestu nie zmieniano; decyzję wdrożono w drugiej rundzie — patrz 8.1.**

### 7.2. 🟠 Wysokie — funkcje zepsute

1. **Floorgate: `onExecute` woła `animateProp`, który jest `local` w `client/client.lua:20`** —
   z poziomu `config.lua:124–131` ten identyfikator jest `nil`. Przy otwieraniu floorgate, gdy lift
   jest na dole, `onExecute` wyrzuca błąd **przed** `setPropBusy/animateProp`, więc floorgate się
   nie otwiera (target: `client.lua:493–512`, E-key: `client.lua:679–682`). Bonus: `onExecute`
   jest wołane także przy zamykaniu. Naprawa: wystawić global/eksport albo przenieść logikę do klienta.
2. **Engine: `playerAnimation.position/heading` to tabele per kierunek (`config.lua:209–216`),
   a kod oczekuje pojedynczych wartości** (`client.lua:360–361` wysyła całość; callback
   `client.lua:917–936` robi `animData.position.x` i arytmetykę na wektorze). Skutek: błąd
   w callbacku → serwer loguje „falló” → prop się nie animuje, a `busy` ustawione przed `animateProp`
   nigdy nie jest czyszczone (prop się „cegluje”). `secret_door` ma poprawny, pojedynczy kształt —
   to niespójność formatu configa między propami. Naprawa: w `animateProp` wybierać
   `position[animName]`/`heading[animName]`, gdy to tabele.
3. **`moveType = "rotation"` nie jest zaimplementowane w ruchu kolizji** — `animatePropObject`
   (`client.lua:276–312`) zawsze robi `AnimateObjectCoords` na `start/endCoords`. Dla floorgate
   (`config.lua:100`, ma `start/endRotation`) oraz dla engine (kolizja bez coordsów ruchu,
   `config.lua:195–199`) przekazuje `nil, nil` → wątek w `AnimateObjectCoords` wyrzuca błąd
   („index nil”) przy każdej animacji, a kolizja floorgate **nie obraca się**. Istniejące
   `AnimateObjectRotation` z `utils.lua` nie jest nigdzie wołane — ewidentnie miało tu być użyte.
   Naprawa: gałąź `if moveType == "rotation" → AnimateObjectRotation`, `elseif "coords" → Coords`,
   kolizja statyczna → pomijać.
4. **Sprzeczność kierunku ruchu kolizji „coords”** — `createCollision` przyjmuje: otwarty = `endCoords`,
   zamknięty = `startCoords` (`client.lua:172–177`), a `animatePropObject` przy otwieraniu animuje
   **do `startCoords`** (`client.lua:276–277` + cel = drugi argument `AnimateObjectCoords`).
   Jedna ze ścieżek ma odwrócone końce. Dla liftu „open” = góra (`endCoords` z 33.366 vs `startCoords`
   31.082), więc przy podnoszeniu kolizja platformy jedzie w dół — auto raczej nie pojedzie z liftem.
   **Do zweryfikowania w grze**, która ścieżka jest zgodna z modelem kolizji (streamu nie czytano).
5. **`/testanims` dostępne dla każdego gracza** — `RegisterCommand("testanims", ..., false)`
   (`client.lua:1125`) + menu wołające `animateProp` bez `busy` i bez sprawdzenia uprawnień.
   Każdy może sterować wszystkimi propami z dowolnego miejsca (byle prop był zespawnowany).
   Naprawa: `true` (ACE `command.testanims`) jak pozostałe komendy testowe.

### 7.3. 🟠/🟡 Serwer ufa klientowi (walidacja/autorytatywność)

Tylko ścieżka AutoOpen jest serwerowo-decycjna (`requestAutoOpen`/`toggleLock` sprawdzają
`ServerHasJobAccess`). Propy ręczne są **klientodecycjne** — serwer jedynie przyjmuje zgłoszenia:

- `updatePropState` (`server.lua:230`): brak sprawdzenia uprawnień, istnienia propa, typu stanu czy dystansu.
- `setPropBusy` (`server.lua:291`): każdy może ustawić `busy=true` na dowolnym propie i zablokować go innym.
- `syncAnimation` (`server.lua:239`): dowolny `dict/anim` jest retransmitowany do wszystkich (-1)
  i grany na pedzie nadawcy u innych; klienci docelowi robią `GetPlayerPed` bez sprawdzenia `-1/0`.
- `zoneEnter/zoneExit`: zajętość strefy (warunek autozamknięcia) jest w całości deklarowana przez
  klientów — fałszywy `zoneEnter` trzyma roletę otwartą w nieskończoność. Brak weryfikacji pozycji
  (`GetEntityCoords(GetPlayerPed(src))` vs strefa z configa, który serwer i tak ładuje jako shared).
- `requestAutoClose`: brak sprawdzenia joba (ktoś spoza strefy może zgłosić zamknięcie, o ile
  serwerowa lista occupants jest pusta — a sterują nią klienci).
- `requestPlayerAnimation`: dowolne `dict/anim/position` — skutek ograniczony do samego nadawcy
  (callback idzie tylko do niego), ale pozycja powoduje teleport jego peda (self-grief/miganie).
- `validateSource` sprawdza jedynie `source > 0`; zwraca `nil` zamiast `false` dla `nil`
  (poprawne w użyciu, warte świadomości przy reużyciu).

Rekomendacja długofalowa: jeden serwerowy event typu `requestToggle(propName)` z walidacją:
prop istnieje w `Config.Props`, gracz jest w promieniu `interactionZone`, sprawdzenie `busy`
i `ServerHasJobAccess`, a dopiero potem `setBusy` + zmiana stanu (klienci animują ze state-baga).
To przy okazji usuwa duplikację logiki otwarcia po stronie klientów.

### 7.4. 🟡 Średnie — niespójności i kruchość

- **ACE na kliencie używa natywki serwerowej**: `open_functions.lua:102` `IsPlayerAceAllowed(PlayerId(), …)`
  to API **serwerowe** ([native](https://docs.fivem.net/natives/?_0xB9234AFB=)); po stronie klienta
  istnieje `IsAceAllowed(permission)`. Przy `useAce=true` sprawdzanie na kliencie wywali błąd
  (i tak póki co żaden prop nie ma `acePermission`, więc gałąź jest martwa). Serwerowa strona ACE jest ok.
- **ACE → fallback do jobów:** gdy `useAce=true`, a prop nie ma `acePermission`, **obie** strony
  (klient i serwer — tu akurat spójnie) spadają do sprawdzania `allowedJobs` zamiast „brak restrykcji ACE
  = dostęp”. Trzeba zdecydować, czy to zamierzone.
- **Nazewnictwo frameworka `qb` vs `qbcore`**: klient używa `'qb'`, serwer normalizuje `'qb'→'qbcore'`.
  Ustawienie `framework='qbcore'` (zgodne z nazewnictwem serwera) sprawi, że klient nie rozpozna
  frameworka i odmówi, choć serwer pozwoli. Do tego klient czyta joba najpierw ze state-baga
  (działa też standalone), a serwer standalone ma twardy fail-closed bez state-baga — przy serwerze
  standalone opartym o state-bagi UI pokaże opcje, które serwer odrzuci.
- **`Config.EnablePlayerAnimations` nigdy nieczytane** (tylko definicja `open_config.lua:2`) —
  przełącznik nie działa; animacja gracza zależy wyłącznie od obecności `playerAnimation` w propie.
- **`playEntityAnimation`: parametry nie znaczą tego, co nazwy:** `duration` i `loop` są ignorowane,
  faktycznie do `PlayEntityAnim(entity, animName, animDict, blendDelta, bLoop, bHoldLastFrame, …)`
  trafia `flag` jako *bLoop* oraz **liczba `0.0`** jako *bHoldLastFrame* (`client.lua:218`;
  sygnatura: [PLAY_ENTITY_ANIM](https://docs.fivem.net/natives/?_0x6089CDF6A57F326C=)).
  Wszystkie wywołania przekazują te same `(…, 0, false, true, 0.0, 0)`, więc w praktyce każda
  animacja (też open/close) idzie z `bLoop=true`. **Potwierdzone w grze** (klipy faktycznie
  się zapętlały) **i naprawione po teście na serwerze — patrz 9.3.**
- **`busy` może zostać ustawione na zawsze**: czyszczenie zależy od `SetTimeout` na kliencie animującym.
  Gdy inicjator wyjdzie z serwera w trakcie animacji gracza (zanim poleci `updatePropState`),
  żaden klient nie wyśle `setPropBusy(false)` (brak synchronizującego klienta = brak jego timeoutu),
  a `playerDropped` czyści tylko occupants. Brak serwerowego watchdog/timeout na `busy`.
  Dodatkowo **każdy** klient synchronizujący animację planuje własne `setPropBusy(false)`
  po lokalnym `GetAnimDuration` — najszybszy może zwolnić prop w trakcie cudzej animacji.
- **`toggleLock` przy blokowaniu nie sprawdza `busy`** (gałąź odblokowania sprawdza) — można nadpisać
  stan w połowie animacji.
- **`isGarageRollup` rozpoznaje dokładnie jedną nazwę modelu** (osobne implementacje na kliencie
  i serwerze) — mimo komentarzy o „wszystkich roletach” nie da się dodać drugiej rolety samą konfiguracją;
  drugi prop o tej samej nazwie skolidowałby na kluczach stanu.
- **`createSpawnPoint`: czysta kosmetyka streamingu** — `onExit` jest puste i propy nigdy nie są
  usuwane (zostają do `onResourceStop`); `spawnedProps[name] = nil` po utworzeniu pointa to no-op.
  Przy 5 propach nieszkodliwe, ale `SpawnDistance` działa tylko w jedną stronę.
- **`extraZones` (E-key)**: klon propa floorgate zachowuje to samo `name`, więc obie strefy
  dzielą klucz w `activeZones/activeZoneData` (wyjście z jednej ukryje UI drugiej — strefy są
  daleko od siebie, więc objawu w praktyce nie będzie). W ścieżce target klon dostaje sufiks,
  ale `GetCustomLabel` dostaje nazwę z sufiksem, gdy reszta logiki używa `originalName`.
- **Wykrywanie targetu/ox_lib tylko raz, przy ładowaniu zasobu** (`target_wrapper.lua:12–31`,
  `client.lua:1–7`), a `fxmanifest` nie deklaruje `dependency 'ox_lib'` (tylko 2× ten sam
  `'/assetpacks'`) — kolejność startu zasobów decyduje o trybie działania. Dodać zależności
  i/lub przeładowywać wykrywanie przy `onResourceStart`.
- **qb-target**: `minZ/maxZ = coords.z ± size.z` (`target_wrapper.lua:60–61`) daje strefę
  2× wyższą niż box ox_target (gdzie `size` to pełne wymiary); `distance = 2.5` na sztywno.
- **`lib.requestModel/requestAnimDict` + martwa gałąź `await`** (7 miejsc): funkcje ox_lib
  w Lua zwracają model/stringa i same yieldują do załadowania
  ([źródło ox_lib](https://github.com/overextended/ox_lib/blob/main/imports/requestModel/client.lua)) —
  sprawdzenie `type(x)=="table" and x.await` nigdy nie będzie prawdziwe. Nieszkodliwe, do uproszczenia.
- **Config — komentarze vs wartości**: `openDelay = 0 -- 2.3s`, `closeDelay = 0.1 -- 1.9s`
  (`config.lua:71–72`), a kod podaje te liczby wprost do `SetTimeout` (ms). Jedno z dwojga nieaktualne.
  Podobnie `rotation` propów to `vector4`, ale klient używa tylko `.x/.y/.z` jako kątów Eulera
  (komponent `w`, np. `0.965926`, jest ignorowany) — format mylący dla edytujących config.
- **Komenda testowa serwera mutuje żywy stan** i zostawia po sobie roletę **zablokowaną**, liczy
  testy przy założeniu świeżego serwera („All doors default to locked”), nadpisuje occupants
  (`[999]=true`) oraz na chwilę zmienia `Config.Permissions.enabled/allowedJobs`. Komenda flow
  na kliencie dodatkowo zostawia gracza w miejscu „outside” (nie wraca na pozycję sprzed testu).
  Oba narzędzia są ACE (`restricted=true`) — za wyjątkiem `/testanims` (7.2.5).

### 7.5. ⚪ Niskie / martwy kod / kosmetyka

- Nieużywane: `AnimateObjectRotation`, `MovePlayerToPosition`, `math.invlerp`, `removeOxTarget`,
  tabela presetów w `utils.lua`, globale `enableDefault/disableDefault`, klucze
  `Messages.interactButton/noAccess/alreadyInUse/testAllAnimations`, parametry `serverId` w hookach
  z `open_functions.lua`, `RegisterNetEvent("ilegal_anims:initializeState")` (w praktyce martwe:
  serwer zawsze inicjuje stan przy starcie, więc handler przyjmie dane klienta tylko w wyścigu rzędu ms).
- `Messages.noAccess` vs `Permissions.noAccessMessage` — dwa miejsca na ten sam komunikat;
  serwer używa drugiego, klient żadnego (przy braku dostępu po prostu chowa UI/opcje).
- Dokładność krzywych: port Beziera ma zniesiony indeks próbek względem oryginału JS (tablica
  1-based); metoda Newtona zwykle to koryguje. Pomiar vs implementacja referencyjna:
  easeInOut/easeOut/ease błąd < 0.000001, **easeIn (0.42,0,1,1) do ~0.03 przy x≈0.98**.
  W tym zasobie easeIn-bezier nie steruje żadnym propem (lift używa `easeInQuad`), więc bez znaczenia praktycznego.
- Szerokość ramki w `sv_loader` liczona jest w bajtach (znaki UTF-8 typu ⚠️ zawyżają) — ramka może
  wyjść minimalnie krzywa. Czysta kosmetyka konsoli.
- Trójjęzyczne komentarze i logi (PL klient / ES config+serwer / EN reszta), literówki w prefiksie
  `ilegal_` (spójne wszędzie — działa), event lokalny `liftStateChanged` współdzielony nazwą między
  klientem a serwerem (osobne domeny, ale mylące), eksporty `get/isLift*` obsługują wszystkie propy,
  nie tylko lift. `isDoorLocked` istnieje tylko serwerowo.
- `getFramework` (serwer) nie cachuje wyniku `'standalone'` — każde sprawdzenie uprawnień przy
  włączonych restrykcjach ponawia 3× `GetResourceState` (i w konsekwencji działa, gdy framework
  wystartuje później — być może zamierzone).

## 8. Rekomendowana kolejność napraw — status realizacji

W drugiej rundzie wykonano **wszystkie cztery grupy napraw z pierwotnego punktu 8**.
Zmieniono sześć plików kodu/konfiguracji: `client/client.lua`, `server/server.lua`,
`config.lua`, `fxmanifest.lua`, `open_config.lua` i `open_functions.lua`.
Folderu `stream/` nadal nie ruszano.

### 8.1. `sv_loader.lua` i `/testanims` — wykonane

- `sv_loader.lua` został usunięty z aktywnej listy `server_scripts` w `fxmanifest.lua`,
  ale sam plik pozostawiono w repozytorium. Wpis można świadomie odkomentować; manifest
  uprzedza jednak, że oznacza to ponowne uruchomienie mutowalnego, zdalnie pobieranego
  kodu oraz opisanej w 7.1 telemetrii. Bez loadera mapa traci jedynie checker mapdata
  i powiadomienia o wersji.
- `/testanims` rejestruje się teraz jako komenda ACE (`RegisterCommand(..., true)`,
  uprawnienie `command.testanims`). Dodatkowo menu nie animuje propów lokalnie:
  wysyła żądania do autorytatywnego serwera, więc nadal obowiązują uprawnienia,
  `busy` i walidacja dystansu.

### 8.2. Naprawy funkcjonalne — wykonane

- **Floorgate (7.2.1):** `onExecute` z `config.lua` nie woła już nieosiągalnego lokalnego
  `animateProp`; używa eksportu zasobu `setLiftState('prompt_sandy_is_lift', true)`. Eksport
  wyłącznie prosi serwer o zmianę stanu, a lokalne odtworzenie następuje ze state-baga.
- **`playerAnimation` silnika (7.2.2):** tabele `position`/`heading` kluczowane nazwą animacji
  (`domkrat_up`/`domkrat_down`) są rozwiązywane na serwerze wyłącznie na podstawie `Config.Props`.
  Klient dodatkowo toleruje ten kształt, zawsze waliduje liczby i buduje `vector3`, więc dane
  silnika nie powodują już błędu ani trwałego `busy`.
- **Ruch kolizji (7.2.3):** `moveType = "coords"` używa `AnimateObjectCoords`,
  `moveType = "rotation"` używa `AnimateObjectRotation`, natomiast kolizja bez typu ruchu
  (statyczny silnik) jest teraz świadomie pomijana zamiast wywoływać animację na `nil`.
- **Kierunek kolizji (7.2.4):** ujednolicono kierunek do konwencji już stosowanej przez
  `createCollision`: otwarty/podniesiony = `endCoords`, zamknięty/opuszczony = `startCoords`.
  To usuwa sprzeczność w kodzie; zgodność z fizycznym modelem nadal wymaga krótkiego
  smoke testu w grze, bo zawartości `stream/` celowo nie analizowano.

### 8.3. Autorytatywny serwer i watchdog `busy` — wykonane

- Dodano jeden ręczny event żądania: `ilegal_anims:requestToggleProp(propName, state?)`.
  Serwer sprawdza typ/istnienie propa, opcjonalny boolean, tryb AutoOpen rolety, pozycję
  gracza względem `interactionZone` i `extraZones`, `ServerHasJobAccess`, `busy` oraz
  faktyczny bieżący stan. Dopiero po tej walidacji rozpoczyna animację.
- Usunięto klientodecyzyjne handlery `initializeState`, `updatePropState`, `setPropBusy`
  i `requestPlayerAnimation` oraz powrotny event `animatePropAfterPlayerAnim`. Klient nie
  ustawia już stanu ani `busy`; wszyscy — także inicjator — odtwarzają animację po zmianie
  `GlobalState` przez serwer.
- `beginPropAnimation` buduje animację gracza wyłącznie z configa. Przy wymaganej animacji
  najpierw ustawia `busy`, wywołuje callback ox_lib u inicjatora i zmienia stan dopiero po sukcesie.
  `Config.EnablePlayerAnimations = false` pomija callback i zmienia stan od razu.
- `busy` ma monotoniczne tokeny per prop. Normalny watchdog zwalnia po
  `animations.duration + 1000 ms`; dla animacji gracza failsafe wynosi
  `8000 + duration + 2000 ms`. Rozłączenie inicjatora zwalnia jego pending natychmiast,
  późny callback/sync po failsafe jest ignorowany, a jeden gracz może mieć tylko jeden
  pending callback naraz.
- `syncAnimation` jest whitelistą: serwer przepuszcza tylko dokładne `dict`/`anim`
  z aktywnego, serwerowego pending danego gracza i tylko raz. Klient dodatkowo sprawdza,
  czy nadawca istnieje, jest aktywny, ma poprawnego peda i nie jest lokalnym graczem.
- AutoOpen też przechodzi przez serwerowy start animacji. `zoneEnter`, `requestAutoOpen`
  i `toggleLock` mają walidację pozycji; `toggleLock` nie działa podczas `busy`;
  `requestAutoClose` wymaga niedawnego legalnego wyjścia albo bliskiej pozycji.
  Zamknięcie celowo nie wymaga joba, aby drzwi zamknęły się po ostatnim wychodzącym graczu.
- Walidacja stref jest rozszerzonym, osiowym boxem (bieżące strefy mają `rotation = 0.0`):
  zwykle połowa rozmiaru + 7,5 m, a fallback auto-zamknięcia połowa rozmiaru + 25 m.
- `validateSource` zwraca teraz prawdziwy boolean tylko dla liczbowego `source > 0`.

### 8.4. Porządki — wykonane

- `EnablePlayerAnimations` jest faktycznie honorowane po stronie serwera.
- Klient używa właściwej natywki ACE `IsAceAllowed(permission)`. Fallback propa bez
  `acePermission` do `allowedJobs` zachowano jako świadomą, udokumentowaną semantykę.
- Klient normalizuje ręcznie ustawione `framework = 'qbcore'` do swojej nazwy `'qb'`.
- Manifest deklaruje `dependency 'ox_lib'` i zawiera `/assetpacks` tylko raz.
- Komentarze przy `openDelay`/`closeDelay` rolety poprawnie mówią o milisekundach;
  oba opóźnienia ustawiono na `0`.

### 8.5. Świadome granice tej rundy

Punkt 8 nie oznaczał naprawienia każdego ustalenia z 7.4/7.5. Poza zakresem pozostają m.in.
semantyka parametrów `PlayEntityAnim`, jednokierunkowy streaming propów, obsługa tylko jednej
nazwy rolety, martwe gałęzie `.await`, różnica wysokości boxa qb-target oraz mutowanie żywego
stanu przez serwerową komendę diagnostyczną. Nie zmieniano ich, aby nie rozszerzać zakresu napraw.

Przed wdrożeniem na serwer produkcyjny należy wykonać w grze: otwarcie/zamknięcie każdego
z pięciu propów, test lifta z pojazdem, floorgate z obu przycisków, AutoOpen z zamkiem oraz
sprawdzenie, czy właściwa grupa ma nadane ACE `command.testanims` w konfiguracji serwera.

## 9. Weryfikacja

### 9.1. Runda czyszczenia zapisu dekompilatora

- **Składnia:** wszystkie 9 plików Lua przechodzą `load()` (parser Lua) — w tym 3 przepisane.
- **Równoważność (mocki FiveM, ten sam scenariusz na wersji z gita i po przepisaniu):**
  - `client/utils.lua`: **identyczne** wyniki funkcji matematycznych dla siatki parametrów,
    identyczne trajektorie `AnimateObjectCoords` dla wszystkich 13 krzywych + krzywej-funkcji,
    identyczne `AnimateObjectRotation` i `MovePlayerToPosition`
    (starej wersji trzeba było dołożyć polyfill `math.pow` w środowisku testowym).
  - `sv_loader.lua`: **identyczna** kolejność requestów i wszystkie wydruki (404/200/zły Lua,
    nowsza/ta sama/błędna wersja), co do znaku.
  - `server/server.lua`: identyczne przejścia stanu dla init/eksportów/`updatePropState`/`setPropBusy`/
    stref/AutoOpen/`syncAnimation`/callbacków/permissions. **Jedyne różnice** wynikają z rekonstrukcji
    z punktu 2: drugie `toggleLock` teraz faktycznie blokuje (w starej wersji notify 2× „Unlocked!”),
    a komenda testowa w warunkach mocka przechodzi **29/29** zamiast **26 PASS / 3 FAIL**
    (failowały: „All doors default to locked” jako następstwo buga zamka oraz dwa warunki can-open/can-close).
- Grepy spójności: pary eventów, klucze GlobalState/Config/Messages, zastosowania globali z `utils.lua`
  i `open_functions.lua`, pola `Config.Props` względem kodu klienta/serwera.

### 9.2. Runda napraw z punktu 8

- **Składnia końcowa:** wszystkie 9 plików Lua ponownie przechodzą `load()` przez parser Lua.
- **Spójność statyczna:** siedem eventów klient→serwer ma dokładnie odpowiadające handlery;
  jedyny własny event serwer→klient to `syncAnimation`; serwerowy callback
  `ilegal_anims:playPlayerAnimation` ma rejestrację na kliencie; wszystkie wywołania eksportów
  tego zasobu (`getLiftState`, `isLiftBusy`, `setLiftState`) mają definicje. Stare eventy
  klientodecyzyjne nie występują już w aktywnym kodzie.
- **Mockowany harness FiveM:** 46/46 sprawdzeń przeszło (34 serwerowe, 12 klienckich), w tym:
  odrzucanie nieznanego propa i żądań z daleka, busy/watchdog, uprawnienia standalone,
  rozwiązywanie `domkrat_up`/`domkrat_down`, porażkę i brak callbacka, późny sync/callback,
  rozłączenie gracza, `EnablePlayerAnimations=false`, jeden pending na gracza, AutoOpen/zamek,
  `onExecute` floorgate, końcowe pozycje kolizji coords/rotation, kolizję statyczną oraz ACE
  flagę `/testanims`.
- `git diff --check` nie wykazał błędów whitespace, a status gita potwierdził zero zmian pod `stream/`.

**Niezeryfikowane (wymaga gry/serwera):** kierunek ruchu kolizji względem fizycznych modeli,
timing `GetAnimDuration`, synchronizacja pozycji graczy względem tolerancji stref, interakcje
ox_target/qb-target na żywym kliencie oraz cała zawartość `stream/`.

### 9.3. Test w grze i poprawki następcze

Po uruchomieniu zasobu na serwerze zgłoszono dwa objawy:

1. **Każdy animowany prop odtwarzał animację w pętli** (roleta „otwierała się w kółko"
   zamiast raz). To ustalenie z 7.4: `playEntityAnimation` wywoływał `PlayEntityAnim`
   z `bLoop=true` oraz liczbą `0.0` w miejscu `bHoldLastFrame`. Funkcję przepisano na
   jednoznaczne `bLoop=false, bHoldLastFrame=true` i usunięto przekłamane parametry
   (`duration`/`loop`/`flag`/`playbackRate`) ze wszystkich miejsc wywołania.
2. **Brak propów tuż po spawnie gracza przy garażu** — pojawiały się dopiero po wyjściu
   z zasięgu i powrocie. Jednorazowa, chwilowa porażka `createProp` (np. streaming modelu
   w trakcie spawnu gracza) nie była ponawiana: kolejne utworzenie następowało dopiero
   przy następnym `onEnter` pointa. Dodano: retry spawnu z rosnącym odstępem (do 5 prób),
   ochronę przed równoległymi próbami, retry kolizji, leczenie brakującej kolizji/linked
   przy ponownym wywołaniu oraz natychmiastową próbę utworzenia, gdy gracz już stoi
   w zasięgu w chwili tworzenia pointa.

Nazwy modeli i słowników animacji zweryfikowano względem listy plików `stream/`
(wszystkie istnieją). Mockowany harness po poprawkach: **49/49 sprawdzeń** (doszły testy
flag `PlayEntityAnim` oraz retry spawnu). Do potwierdzenia pozostaje jedynie ponowny
smoke test w grze po tych dwóch poprawkach.
