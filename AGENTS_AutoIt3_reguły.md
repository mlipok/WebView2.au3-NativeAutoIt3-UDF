# Reguły AutoIt3 — tłumaczenie polskie

## Wykluczenia z kontroli

- Nie sprawdzaj plików pasujących do wzorca `*_stripped.au3`.
- Nie sprawdzaj plików pasujących do wzorców `* copy.au3` lub `*-copy.au3`, także ich odpowiedników w języku środowiska Windows, takich jak polskie `* kopia.au3` i `*-kopia.au3`.
- Nie sprawdzaj plików pasujących do wzorca `*.au3.bak`; są to kopie zapasowe tworzone przez narzędzia takie jak grepWin.
- Nie sprawdzaj katalogów o nazwie `BackUp` ani katalogów pasujących do wzorca `*test*`, włącznie z zawartymi w nich plikami i podkatalogami.
- Dopasowuj te wzorce bez rozróżniania wielkości liter.
- Stosuj wykluczenia podczas wyszukiwania odwołań, analizy zależności, przeglądu kodu i wprowadzania zmian.

## Kontrola kodu AutoIt

Wszystkie pliki źródłowe `*.au3` w repozytorium utrzymuj w kodowaniu **UTF-8 bez BOM** (plik nie może zaczynać się od `EF BB BF`) i z zakończeniami linii CRLF. Przy każdej zmianie sprawdź kodowanie przed zapisem oraz po zapisie i po uruchomieniu narzędzi formatujących; jeśli edytowany plik ma BOM, usuń go przy zapisie. Nie zastępuj UTF-8 kodowaniem UTF-16. Stała `$FO_UTF8_NOBOM` określa tryb odczytu lub zapisu plików przez `FileOpen()` i nie zastępuje kontroli kodowania samego pliku źródłowego `*.au3`. Ta zasada nie rozszerza zakresu plików dopuszczonych do pracy w danym zadaniu.

Używaj przenośnej instalacji AutoIt znajdującej się w `Z:\AutoItPortable\`:

- AutoIt 3.3.18.0: `Z:\AutoItPortable\App\AutoIt3.exe`.
- Au3Check 3.3.18.0: `Z:\AutoItPortable\App\Au3Check.exe`.
- Tidy 25.205.1420.7: `Z:\AutoItPortable\App\SciTE\Tidy\Tidy.exe`.

Po każdym przygotowaniu lub zmodyfikowaniu kodu `*.au3` uruchom kolejno:

1. Tidy — formatowanie kodu.
2. Au3Check — kontrolę składni i błędów, z parametrami:
   `-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7`.

Uruchamiaj Tidy wyłącznie z jawną ścieżką do istniejącego, konkretnego pliku `.au3`, przekazaną jako jedyny argument zgodnie z plikiem SciTE `au3.properties` tej instalacji. Nie dodawaj `/q`. Bezwzględnie zabrania się uruchamiania Tidy bez ścieżki pliku lub z parametrem `/?`, także w celu przetestowania programu, sprawdzenia składni wywołania, wyświetlenia pomocy albo diagnozowania problemu. Takie wywołania mogą otworzyć interaktywne okno wyboru pliku i pozostawić działający proces `Tidy.exe`. Sposób użycia ustalaj z dokumentacji lub istniejących poprawnych wywołań, bez testowego uruchamiania Tidy w ten sposób.
Po wywołaniu Tidy sprawdź, czy proces zakończył działanie; jeśli pojawi się okno wyboru pliku, zamknij je i upewnij się, że nie pozostał osierocony proces `Tidy.exe`.

Jeżeli Au3Check nie uruchomi się w ograniczonym środowisku Codex z powodu błędu relokacji DLL lub błędu uruchomienia procesu, ponów to samo polecenie poza tym środowiskiem, używając `Z:\AutoItPortable\App\Au3Check.exe`. Zapisz ścieżkę narzędzia, wersję, kontekst uruchomienia oraz rzeczywistą liczbę błędów i ostrzeżeń. Nigdy nie przedstawiaj niepowodzenia uruchomienia narzędzia jako wyniku kontroli składni. Moduły zależne sprawdzaj przez ich publiczny plik wejściowy `#include`, jeżeli samodzielna kontrola nie ma dostępu do wymaganych deklaracji.

Jeżeli plik używa dyrektywy AutoIt3Wrapper, stosuj dokładnie:

```autoit
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
```

