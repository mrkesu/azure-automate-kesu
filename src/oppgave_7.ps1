[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "URL for kortstokk")]
    [System.URI]$UrlKortstokk = "http://nav-deckofcards.herokuapp.com/shuffle"
)

# Leker meg litt med klasser for å lære hvordan de funker...
class Deck {
    [object]$cards

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
        return $out
    }

    # Samlet poengsum for kortene i kortstokk.
    # Knekt (J), Dronning (Q) og Konge (K) teller som 10 poeng, Ess (A) teller som 11 poeng, resten er vanlig
    [int] GetPoints() {
        [int]$i = 0
        try {
            foreach ($card in $this.cards) {
                $i += switch ($card.value) {
                    { $_ -in 'J', 'Q', 'K' } { 10 }
                    'A' { 11 }
                    Default { [int]::Parse($card.value) }
                }
            }
        }
        catch {
            Write-Error "Får ikke til å kalkulere poengsummen, hjelp!"
            Throw $_.Exception.Message
        }
        return $i
    }

    # Trekke kort fra toppen av kortstokken
    [void] GetCard([int]$amount, [Deck]$hand) {
        for ($i = 0; $i -lt $amount; $i++) {
            # Lagre øverste kort
            $topCard = $this.cards[0]
        
            # Lage ny kortstokk uten det øverste kortet
            $newDeck = @()
            foreach ($card in $this.cards) {
                if ($card -ne $topCard) {
                    $newDeck += $card
                }
            }
            # Lagre ny kortstokk og gi spiller det øverste kortet
            $this.cards = $newDeck
            $hand.cards += $topCard
        }
    }

    # Constructor med en ferdig stokket kortstokk
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

    # Constructor med en tom kortstokk
    Deck([object]$hand) {
        $this.cards = @()
    }
}

class Player {
    [string]$name                       # spillernavn
    [object]$hand = [Deck]::new($hand)  # spiller sine kort, en "tom kortstokk"
    [object]$deck                       # referanse til kortstokken som brukes

    Player($name, [Deck]$deck) {
        $this.name = $name
        $this.deck = $deck
        $this.deck.GetCard(2, $this.hand) # Nye spillere starter med 2 kort
    }

    # Spiller trekker et kort
    [void] DrawCard() {
        $this.deck.GetCard(1, $this.hand)
    }
    # Spiller trekker flere kort om gangen
    [void] DrawCard([int]$amount) {
        $this.deck.GetCard($amount, $this.hand)
    }

    [string]ToString() {
        return "$($this.name): $($this.hand)"
    }
}

class Blackjack {
    [System.Collections.ArrayList]$players = @()
    [object]$deck = [Deck]::new($UrlKortstokk)
    [int]$pointsGoal = 21

    [Player[]]Winner() {
        $winner = @()
        foreach ($player in $this.players) {
            if ($player.hand.GetPoints() -eq $this.pointsGoal) {
                $winner += $player
            }
        }
        return $winner
    }
}

# Starte spillet + lage kortstokk-variabelen de ønsker i oppgaven
$game = [Blackjack]::new()
$kortstokk = $game.deck

# Skrive ut kortstokk
Write-Host "Kortstokk: $kortstokk"
Write-Host "Poengsum: $($kortstokk.GetPoints())"
Write-Host ""

# Skape to spillere med referanse til kortstokken, og legge de til som spillere i blackjack
$meg = [Player]::new("meg", $kortstokk)
$magnus = [Player]::new("magnus", $kortstokk)
#$player3 = [Player]::new("spiller3", $kortstokk)

$game.players.Add($magnus) | Out-Null
$game.players.Add($meg) | Out-Null
#$game.players.Add($player3) | Out-Null

# En vinner funnet
if($game.Winner().Length -eq 1) {
    Write-Host "Vinner: $($game.Winner().name)"
}

# Flere vinnere funnet
if($game.Winner().Length -gt 1) {
    Write-Host "Vinner: Draw"
}

Write-Host "$($magnus.name)`t| $($magnus.hand.GetPoints()) | $($magnus.hand)"
Write-Host "$($meg.name)`t| $($meg.hand.GetPoints()) | $($meg.hand)"
#Write-Host "$($player3.name) | $($player3.hand.GetPoints()) | $($player3.hand)"