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

Pozostałe pliki były już w normalnym zapisie i **nie były edytowane** w tej rundzie
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
  ale zablokować telemetrię/własnoręcznie hostować kod. **W tej rundzie pliku nie usuwano ani manifestu
  nie zmieniano — tylko przepisano format.**

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
  sygnatura: [PLAY_ENTITY_ANIM](https://docs.fivem.net/natives/?_0xD201F3FF917A506D=)).
  Wszystkie wywołania przekazują te same `(…, 0, false, true, 0.0, 0)`, więc w praktyce każda
  animacja (też open/close) idzie z `bLoop=true`. Konwersja liczby na BOOL natywki jest zależna
  od marshalingu — **do zweryfikowania w grze**, czy klipy nie zapętlają się zamiast trzymać ostatnią klatkę.
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

## 8. Rekomendowana kolejność napraw (następny krok, jeszcze niewykonane)

1. Decyzja ws. `sv_loader.lua` w manifeście (7.1) i ograniczenie `/testanims` przez ACE (7.2.5).
2. Naprawy funkcjonalne: `onExecute`/global floorgate (7.2.1), kształt `playerAnimation` silnika (7.2.2),
   `moveType="rotation"` + pomijanie kolizji statycznych (7.2.3), weryfikacja kierunku kolizji w grze (7.2.4).
3. Twardnienie serwera: jeden autorytatywny event przełączania propa + watchdog na `busy` (7.3, 7.4).
4. Porządki: `EnablePlayerAnimations`, ACE na kliencie, zależności w manifeście, komentarze czasów w configu.

## 9. Weryfikacja wykonana w tej rundzie

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

**Niezeryfikowane (wymaga gry/serwera):** rzeczywiste odtwarzanie animacji (w tym zachowanie
`bLoop/bHoldLastFrame`), kierunek ruchu kolizji względem modeli, timing `GetAnimDuration`,
interakcje stref/ox_target/qb-target na żywym kliencie oraz cała zawartość `stream/`.
