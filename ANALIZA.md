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

### 9.4. Wykrywanie mapy przez Prompt mapdata bez `sv_loader.lua`

Po dodaniu na serwerze zasobów mapdata/shared checker nie wykrywał tego interioru
(lista „Missing" zawierała **Gas**, a w linku do mapdata brakowało `+Gas`). Analiza
oficjalnego kodu checkera (`Prompt-Coder/mapdatachecker`, `remote_sv/map/script.lua`
— tego samego, który `sv_loader.lua` pobierał i wykonywał) pokazała, że wykrywanie
zainstalowanych map opiera się wyłącznie na **lokalnych eventach serwerowych**
`<static>:mapExists` z callbackiem, dla każdego `static` z rejestru `all_data_full`
(tutaj: `prompt_sandy_gasstation_carwash` = „Gas", `locations={"sandy"}`). Handlery
normalnie rejestrował zdalny skrypt z `sv_loadera`; po jego wyłączeniu (7.1/8.1)
nikt nie odpowiadał, więc mapa była niewidoczna.

Rozwiązanie bez przywracania zdalnego kodu i telemetrii: `server/server.lua` rejestruje
lokalnie te same handlery (`:mapExists`, `promptmap:i_exist_*`, `promptmap:locations_*`,
`:mapFullNameSend`, `:mapFinal`) przez `AddEventHandler`, z walidacją callbacku.
Mockowany harness po zmianie: **54/54 sprawdzeń**. Uwaga: folderów `prompt_sandy_shared`
i `cfx_prompt_sandy_mapdata` nie ma w tym repozytorium — analizę oparto o kod checkera,
który te zasoby ładują; sam mechanizm eventów jest dla nich wiążący. Do potwierdzenia
na serwerze: po restarcie zasobów w komunikacie checkera „Gas" powinien zniknąć
z listy Missing, a link powinien zawierać `+Gas`.

Po dopisaniu folderów do repozytorium zweryfikowano ich zawartość: `prompt_sandy_shared`
nie zawiera żadnego Lua (tylko wspólne assety stream), a `cfx_prompt_sandy_mapdata/sv_MapDataHandler.lua`
jedynie odpowiada listą obsługiwanych map (`prompt:mapdata_sendList`) — samo wykrywanie nadal
wykonuje `remote_sv/map/script.lua` działający wewnątrz pozostałych map. Pierwszy test na serwerze
wciąż nie wykrywał „Gas"; prawdopodobne przyczyny: na serwerze gier był jeszcze starszy `server.lua`
albo jednorazowe zapytania checkera (ok. 5 s po starcie każdej mapy) padły, zanim ten zasób zdążył
wystartować w ramach kategorii `[promptmaps]`. W odpowiedzi: handlery wykrywania rejestrowane są
teraz przez `RegisterNetEvent` (parytet 1:1 ze zdalnym skryptem, nadal z walidacją callbacku),
a start zasobu loguje linię potwierdzającą rejestrację. Harness po zmianie: **55/55 sprawdzeń**.
Jeśli mimo obecnego logu checker nadal nie widzi mapy, przyczyną jest kolejność startu — zasób
powinien startować przed pozostałymi mapami Prompt (np. osobne `ensure` przed kategorią).

Aktualizacja po kolejnym teście: log startowy potwierdził, że nowy `server.lua` działa
i startuje przed pozostałymi mapami, a „Gas" nadal nie był wykrywany. Winowajcą okazał się
prawdopodobnie własny bezpiecznik w handlerach: callback checkera przychodzi z **innego
zasobu** jako referencja funkcyjna FXServera, dla której `type(cb)` nie musi zwracać
`"function"` — filtr `type(cb)=="function"` po cichu odrzucał więc odpowiedzi. Handlery
odpowiadają teraz jak oficjalny skrypt (wywołanie wprost), zabezpieczone jedynie `pcall`,
i logują każde zapytanie checkera. Przy okazji zsynchronizowano decyzję właściciela:
plik `sv_loader.lua` usunięto także z gałęzi (wcześniej usunięty na `main`), a komentarz
w manifeście opisuje stan docelowy. Harness po zmianie: **56/56 sprawdzeń** (w tym test
callbacku-callable o typie innym niż `function`).

Epilog: po poprawce callbacków raport checkera **całkiem zniknął** — co okazało się dowodem,
że wykrywanie już działa. Raport drukuje zawsze mapa ostatnia na wykrytej liście według
kolejności rejestru (`Firestation2` #4 < `Market` #11 < `Gas` #13); wcześniejszy wydruk pochodził
z Marketu, a po wykryciu „Gas" obowiązek druku przeszedł na tę mapę (pozostałe checkery delegują
go eventem `:mapFinal` z argumentami `allMaps, existList`) — tylko że bez `sv_loadera` nie było
tu żadnego checkera, który by go wydrukował. Dodano więc lokalny odpowiednik wydruku w handlerze
`:mapFinal`: pyta mapdata o jej listę (`prompt:mapdata_sendList`), porównuje zbiory i drukuje tę
samą ramkę (Excess/Missing/link, nazwy z lokalnego snapshotu rejestru). Kod `sv_loader.lua`
z zasobu Market potwierdził przy okazji, że wszystkie mapy ładują ten sam, analizowany wyżej
skrypt checkera. Harness po zmianie: **59/59 sprawdzeń** (w tym scenariusz `:mapFinal` z linkiem
`Firestation2+Market+Gas`).

## 10. Runda: `prompt_sandy_market`, `prompt_sandy_fire2` i podwójny wydruk raportu mapdata

Data: 2026-10-18. Zakres: analiza i naprawa pozostałych folderów (`prompt_sandy_market`,
`prompt_sandy_fire2`, weryfikacja pomocniczych `prompt_sandy_shared` i `cfx_prompt_sandy_mapdata`)
oraz objaw ze zrzutu konsoli: raport mapdata drukował się **dwa razy** (podwójne
„odpowiadam true" i dwie identyczne ramki).

### 10.1. Przyczyna podwójnego wydruku — potwierdzona

Oficjalny checker (`Prompt-Coder/mapdatachecker`, `remote_sv/map/script.lua`) **nie jest
osobnym zasobem** — kopię skryptu pobiera i wykonuje `sv_loader.lua` **każdej** mapy.
Po rundzie z rozdz. 8/9 sv_loader został tylko w **dwóch** zasobach: `prompt_sandy_market`
i `prompt_sandy_fire2`. Oznaczało to **dwie niezależne instancje checkera**, z których każda:

1. pytała wszystkie mapy o istnienie (stąd dwa logi „checker pyta … odpowiadam true"
   z handlera w `prompt_sandy_illegal_garage`) i budowała tę samą listę
   `existList = {Firestation2, Market, Gas}`;
2. jako ostatnia mapa w kolejności rejestru jest `Gas` — obie instancje **delegowały**
   wydruk eventem `prompt_sandy_gasstation_carwash:mapFinal`, a handler w
   `server/server.lua` drukował raport przy każdym delegowaniu → dwie identyczne ramki.

To nie była wina samego handlera `:mapFinal` ani mapdata — to był wprost skutek dwóch
`sv_loader.lua` (a przy okazji: każda z tych kopii, jako plik jawny, realizowała telemetrię
opisaną w 7.1 — serwer „dzwonił do domu" **dwa razy** na start).

### 10.2. Co zostało zrobione

**`prompt_sandy_market` (analiza + naprawy):**

- Kod `client.lua`/`server.lua`/`config.lua` był już czytelny (nie po dekompilatorze) i ogólnie
  sprawny (menedżer IPL marketu: 9 stalli `box55_s_market_stalls_*`, sync serwer↔klient,
  eksporty, menu ox_lib + fallback komendowy). Nie było tam nic na miarę ustaleń 7.2 —
  poza poniższymi punktami.
- 🔴 **`sv_loader.lua` usunięty** (decyzja właściciela z 7.1/8.1 — kod zdalny + telemetria).
  W jego miejsce `sv_mapdata.lua`: **wyłącznie** lokalna rejestracja handlerów wykrywania
  (`<static>:mapExists`, `promptmap:i_exist_*`, `promptmap:locations_*`, `<static>:mapFullNameSend`,
  no-op `<static>:mapFinal`) — parzystość 1:1 ze zdalnym skryptem, callbacki przez `pcall`
  (quirk referencji funkcyjnych — patrz 9.4), zero sieci.
- 🟡 wywołania eksportów ox_lib zmienione z `lib:registerContext(...)` na składnię z kropką
  (zgodną z API ox_lib; wywołanie przez `:` mogłoby przekazać tabelę proxy jako pierwszy argument);
- 🟡 `hasOxLib` mierzone tylko przy starcie zasobu → teraz stan `ox_lib` sprawdzany przy
  każdym użyciu (odporność na kolejność startu zasobów);
- 🟡 `Config.Command.restricted` był martwy (zakomentowany przykład sprawdzenia ACE, i to
  z błędną natywką serwerową na kliencie — ten sam błąd co w 7.4) → komenda rejestruje się
  z wbudowanym flagiem FiveM `RegisterCommand(..., restricted)`; `restricted = true` wymaga
  teraz ACE `command.marketipls`. Domyślne `false` bez zmian w zachowaniu.
- ⚪ kolejność pozycji menu i listy `/pm_ipl list` była z `pairs()` (losowa) → iteracja po
  `Config.IPLs` (stała kolejność jak w configu); usunięty martwy blok `Config.Fallback`
  (nieczytany nigdzie; „autoLoad" i tak działa przez init stanów + sync).

**`prompt_sandy_fire2` (analiza + naprawy):**

- Zasób jest czysto mapowy (stream + timecycle + `replacelogo/` z podmianą logo 3D —
  folder pomocniczy z readme, celowo poza `stream/`). Jedynym kodem był `sv_loader.lua`.
- 🔴 **`sv_loader.lua` usunięty**; w miejsce analogiczny `sv_mapdata.lua`
  (`prompt_sandy_fire2` / „Firestation2" / `{"sandy"}`). Reszta bez zmian
  (komentarz o scaleniu audio do shared `prompt_audio` zostawiony — jest informacyjny).

**Podwójny wydruk — naprawa w `prompt_sandy_illegal_garage/server/server.lua`:**

- Raport ma teraz **strażnika `mapdataReportPrinted`** — drugie wywołanie to no-op
  (niezależnie od źródła: delegacja `:mapFinal`, self-check, restart wątków).
- Dodany **lokalny self-check**: po ~10 s od startu, jeśli nic nie wydrukowano i żaden
  obcy checker nie pytał nas o istnienie (`promptCheckerSeen` — flaga ustawiana w
  `replyExists`/`locations`), sami pytamy mapy o istnienie tymi samymi eventami co oficjalny
  skrypt (w kolejności rejestru, bez pytania samych siebie) i drukujemy raport **raz**.
  Dzięki temu raport nadal się pojawia (zniknąłby zupełnie po usunięciu obu checkerów),
  ale nigdy nie jest dublowany:
  - obcy checker delegujący `:mapFinal` → drukuje pierwszy, self-check milczy
    (strażnik + flaga);
  - obcy checker drukujący sam (gdy jest „ostatni" w rejestrze) → my milczymy (flaga);
  - brak jakichkolwiek checkerów (obecny stan repo) → drukuje self-check, raz.
- `PROMPT_MAP_NAMES` zmieniony w **uporządkowany rejestr** `PROMPT_MAP_REGISTRY`
  (snapshot `all_data_full` z kolejnością rejestru) — self-check pyta w tej samej
  kolejności, w jakiej oficjalny checker buduje `existList` i link
  (stąd link dokładnie `…/Firestation2+Market+Gas`).
- Uwaga: link w raporcie jest zawsze w formie `vertex-hub.com/...` (bez sieciowego
  „próbnika" URL GitHuba, który robi oficjalny skrypt) — dla obecnych zestawów map
  wynik jest identyczny jak na zrzucie.

**`cfx_prompt_sandy_mapdata/sv_MapDataHandler.lua` (hardening):**

- Callbacki (`prompt:mapdata_exists`, `lyn-mapdata:exists`, `<static>:mapDataExists`)
  wołane przez `pcall` (śmieciowy argument z eventu sieciowego nie wywali handlera;
  callable-ref też działa);
- `prompt:mapdata_sendList` waliduje typ `returnevent` i prefiks `promptmap:return_`
  (wszyscy znani pytający — oficjalny skrypt i nasze handlery — używają tego prefiksu),
  więc gracz nie może już wymusić `TriggerEvent` na dowolnej nazwie eventu serwera
  listą map jako argumentem (wcześniej: RegisterNetEvent + dowolny string).

**`prompt_sandy_shared` (tylko weryfikacja, brak zmian):** 32 ytyp-y leżą w `stream/`
(FiveM rejestruje ytyp-y ze `stream/` automatycznie; nieaktywny blok `data_file` w manifeście
to martwa pozostałość po innej ścieżce plików — nieszkodliwa). Komentarz „IPL LOADER SYSTEM"
w manifiecie opisuje system, którego **kodu w folderze nie ma** (ani jednego pliku Lua) —
prawdopodobnie zagubiony/escrowed element pakietu; na tę chwilę ładowanie IPL/i tak obsługuje
`prompt_sandy_market`. Do świadomej decyzji właściciela, czy ten loader jest potrzebny.

### 10.3. Weryfikacja

- **Składnia:** wszystkie 18 plików Lua w repo (w tym manifesty) przechodzą parser.
- **Mockowany harness FiveM** (event bus + wątki + wierny quirk referencji funkcyjnych
  między zasobami — callback jako callable-table o `type() ~= "function"`): **8/8 scenariuszy**:
  1. baseline (3 mapy + pełna mapdata): dokładnie **jeden** raport, Missing = 18 map,
     link `Firestation2+Market+Gas`, self-check pyta market/fire2 po razie i nie pyta siebie;
  2. dwa obce checkery (dawny bug): **jeden** raport, dwa logi „odpowiadam" (po jednym
     na pytającego), self-check pominięty;
  3. obcy checker bez delegacji (drukujący sam): my **milczymy** (brak dubla);
  4. podwójna delegacja `:mapFinal`: jeden raport (strażnik);
  5. mapdata == zainstalowane: raport „Mapdata is the same as maps installed";
  6. brak mapdata: raport „Mapdata does not exist" + link;
  7. hardening `sv_MapDataHandler` (zły typ/prefiks `returnevent`, śmieciowe callbacki,
     callable-ref);
  8. handlery `sv_mapdata` market/fire2 (istnienie, lokalizacje, fullName, śmieciowe
     callbacki, no-op `mapFinal`).
- **Niezeryfikowane (wymaga gry/serwera):** start zasobów na FXServerze i konsola
  (kolejność `ensure`), interakcja rynku/`/marketipls` z ox_lib i bez niego, zachowanie
  timecycle fire2 oraz podmiana logo 3D, pełny raport przy obcych checkerach na żywym
  serwerze.

### 10.4. Znane granice i uwagi

- Raport mapdata drukuje **`prompt_sandy_illegal_garage` (Gas)** — zgodnie z konwencją
  oficjalnego checkera (drukuje ostatnia mapa w rejestrze). Ktoś, kto uruchomi market/fire2
  **bez** gasa, nie zobaczy raportu (wykrywanie map nadal działa).
- Self-check czeka 10 s na ewentualne obce checkery; gdyby obcy checker startował
  później niż ~10 s po Gasie i drukował raport sam (bez delegacji), mogłyby wyjść dwa
  raporty — skrajny przypadek kolejności startu, taki sam jak w oficjalnym ekosystemie.
- `server.js`/`client.js` w `cfx_prompt_sandy_mapdata` (rejestracja assetów Vertex Hub:
  `RegisterResourceAsset` + `RegisterStreamingFileFromCache`) zostawione bez zmian —
  to lokalny mechanizm assetów mapdata, nie telemetryczny, a ruszenie go mogłoby
  uszkodzić streaming tej mapy.

## 11. Wspólna permisja ACE dla komend pakietu (`command.sandyshores`)

Data: 2026-10-18. Wszystkie komendy z repo sprawdzają teraz **jeden** obiekt ACE:
`command.sandyshores`. Konfiguracja serwera (server.cfg):

```cfg
# Prompt Sandy Shores — dostęp do komend (testsound, testanims, testautodoors_ig(_flow),
# marketipls, pm_ipl) dla wybranej grupy:
add_ace group.admin command.sandyshores allow
add_principal identifier.license:XXXX group.admin
```

Stare, rozproszone ACE (`command.testanims`, `command.testautodoors_ig`, ewentualne
`command.marketipls`) **nie są już sprawdzane** — linie w server.cfg można usunąć.

### 11.1. Zasady implementacji

- Komendy rejestrują się z `restricted = false` i sprawdzają permisję **ręczne** w handlerze
  (wbudowany flag FiveM patrzy na osobne `command.<nazwa_komendy>`, więc z `true` posiadacz
  `command.sandyshores` i tak zostałby zablokowany przed handlerem).
- Klient (`prompt_sandy_illegal_garage/client/client.lua`, `prompt_sandy_market/client.lua`):
  `IsAceAllowed("command.sandyshores")` — poprawna natywa po stronie klienta (por. 7.4);
  odmowa = komunikat w konsoli i przerwanie. Helper `canUseSandyCommand()` w obu plikach.
- Serwer (`prompt_sandy_illegal_garage/server/server.lua`, komenda `/testautodoors_ig`):
  `IsPlayerAceAllowed(source, ...)`; **konsola serwera (source 0) przechodzi zawsze**
  (jak dotychczas); próba gracza bez ACE jest logowana i odrzucana.
- **Egzekwowanie serwerowe w markecie** (`prompt_sandy_market/server.lua`): eventy
  `ipl_manager:requestLoad/requestUnload/requestToggle/requestLoadAllEnabled/requestUnloadAll`
  są `RegisterNetEvent`, więc klient mógłby je wywołać z pominięciem komend — wszystkie
  pięć sprawdza teraz to samo ACE po stronie serwera (gracz bez ACE nie zmieni stanu IPL
  nawet zmodowanym klientem). Wyjątek: `ipl_manager:requestSync` (sam odczyt stanu) zostaje
  otwarty — IPL-e marketu to widoki świata i **każdy** klient musi je zaaplikować lokalnie
  (zablokowanie synca sprawiłoby, że gracze bez ACE widzieliby market bez stoisk).
- `Config.Command.restricted` w `prompt_sandy_market/config.lua` usunięty (zastąpiony
  wspólną permisją); zostają `name`/`description`.
- Poza zakresem (niekomendowe): `open_functions.lua` nadal obsługuje opcjonalne ACE
  per-prop (`propConfig.acePermission`) — to inna warstwa uprawnień, nietknięta. Eksporty
  zasobów (`loadIPL`, `loadIPLServer`, `setLiftState`, …) wywoływane między zasobami nie
  przechodzą bramki gracza (kontroluje je wywołujący zasób).

### 11.2. Lista objętych komend

| Komenda | Zasób | Strona | Poprzednie ograniczenie |
|---|---|---|---|
| `/testsound` | illegal_garage | client | `command.testsound` (wbudowane) |
| `/testautodoors_ig_flow` | illegal_garage | client | `command.testautodoors_ig_flow` (wbudowane) |
| `/testanims` | illegal_garage | client | `command.testanims` (wbudowane) |
| `/testautodoors_ig` | illegal_garage | server | `command.testautodoors_ig` (wbudowane) |
| `/marketipls` | market | client | `Config.Command.restricted` (domyślnie brak) |
| `/pm_ipl` | market | client | brak (dostępna dla wszystkich) |

### 11.3. Weryfikacja

- Składnia: 18/18 plików Lua.
- Harness: **10/10 scenariuszy** — doszły: S9 (eventy mutujące marketu odrzucone bez ACE,
  broadcast `stateChanged` z ACE, `requestSync` otwarty dla wszystkich) i S10 (komendy
  marketu zarejestrowane z `restricted=false`, odmowa bez ACE bez żądań serwerowych,
  menu/`pm_ipl` działają z ACE).
- Do sprawdzenia w grze: odmowa komendy bez ACE (komunikat w konsoli F8), przejście
  z nadanym `command.sandyshores`, `/testautodoors_ig` z konsoli serwera, wizualna
  obecność stoisk marketu u gracza BEZ ACE (efekt „requestSync otwarty").

## 12. Scalenie z `main`: nowe mapy `prompt_sandy_apts` i `prompt_sandy_hospital2`

Data: 2026-10-18. Przy scalaniu PR (gałąź rund 10–11) z `main` doszły tam dwa nowe zasoby
map (commity „add 2 new interiors"/„update"): `prompt_sandy_apts` (Sandy Shores Apartments)
i `prompt_sandy_hospital2` (szpital). Oba przyszły ze **swoimi `sv_loader.lua`** (skrypt
dekompilatora z tym samym zdalnym kodem + telemetrią, tylko z własnym `MapId`) oraz
z **12 nowymi komendami** bez bramek. Żeby scalenie nie przywróciło naprawionych błędów
(dwa checkery = podwójny raport; obce komendy bez ACE), włączone w oba systemy z rozdz. 10–11:

- **`sv_loader.lua` usunięte** z obu map (konflikty rename/delete rozstrzygnięte jako
  świadome usunięcie); w ich miejsce `sv_mapdata.lua` z właściwymi stałymi
  (`prompt_sandy_apts`/„Apts", `prompt_sandy_hospital2`/„Hospital2") — mapy są widoczne
  dla checkera bez zdalnego kodu i telemetrii. Wpisy `server_scripts` w obu manifestach
  podmienione.
- **Komendy pod `command.sandyshores`** (razem 18 komend w repo):
  - `prompt_sandy_apts/debug_commands.lua` (client, plik aktywny tylko przy `Config.Debug`):
    `/apts_status`, `/apts_here`, `/apts_stream`, `/apts_nuke`, `/apts_tp` — helper
    `canUseSandyCommand()` + check w każdym handlerze;
  - `prompt_sandy_hospital2/client/debug.lua` (client): `/scenario`, `/scenarioat`,
    `/stopanim`, `/mycoords`, `/propcoords` — jw.;
  - `prompt_sandy_hospital2/server/mri.lua` (server): `/testmri` (wcześniej wbudowane
    `command.testmri`) i `/testoperator` (wcześniej ręcznie `command.testmri`) — oba
    teraz `IsPlayerAceAllowed(..., 'command.sandyshores')`; `/testmri` rejestruje się
    z `restricted=false` + ręczny check (jak reszta pakietu).

Weryfikacja: składnia wszystkich plików Lua (25+ po dodaniu nowych map), harness
rozszerzony o scenariusze rejestracji mapdata nowych map i bramek ich komend
(12/12 scenariuszy łącznie). Do sprawdzenia w grze: wykrywanie Apts/Hospital2 przez
raport mapdata (Missing bez „Apts"/„Hospital2" po ich zainstalowaniu), brak logów
odpowiadania przy braku obcych checkerów, odmowa komend debug bez ACE.

Uwaga: nowe mapy nie były analizowane funkcjonalnie na poziomie rynku/garażu
(skala „rozdziału 7") — dotknięto wyłącznie ich integracji z mapdata i permisjami.

## 13. Runda: `prompt_sandy_church`, `prompt_sandy_cityhall`, `prompt_sandy_sheriff` (+ ostatnie pliki `prompt_sandy_apts`)

Data: 2026-10-20. Ostatnie zasoby z **kodem dekompilatora** (wzorce `L0_1`/`A0_2`/
`goto lbl_N` — dokładnie 9 plików) oraz jedyne trzy mapy, które jeszcze nosiły
`sv_loader.lua`. Po tej rundzie w repo **nie ma ani jednego pliku dekompilowanego
ani jednej aktywnej referencji do `sv_loader`** (pozostałe wzmianki to komentarze
dokumentacyjne).

### 13.1. Przepisane pliki (6, in situ, wartości 1:1)

| Plik | Zawartość po przepisie |
|---|---|
| `prompt_sandy_cityhall/client/utils.lua` | biblioteka easingu Bezier (A/B/C, `calcBezier`, `getSlope`, `newtonRaphsonIterate`, `bezier`, `math.lerp`/`math.invlerp` — globalnie, celowo) + `TranslateObjectCoordsCubicBezier(entity, endCoords, duration, curveType, curveKey, targetFloor, startTime)`; `EASING_PRESETS` zachowany jako udokumentowany nie-używany local (dekompilacja go definiowała) |
| `prompt_sandy_cityhall/internal_config.lua` | czysty `Config.Elevator` — wszystkie współrzędne/krzywe/czasy 1:1 z dekompilacją, komentarze PL |
| `prompt_sandy_cityhall/server/server.lua` | `GlobalState.elevator` (inicjalizacja), `waitForPlayerDoorAnimation` (deadline 7000 ms, poll 50 ms), `elevator:updateState` (walidacja: tabela, `isMoving`, istnienie `targetFloor` ≠ `currentFloor`, `serverId` tylko jeśli `== source`, blokada `doorAnimationBusy`, clamp duration 3000..15000, `SetTimeout(duration + doorDur*2 + 300)` → stan arrive → odblokowanie), relacja animacji białą listą dict/anim; **zachowana** bezręczna linia `RegisterServerEvent("prompt_elevator:send:animation")` — zarejestrowane bez handlera; to poprawne API FXServera (potwierdzone użyciem w publicznych `server.lua`) |
| `prompt_sandy_cityhall/client/client.lua` | pełny klient windy: bramki `ox_lib`/`static_elevator_replace` (przebudowane na early-return — semantyka identyczna), `interiorId` z `GetInteriorAtCoords(1753.6223, 3804.645, 35.4474)`, globalne API dla `open.lua` (`getNearestFloor`, `calculateElevatorDuration`, `SelectFloor`, `CallElevator`, 4 funkcje dźwięku/animacji), strefa spawnu `lib.points` (promień 35), statebag `"elevator"` (`moving` → zamknięcie drzwi + wątek `animateIndicators`/`moveElevatorToFloor`; `arrived` → dzwonek + otwarcie), callback `elevator:playerDoorAnimation` (matematyka rotacji, `TaskPedSlideToCoord` limit 5 s), netevent `prompt_elevator:sync:animation` (bramka room −1984934778, `TaskPlayAnim` z `lockZ` = przekazany heading bez zmian), sprzątanie przy `onResourceStop` |
| `prompt_sandy_apts/interior_manager.lua` | 3 zbiory budynków (strefy target 50 m, ukrywanie `CreateModelHide` promień 50, próg Z 46), wątki 5 s / 1 s / baner 3 s |
| `prompt_sandy_apts/proximity_loader.lua` | strategię `auto_stream_only`/`proximity_ipl`, strefy wykluczenia (ściana + box), harmonogram `CheckScaling`, entity sets (furnished/shell_only), wątki: anti-autostream przy starcie, pętla bliskości (max 6 najbliższych), sweep 10 s, init statycznych (5×1 s), eksporty 1:1 (`GetInteriorMode`/`SetInteriorMode`/`GetLoadedIPLsCount`/`IsIPLLoaded`/`GetStrategy`) |

### 13.2. Świadome normalizacje i usuwanie martwego kodu (brak zmiany zachowania)

- **`AddStateBagChangeHandler`** — kolejność argumentów potwierdzona deklaracją
  natywnej CFX: callback to `(bagName, key, value, reserved, replicated)`,
  rejestracja `(keyFilter, bagFilter, handler)`. W przepisie:
  `AddStateBagChangeHandler("elevator", nil, function(bagName, key, newState)`.
- `AttachEntityToEntity`: `vertexIndex = false` → `0`, `collision = 2` → `true`
  (normalizacja do formy garażowej po naprawie).
- `TaskPlayAnim`: 12. argument (`lockZ`) przechodzi **bez zmian** (wierność,
  nie normalizacja) — w oryginale był tam heading.
- Wywołanie animacji drzwi windy jest **bajt w bajt** identyczne z naprawioną
  formą garażu (`PlayEntityAnim(entity, anim, dict, 8.0, false, true, false, 0.0, 0)`)
  → nie wymagała naprawy pętli, tylko przepisania.
- Usunięte martwe fragmenty (wynik nikt nie odczytywał / bez skutków ubocznych):
  - `ensureElevatorState` (client) — syła event `elevator:initializeState`, na który
    **nie ma żadnego handlera**;
  - nie-używany local `isInsideElevator` (globalny prowadzi `open.lua`);
  - `isPlayerInAnyKnownInterior` + jej martwe wywołanie (apts, wątek 1 s);
  - duplikat `IsInteriorEntitySetActive` w `setupEntitySetsForIpl` (apts).
- `pointInPolygon` (apts): pętla krawędzi przepisana na `(punkty[i], punkty[i+1])`
  — ten sam zbiór krawędzi co w dekompilacji (odwrotna orientacja indeksów nie
  zmienia wyniku — test `pointOnSegment` jest niezależny od orientacji).

### 13.3. `sv_loader` → lokalny `sv_mapdata` (church / cityhall / sheriff)

- **Usunięte**: `prompt_sandy_church/sv_loader.lua`, `prompt_sandy_cityhall/sv_loader.lua`,
  `prompt_sandy_sheriff/sv_loader.lua` (decyzja właściciela 7.1/8.1 — zdalny kod + telemetria).
- **Dodane**: `sv_mapdata.lua` w każdym z trzech (wzór apts/market/fire2/hospital2):
  wyłącznie handlery wykrywania (`<MapId>:mapExists`, `promptmap:i_exist_<MapId>`,
  `promptmap:locations_<MapId>`, `<MapId>:mapFullNameSend`, legacy `:mapFinal`),
  callbacki odpowiadają przez `pcall` (referencja funkcyjna z innego zasobu),
  brak sieci. Stałe: `prompt_sandy_church`/„Church", `prompt_sandy_cityhall`/„Cityhall",
  `prompt_sandy_sheriff`/„Sheriff", `MAP_LOCATIONS = { "sandy" }` (nazwy 1:1 z rejestrem
  `PROMPT_MAP_REGISTRY` w `prompt_sandy_illegal_garage`).
- **Manifesty**: `server_scripts` — `sv_loader.lua` → `sv_mapdata.lua`;
  `prompt_sandy_cityhall/fxmanifest.lua` dodatkowo `dependency 'ox_lib'`
  (klient używa `lib.points`/`lib.zones`/`lib.callback` — poprzednio tylko kontrola
  `GetResourceState("ox_lib")` raz przy starcie); `dependency '/assetpacks'`
  zachowane wszędzie. `prompt_sandy_apts/fxmanifest.lua` — bez zmian (już po 12. rundzie).

### 13.4. Cityhall: ACE + wzmocnienia (wzór 10.2/11)

- `/cityhall` → `RegisterCommand("cityhall", ..., false)` + `canUseSandyCommand()`
  (client: `IsAceAllowed("command.sandyshores")`) — po tej rundzie **wszystkie komendy
  pakietu (19) są pod jednym ACE** `command.sandyshores`.
- `ipls_server.lua`: oba handlery (`ipls:sync:toggleIPL`, `ipls:sync:toggleEntitySet`)
  teraz: `IsPlayerAceAllowed(source, "command.sandyshores")` **i** walidacja nazwy
  przeciw białej liście (12 IPL / 4 entity sets, lista 1:1 z inicjalizacją
  `GlobalState`). Sfałszowany klient nie może już wpisać do replikowanego statebag
  dowolnego klucza. Dodatkowo: `state` normalizowane do boola i straż `GlobalState.ipls
  == nil` (wyścig startu; oryginał wywalał błąd, stan i tak by się nie zmienił).
- `ipls_command.lua`: `pairs()` w trzech menu → **stabilne kolejności**
  (`IPL_ORDER`/`ENTITY_SET_ORDER`/`PRESET_ORDER`) — ta sama poprawka co w marketu (10.2).
  `ipls:openMenu` (netevent klienta) zostaje otwarty — otwiera tylko menu po stronie
  klienta; każda mutacja stanu idzie przez zablokowane serwerek eventy.

### 13.5. Weryfikacja

- **Harness lupa** (mocki globali FiveM, wykonanie kodu top-level każdego pliku):
  wszystkie pliki kodowe OK. Harness **wyłapał realny błąd przepisu**: `vec3(...)`
  zamiast `vector3(...)` w `internal_config.lua` (4 miejsca) — naprawiono.
- **Artefakt harnessa (ważne do powtórzenia)**: buildy Lua w lupa 2.8 kompilują
  wywołania `f 'a' 'b'` (≥2 łącznie-rozdzielone argumenty-łańcuchy) jako
  `(f 'a')('b')` — sprawdzone na `print 'a' 'b'` nawet w wariancie `lua54`.
  To błąd samego lupa, NIE Lua 5.4 (FiveM) — dlatego manifesty (pełne tej składni,
  standardowo w FiveM) zweryfikowano niezależnym parserem.
- **`luaparser`** (niezależna gramatyka Lua 5.3/5.4 z PyPI): **47/47** plików `.lua`
  poza `stream/` w całym repo — zero błędów składni.
- Grep: zero wzorców dekompilatora poza komentarzami-nagłówkami plików przepisanych;
  zero aktywnych referencji `sv_loader` (same komentarze).

### 13.6. Do sprawdzenia w grze

- Pełny cykl windy: wezwanie (strefa call), wejście, wybór piętra, animacje drzwi
  (otwarcie/zamknięcie + slide gracza), dojazd z easingiem, dzwonek, spawn przy wyjściu.
- `/cityhall` bez ACE — odmowa (komunikat w konsoli F8); z `command.sandyshores` —
  menu; kolejność pozycji menu stała (12 IPL w kolejności `IPL_ORDER`).
- Zmiany z menu widoczne u wszystkich graczy (statebag) — i tylko z ACE
  (próbna zmiana bez ACE nie zmienia stanu).
- Apts: budynki chowają się wewnątrz / odzyskują po wyjściu; IPL ładowane wg
  odległości (strategia `proximity_ipl`) albo auto-stream (`auto_stream_only`).
- Raport mapdata: `Church`, `Cityhall`, `Sheriff` widoczne jako obecne bez zdalnego
  checkera.

Uwaga: `stream/` jak zawsze nietknięte (trwała decyzja właściciela).

## 14. Runda: `prompt_sandy_bank`, `cfx_chuz_sandy_shores_boat_house`, `prompt_sandy_beaches`

Data: 2026-10-21. Zakres: trzy nowe interiory z commitu `add bank, boat house, beaches`:
- **`prompt_sandy_bank`** (Sandy Shores Bank — `"Bank"` w rejestrze `all_data_full`),
- **`cfx_chuz_sandy_shores_boat_house`** (Boat House — `"Boathouse"` w rejestrze `all_data_full`),
- **`prompt_sandy_beaches`** (Sandy Shores Marina — `"Marina"` w rejestrze `all_data_full`),

plus usunięcie ostatnich wzmianek wzorców dekompilatora nawet z komentarzy nagłówkowych starszych
plików Lua (zero trafień w całym repozytorium — 57/57 plików `.lua` poza `stream/`).

### 14.1. `sv_loader.lua` → lokalny `sv_mapdata.lua` (wszystkie 3 nowe interiory)

- **Usunięte:**
  - `prompt_sandy_bank/sv_loader.lua` (jawny kod dekompilatora ze zdalnym `load()` i telemetrią z 7.1),
  - `prompt_sandy_beaches/sv_loader.lua` (jawny kod dekompilatora jw.),
  - `cfx_chuz_sandy_shores_boat_house/sv_loader.lua` (zaszyfrowany binarnie nagłówkiem `FXAP\x01`, 2150 B).
- **Dodane:** lokalne `sv_mapdata.lua` (wzór 1:1 z `church`/`cityhall`/`sheriff`/`apts`/`hospital2`/`market`/`fire2`),
  rejestrujące wyłącznie lokalne handlery wykrywania (`<MAP_ID>:mapExists`, `promptmap:i_exist_<MAP_ID>`,
  `promptmap:locations_<MAP_ID>`, `<MAP_ID>:mapFullNameSend`, pusty `<MAP_ID>:mapFinal`) z wywołaniem
  callbacku przez `pcall`:
  - `prompt_sandy_bank/sv_mapdata.lua` → `MAP_ID = "prompt_sandy_bank"`, `MAP_NAME = "Bank"`, `MAP_LOCATIONS = { "sandy" }`,
  - `cfx_chuz_sandy_shores_boat_house/sv_mapdata.lua` → `MAP_ID = "cfx_chuz_sandy_shores_boat_house"`, `MAP_NAME = "Boathouse"`, `MAP_LOCATIONS = { "sandy" }`,
  - `prompt_sandy_beaches/sv_mapdata.lua` → `MAP_ID = "prompt_sandy_beaches"`, `MAP_NAME = "Marina"`, `MAP_LOCATIONS = { "sandy" }`.
  Nazwy `MAP_ID`/`MAP_NAME`/`MAP_LOCATIONS` zweryfikowano bezpośrednio względem aktualnego `all_data_full`
  z `Prompt-Coder/mapdatachecker` oraz `PROMPT_MAP_REGISTRY` w `prompt_sandy_illegal_garage/server/server.lua`.
- **Manifesty (`fxmanifest.lua`):** podmieniono `sv_loader.lua` → `sv_mapdata.lua` we wszystkich trzech zasobach;
  w `prompt_sandy_beaches/fxmanifest.lua` usunięto zduplikowane `dependency '/assetpacks'`;
  w `cfx_chuz_sandy_shores_boat_house/fxmanifest.lua` dopisano `'sv_mapdata.lua'` do `escrow_ignore`.
- **Komendy ACE:** żaden z trzech nowych interiorów nie rejestruje własnych komend (`RegisterCommand`),
  więc pula komend pakietu objętych `command.sandyshores` pozostaje kompletna.

### 14.2. ⚠️ Ważna uwaga dot. Asset Escrow w `cfx_chuz_sandy_shores_boat_house`

W odróżnieniu od `prompt_sandy_bank` i `prompt_sandy_beaches` (które przeszły wcześniej przez LuaClear),
zasób `cfx_chuz_sandy_shores_boat_house` został dodany **w postaci zaszyfrowanej CFX Asset Escrow**:
- w katalogu głównym zasobu znajduje się plik `.fxap` (185 B, nagłówek `FXAP\x01`), którego **celowo nie usuwano**,
- usunięty `sv_loader.lua` również miał nagłówek `FXAP\x01` (2150 B), co wskazuje, że pliki modeli
  w `stream/locked/*` są nadal zaszyfrowane escrowem.

Skutek praktyczny:
- **jeśli klucz licencyjny serwera posiada uprawnienie Keymaster do `cfx_chuz_sandy_shores_boat_house`** —
  pozostawiony `.fxap` pozwoli FXServerowi odszyfrować `stream/locked/*`, a jawny `sv_mapdata.lua` zadziała
  normalnie bez zdalnego kodu i bez dublowania raportu mapdata;
- **jeśli serwer NIE ma licencji Keymaster na ten zasób** — FXServer zgłosi `You lack the required entitlement`
  dla zaszyfrowanych assetów i zasób trzeba najpierw odszyfrować tak samo jak pozostałe interiory
  (zachowując po odszyfrowaniu obecny `fxmanifest.lua` i `sv_mapdata.lua`).

### 14.3. Przepisane pliki Lua w `prompt_sandy_beaches` (czysty kod Lua + naprawy błędów)

Wszystkie 4 pliki skryptowe w `prompt_sandy_beaches` były w zapisie dekompilatora (`L0_1`, `A0_2`, `goto lbl_N`)
i zostały w całości przepisane na czytelny, idiomatyczny kod Lua:

| Plik | Przed | Po | Zakres |
|---|---|---|---|
| `prompt_sandy_beaches/config.lua` | 16 linii | 22 | `Config.Debug`, `Config.EnablePromptSupporter`, `Config.Zones.alamo_sea` (1:1) |
| `prompt_sandy_beaches/weather_prop_controllers.lua` | 44 linie | 19 | ustawianie convaru `"Prompt supporter"` (1:1) |
| `prompt_sandy_beaches/weather_prop_controller.lua` | 416 linii | 246 | 4 warianty dynamicznych propów przy rampie łodzi (pogoda + pora dnia + dystans) |
| `prompt_sandy_beaches/client.lua` | 1444 linie | 382 | konfiguracja 78 `Water_Quads` + 3 `Calm_Quads` dla Alamo Sea |

### 14.4. Wykryte i naprawione błędy w `prompt_sandy_beaches`

1. 🔴 **Krytyczny crash wątku startowego w `client.lua` (woda w ogóle się nie konfigurowała!):**
   - Natywka FiveM `GetWaterQuadBounds(quadId)` zwraca **5 wartości**: `found (bool), minX, minY, maxX, maxY`
     — identycznie jak `GetCalmingQuadBounds` (potwierdzone bezpośrednio w źródłach C++ `citizenfx/fivem`:
     `code/components/extra-natives-five/src/WaterExtraNatives.cpp` oraz testem na żywym runtime Lua 5.4).
   - W wątku `CreateThread` (oraz w helperze `getWaterQuadBounds`) autor rozpakował tylko **4 zmienne**:
     `minX, minY, maxX, maxY = GetWaterQuadBounds(waterQuad)` i wywołał
     `string.format("  WaterQuad %d bounds: minX=%.0f, ...", waterQuad, minX, ...)` **przed** wejściem do `debugLog`
     (czyli nawet przy `Config.Debug = false`!).
   - Ponieważ dla punktu diagnostycznego `(1076.0, 3930.0)` `waterQuad = 506 ~= -1`, `minX` dostawało wartość
     `true` (`boolean`), a Lua 5.4 rzucała nieobsłużony wyjątek:
     `bad argument #3 to 'format' (number expected, got boolean)` — **zabijając cały wątek zanim pętla
     `for zoneName, zoneConfig in pairs(Config.Zones)` zdążyła wykonać choćby jedną zmianę wody w Alamo Sea!**
   - **Naprawa:** rozpakowanie pełnych 5 wartości `local found, minX, minY, maxX, maxY = GetWaterQuadBounds(...)`
     ze sprawdzeniem `if found then ... end` zarówno w `CreateThread`, jak i w `getWaterQuadBounds`.

2. 🟠 **Rekonstrukcja uszkodzonego przez dekompilator warunku `matches` w `findMatchingQuad` (`client.lua`):**
   - Dekompilator LuaClear uszkodził 4-członową koniunkcję porównującą granice quada (ten sam typ uszkodzenia co w rozdz. 2):
     zostawił jedynie `math.abs(minX - origMinX) <= 10.0` (mimo zdekodowania `origMinY`, `origMaxX`, `origMaxY` oraz
     `minY`, `maxX`, `maxY` tuż wyżej), a kilka linii niżej odwołał się do **niezadeklarowanej zmiennej globalnej `matches`**.
   - Przy niestandardowym `water.xml` (np. połączony `WaterQuad[52]` o `minX = 848, maxX = 1304, maxY = 4224` z pliku
     referencyjnego `prompt_sandy_beaches/water.xml`) samo sprawdzenie `minX == 848` błędnie dopasowywałoby połączony quad
     jako quad `488` i przycinało go do `maxX = 1000, maxY = 4000`, osuszając duży fragment jeziora.
   - **Naprawa:** odtworzono pełne sprawdzenie wszystkich 4 granic (`minX`, `minY`, `maxX`, `maxY` w tolerancji `10.0`)
     oraz dodano bezpieczny fallback dopasowujący również granice docelowe z `MODIFIED_QUADS`, dzięki czemu
     żywy restart zasobu (`/restart prompt_sandy_beaches`) w trakcie sesji nadal poprawnie rozpoznaje i aktualizuje
     wszystkie 78 quadów (także te o przesuniętym już brzegu).

3. 🟡 **Poprawki odporności w `weather_prop_controller.lua`:**
   - Jawne 6 argumentów `Vdist(playerCoords.x, playerCoords.y, playerCoords.z, coords.x, coords.y, coords.z)`.
   - Limit czasu `5000 ms` przy `RequestModel`/`HasModelLoaded` + sprawdzenie `IsModelInCdimage` oraz
     `SetModelAsNoLongerNeeded` po utworzeniu obiektu (brakujący model nie zawiesi wątku w pętli `Wait(1)`).
   - Dodany handler `onResourceStop` usuwający zespawnowane propy (`SetEntityAsMissionEntity`), aby restart
     zasobu nie zostawiał osieroconych duplikatów na rampie łodzi.

### 14.5. Weryfikacja

- **Parser AST (`luaparser`):** **57/57** wszystkich plików `.lua` poza `stream/` w całym repozytorium przechodzi parsowanie bez błędów.
- **Czystość kodu:** **0** plików `sv_loader.lua` i **0** wystąpień wzorców dekompilatora (`L0_1`, `A0_2`, `lbl_`) w całym repozytorium (również w komentarzach).
- **Harness Lua 5.4 (`lupa.lua54`) — 34/34 sprawdzeń PASS:**
  - zgodność 1:1 danych i logiki wszystkich przepisanych plików z wersją z `HEAD` (wszystkie 78 `Water_Quads`,
    3 `Calm_Quads`, 4 zmodyfikowane `Water_Quads`, 3 zmodyfikowane `Calm_Quads`, `config.lua`, oba warianty `weather_prop_controllers.lua`),
  - pełne wykonanie wątku startowego `client.lua` (zarówno przy `Config.Debug = false`, jak i `Config.Debug = true`),
    żywy restart zasobu z nowymi parametrami `waterLevel`/`waterAlpha` oraz ochrona przed fałszywym dopasowaniem połączonego `WaterQuad[52]`,
  - pełny cykl `weather_prop_controller.lua` (`sunny` → `rainy` → `storm` → `moon_clear` → wyjście poza 50 m → sprzątanie `onResourceStop`),
  - integracja wszystkich **11 zainstalowanych map Sandy** + `cfx_prompt_sandy_mapdata`: pojedynczy wydruk raportu,
    `Bank`, `Marina` i `Boathouse` znikają z listy `Missing`, a wygenerowany link ma dokładną postać:
    `https://vertex-hub.com/prompt/map-data/sandy-rework/Firestation2+Hospital2+Apts+Bank+Market+Gas+Church+Cityhall+Marina+Boathouse+Sheriff`.
- **Stan repozytorium:** zero zmian w jakimkolwiek folderze `stream/`.
