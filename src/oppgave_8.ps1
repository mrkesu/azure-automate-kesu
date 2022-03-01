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
    [int]GetPoints() {
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
    [void]GetCard([int]$amount, [Deck]$hand) {
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
    [bool]$active = $true

    Player($name, [Deck]$deck) {
        $this.name = $name
        $this.deck = $deck
        $this.deck.GetCard(2, $this.hand) # Nye spillere starter med 2 kort
    }

    # Spiller trekker et kort
    [void]DrawCard() {
        $this.deck.GetCard(1, $this.hand)
    }
    # Spiller trekker flere kort om gangen
    [void]DrawCard([int]$amount) {
        $this.deck.GetCard($amount, $this.hand)
    }

    [string]ToString() {
        return "$($this.name): $($this.hand)"
    }
}

class Blackjack {
    [System.Collections.ArrayList]$players = @()
    [Deck]$deck = [Deck]::new($UrlKortstokk)
    [int]$pointsGoal = 21

    # Add new player
    [Player]newPlayer([string]$name) {
        $new = [Player]::new($name, [Deck]$this.deck)
        $this.players.Add($new)
        return $new
    }
    
    [Player[]]Winner() {
        $winner = @()
        # If there's only 1 active player, then he's the winner by default.
        if( ($this.players | Where-Object {$_.active}).Length -eq 1 ) {
            return $this.players | Where-Object {$_.active}
        }

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

# Skape to nye spillere i blackjack med referanse til kortstokken
$game.newPlayer("meg") | Out-Null
$game.newPlayer("magnus") | Out-Null
#$player3 = $game.newPlayer("spiller3")

# En vinner funnet
if($game.Winner().Length -eq 1) {
    Write-Host "Vinner: $($game.Winner().name)"
}
# Flere vinnere funnet
elseif($game.Winner().Length -gt 1) {
    Write-Host "Vinner: Draw"
}
# Ingen vinner funnet: sudden death :)
elseif($game.Winner().Length -eq 0) {
    foreach($player in $game.players) {
        # Hvis alle de andre spillerne er inaktiv (bust) så er dette siste mann og
        # vinner automatisk. ingen vits å trekke flere kort.
        if( ($game.players | Where-Object {$player -ne $_ -AND $_.active}).Length -eq 0 ) {
            break
        }

        while($player.hand.GetPoints() -lt 17) {
            $player.DrawCard()
            if($player.hand.GetPoints() -gt 21) { $player.active = $false } # Player is bust, set as inactive
        }
    }
    Write-Host "Vinner: $($game.Winner().name)"
}

# Spillerinfo, i alfabetisk rekkefølge etter navn
foreach($player in ($game.players | Sort-Object -Property name)) {
    Write-Host "$($player.name)`t| $($player.hand.GetPoints()) | $($player.hand)"
}