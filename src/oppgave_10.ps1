[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "URL for kortstokk")]
    [System.URI]$UrlKortstokk = "http://nav-deckofcards.herokuapp.com/shuffle"
)

# Leker meg litt med klasser for å lære hvordan de funker...
class Deck {
    [array]$cards

    # Tom kortstokk (f.eks. en spiller sin starthand)
    Deck() {
        $this.cards = @()
    }

    # Kortstokk hentet fra URL
    Deck([System.URI]$URL) {
        try {
            $request = Invoke-WebRequest -Uri $URL
            $this.cards = $request.Content | ConvertFrom-Json
        }
        catch {
            Write-Error "Klarte ikke å hente kortstokk :("
            Throw $_.Exception.Message
        }
    }

    # Egendefinert ToString for å forenkle output av kortstokken
    [string]ToString() {
        $out = ""
        for ($i = 0; $i -lt $this.cards.Length; $i++) {
            $out += $this.cards[$i].suit[0] + $this.cards[$i].value

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
        $i = 0
        foreach ($card in $this.cards) {
            $i += switch ($card.value) {
                { $_ -in 'J', 'Q', 'K' } { 10 }
                'A' { 11 }
                Default { [int]::Parse($card.value) }
            }
        }
        return $i
    }

    # Trekke kort fra toppen av denne kortstokken og legge det til i en annen kortstokk
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
}

class Player {
    [string ]$name                  # spillernavn
    [Deck   ]$hand = [Deck]::new()  # spiller sine kort, en "tom kortstokk"
    [Deck   ]$deck                  # referanse til kortstokken som brukes
    [bool   ]$active = $true

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
    [Deck                        ]$deck = [Deck]::new($UrlKortstokk)
    [int                         ]$pointsGoal = 21

    # Add new player
    [Player]newPlayer([string]$name) {
        $new = [Player]::new($name, [Deck]$this.deck)
        $this.players.Add($new)
        return $new
    }
    
    [int]activePlayers() {
        return ($this.players | Where-Object {$_.active}).Length
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

# Skrive ut kortstokk
Write-Host "Kortstokk: $($game.deck)"
Write-Host "Poengsum: $($game.deck.GetPoints())"
Write-Host ""

# Opprette to nye spillere
$game.newPlayer("meg") | Out-Null
$game.newPlayer("magnus") | Out-Null
#$game.newPlayer("spiller3") | Out-Null

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
        
        # Hvis spiller har mindre poeng enn andre aktive spillere, fortsett å trekk
        while( ($game.players | Where-Object {$player -ne $_ -AND $_.active -AND $player.hand.GetPoints() -le $_.hand.GetPoints()}).Length -gt 0 ) {
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

# Skriver ut kortstokken igjen
Write-Host ""
Write-Host "Kortstokk: $($game.deck)"