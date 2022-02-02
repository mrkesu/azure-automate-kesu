# Leker meg litt med klasser for å lære hvordan de funker...
class Deck {
    [array]$cards

    # Lager en egen tostring for å løse oppgaven enkelt
    [string]ToString() {
        $out = ""
        for ($i = 0; $i -lt $this.cards.Length; $i++) {
            $out += $this.cards[$i].suit.Substring(0, 1) + $this.cards[$i].value

            # Legg til komma etter hver iterasjon, men ikke til slutt
            if ($i -lt ($this.cards.Length - 1)) {
                $out += ","
            }
        }

        return "Kortstokk: $out"
    }

    # Constructor, starter med en ferdig stokket kortstokk
    Deck() {
        $request = Invoke-WebRequest -Uri "http://nav-deckofcards.herokuapp.com/shuffle";
        $this.cards = $request.Content | ConvertFrom-Json
    }
}

$deck = [Deck]::new()

# ToString() automagi ╰(*°▽°*)╯
Write-Host $deck