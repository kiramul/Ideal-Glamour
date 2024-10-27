def pbAfterBattle(decision,canLose)
    $Trainer.party.each do |pkmn|
      pkmn.statusCount = 0 if pkmn.status == :POISON   # Bad poison becomes regular
      pkmn.makeUnmega
      pkmn.makeUnprimal
    end
    if $PokemonGlobal.partner
      $Trainer.heal_party
      $PokemonGlobal.partner[3].each do |pkmn|
        pkmn.heal
        pkmn.makeUnmega
        pkmn.makeUnprimal
      end
    end
    if decision==2 || decision==5   # if loss or draw
      if canLose
        $Trainer.party.each { |pkmn| pkmn.heal }
        (Graphics.frame_rate/4).times { Graphics.update }
      end
    end
    Events.onEndBattle.trigger(nil,decision,canLose)
    $game_player.straighten
  end
  
  Events.onEndBattle += proc { |_sender,e|
    decision = e[0]
    canLose  = e[1]
    if Settings::CHECK_EVOLUTION_AFTER_ALL_BATTLES || (decision!=2 && decision!=5)   # not a loss or a draw
      if $PokemonTemp.evolutionLevels
        pbEvolutionCheck($PokemonTemp.evolutionLevels)
        $PokemonTemp.evolutionLevels = nil
      end
    end
    case decision
    when 2, 5   # Lose, draw
      if !canLose
        $game_system.bgm_unpause
        $game_system.bgs_unpause

        echoln("Player's last tile: #{$PokemonTemp.lastTile}")

        if aidKitHasCharges? && $PokemonTemp.lastTile
            pbMessage(_INTL("\\w[]\\wm\\c[12]\\l[3]You quickly pull some medicine from your Aid Kit.\\wtnp[20]"))
            useAidKit
            lastTile = $PokemonTemp.lastTile
            transferPlayer(lastTile[1],lastTile[2],lastTile[3],lastTile[0])

            # Reset all events to original positions
            for event in $game_map.events.values
                event.move_to_original
            end
        else
            pbStartOver
        end
      end
    end
  }
  
  def pbEvolutionCheck(currentLevels)
    for i in 0...currentLevels.length
      pkmn = $Trainer.party[i]
      next if !pkmn || (pkmn.hp==0 && !Settings::CHECK_EVOLUTION_FOR_FAINTED_POKEMON)
      next if currentLevels[i] && pkmn.level==currentLevels[i]
      newSpecies = pkmn.check_evolution_on_level_up
      next if !newSpecies
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn,newSpecies)
      evo.pbEvolution
      evo.pbEndScreen
    end
end

Events.onMapChange += proc { |_sender, _e|
    $PokemonTemp.lastTile = nil
}

Events.onLeaveTile += proc { |_sender,e|
    # e[0] - Event that just left the tile.
    # e[1] - Map ID where the tile is located (not necessarily
    #        the current map). Use "$MapFactory.getMap(e[1])" to
    #        get the Game_Map object corresponding to that map.
    # e[2] - X-coordinate of the tile
    # e[3] - Y-coordinate of the tile
    next unless e[0] == $game_player
    $PokemonTemp.lastTile = [e[1],e[2],e[3],$game_player.direction]
    echoln("Player's last tile set to: #{$PokemonTemp.lastTile}")
}