W raporcie zmian podaj wynik obu kontroli, w tym wszystkie błędy i ostrzeżenia. Jeżeli któregoś narzędzia nie można uruchomić, zaznacz to wyraźnie w raporcie.

Zmiany ograniczone wyłącznie do koloru, rozmiaru lub położenia elementów interfejsu nie wymagają testów GUI. Nie uruchamiaj testu GUI tylko po to, aby potwierdzić takie zmiany. Nadal wykonuj Tidy i Au3Check dla zmodyfikowanych plików `*.au3`. Jeśli równocześnie zmieniasz zachowanie programu, sprawdź to zachowanie w niezbędnym zakresie.

## Nagłówki funkcji AutoIt, tworzenie UDF-ów i dobre praktyki programowania

- Przed utworzeniem lub przeglądem UDF-u sprawdź także `AutoIt_Best_coding_practices.md`: wskazówki dotyczące używania funkcji, nazw i zasięgu zmiennych, inicjalizacji, stałych, dyrektyw Au3Check, liczb magicznych oraz `#include-once`. Traktuj te wskazówki jako zalecenia; w razie rozbieżności stosuj szczegółowe zasady repozytorium zapisane w tym pliku.
- Przy pisaniu, przeglądaniu lub wywoływaniu funkcji AutoIt sprawdzaj `Function_notes.md` w zakresie wartości funkcji, parametrów opcjonalnych, wartości zwrotnych, `@error` i `@extended`. Jeśli wywoływana funkcja sygnalizuje niepowodzenie przez `@error`, sprawdź tę wartość bezpośrednio przed użyciem wyniku funkcji.
- Przed napisaniem lub przeglądem nagłówka funkcji AutoIt sprawdź `UDF-spec.md`, zwłaszcza **Functions → Headers** i **Internal use only**. Strona źródłowa jest oznaczona jako opracowywana; w razie rozbieżności stosuj poniższe zasady właściwe dla repozytorium.
- Dla funkcji publicznych używaj bloku `; #FUNCTION#`, a dla funkcji pomocniczych `; #INTERNAL_USE_ONLY#`. Zachowuj standardowy układ pól używany w tym repozytorium: `Name`, `Description`, `Syntax`, `Parameters`, `Return values`, `Author`, `Modified`, `Remarks`, `Related`, `Link`, `Example`.
- `Description` powinien być zwięzły. W `Parameters` wyjaśnij znaczenie argumentów, wartości domyślnych i `ByRef`, jeśli wpływają na sposób użycia funkcji. Nagłówek musi odpowiadać rzeczywistej sygnaturze i ścieżkom wykonania.
- W `Modified` wymieniaj osoby, które pomogły zmodyfikować funkcję. Nie umieszczaj tam dat, opisów zmian ani historii wersji.
- W `Return values` opisuj rzeczywiste wartości zwracane przy powodzeniu i niepowodzeniu. Jeśli funkcja rozróżnia te stany, stosuj `On Success - ...` oraz `On Failure - ... and sets @error ...`. Nie wymuszaj takiego podziału dla funkcji, które tylko zachowują otrzymane `@error` albo zwracają wartość logiczną bez ustawiania własnego stanu błędu.
- Kody `@error` dokumentuj w `Return values` danej funkcji, a nie w `Remarks` ani na wspólnej liście pod inną funkcją. Jeden kod może zajmować jeden wiersz; wiele kodów wypisz w osobnych wierszach wraz z ich znaczeniem. Uwzględniaj tylko kody, które funkcja rzeczywiście ustawia lub propaguje.
- Jeśli funkcja propaguje `@error` i `@extended` z innej funkcji, opisz to w `Return values` i wskaż źródło. Wyjaśnij `@extended`, jeśli niesie informację przydatną wywołującemu. Nie przypisuj kodom błędów funkcji pomocniczej znaczeń, których nie mają w funkcji publicznej.
- W `Remarks` opisuj zachowanie, ograniczenia i znaczenie stanów — na przykład to, czy przyjęcie polecenia przez COM potwierdza faktyczne wyświetlenie dokumentu. Nie przenoś tam list kodów `@error`.

Przykład dla funkcji z kilkoma kodami błędów:

```autoit
; Return values .: On Success - 1.
;                  On Failure - 0 and sets @error to one of the following:
;                    1 = Invalid input.
;                    2 = Unavailable GUI.
;                    3 = Operation failed.
;                  @extended contains the underlying error when available.
```
