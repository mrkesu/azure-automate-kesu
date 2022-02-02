[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage = "URL for kortstokk")]
    [System.URI]$UrlKortstokk = "http://nav-deckofcards.herokuapp.com/shuffle"
)

# Leker meg litt med klasser for å lære hvordan de funker...
class Deck {
    [array]$cards

    # Lager en egen tostring for å løse oppgaven enkelt
    [string]ToString(){
        $out = ""
        for ($i = 0; $i -lt $this.cards.Length; $i++) {
            $out += $this.cards[$i].suit.Substring(0, 1) + $this.cards[$i].value

            # Legg til komma etter hver iterasjon, men ikke til slutt
            if($i -lt ($this.cards.Length - 1)) {
                $out += ","
            }
        }

        return "Kortstokk: $out"
    }

    # Constructor, starter med en ferdig stokket kortstokk
    Deck([System.URI]$URL) {
        #$request = Invoke-WebRequest -Uri "http://nav-deckofcards.herokuapp.com/shuffle";
        try {
            $request = Invoke-WebRequest -Uri $URL
            $this.cards = $request.Content | ConvertFrom-Json
        }
        catch {
            Write-Error "Klarte ikke å hente kortstokk :("
            Throw $_.Exception.Message
        }
    }
}

$deck = [Deck]::new($UrlKortstokk)

# ToString() automagi ╰(*°▽°*)╯
Write-Host $deck