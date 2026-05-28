# Godot 4 2D Card Game Skeleton

## Recommended Node Structure

```text
MainMenu (Control) - scripts/main_menu.gd
  TitleLabel (Label)
  StartButton (Button)

BattleScene (Control) - scripts/battle_scene.gd
  Background (ColorRect)
  Player (Node) - scripts/player.gd
  Enemy (Node) - scripts/enemy.gd
  PlayerLabel (Label)
  EnergyLabel (Label)
  EnemyLabel (Label)
  PlayArea (ColorRect)
    PlayAreaLabel (Label)
  HandArea (Control)
  DeckManager (Node) - scripts/deck_manager.gd
  HandManager (Node) - scripts/hand_manager.gd
  TurnManager (Node) - scripts/turn_manager.gd
  DrawPileLabel (Label)
  DiscardPileLabel (Label)
  EndTurnButton (Button)
  GameOverOverlay (ColorRect)
    ResultLabel (Label)
    RestartButton (Button)

CardView (Control) - scripts/card_view.gd
  Panel (Panel)
  NameLabel (Label)
  CostLabel (Label)
  DescriptionLabel (Label)
```

## Implemented Gameplay

1. Click `Start Game` in `MainMenu` to enter `BattleScene`.
2. Player has health and energy. Enemy has health and attack damage.
3. First turn draws 5 cards. Later turns draw 1 card at turn start.
4. Cards display name, cost, and description.
5. Cards can be clicked to play, or dragged into `PlayArea`.
6. Attack cards damage the enemy.
7. Played cards go into the discard pile.
8. Clicking `End Turn` discards the remaining hand, then the enemy attacks the player.
9. Player death shows `Defeat`; enemy death shows `Victory`.

## Script Responsibilities

- `CardData`: card resource data: id, name, type, cost, description, and damage.
- `CardEffect`: one effect entry on a card, such as damage, block, draw, energy, burn, weak, or heal.
- `CardView`: card UI, click-to-play, drag-to-play, and display refresh.
- `DeckManager`: draw pile, discard pile, shuffle, draw, discard.
- `HandManager`: creates cards in hand, lays them out, and requests card play.
- `TurnManager`: turn number and draw count rules.
- `Player`: health, energy, damage, and death signal.
- `Enemy`: health, attack damage, damage intake, and death signal.
- `BattleScene`: connects systems, checks energy, resolves cards, and handles victory/defeat.
