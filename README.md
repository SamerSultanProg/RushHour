# Rush Hour - Jeu de Puzzle (Samer Sultan)

## Concept du Projet

Rush Hour est une adaptation numérique du célèbre jeu de puzzle logique du même nom. L'objectif est simple : libérer la voiture rouge (R) en la faisant sortir par la droite du plateau de jeu 6x6. Pour y parvenir, le joueur doit déplacer les autres véhicules qui bloquent le chemin, sachant que chaque véhicule ne peut se déplacer que dans une seule direction (horizontalement ou verticalement selon son orientation).

### Objectifs du Jeu
- **But principal** : Faire sortir la voiture rouge par la sortie située à droite du plateau
- **Système de médailles** : Obtenir la meilleure médaille possible selon le nombre de mouvements
  - 🥇 **Or** : Résoudre en un nombre optimal de coups (ou moins)
  - 🥈 **Argent** : Jusqu'à 5 coups au-dessus de l'optimal
  - 🥉 **Bronze** : Plus de 5 coups au-dessus de l'optimal
- **10 niveaux prédéfinis** de difficulté croissante
- **Mode aléatoire** : Génération procédurale de niveaux infinis

### Contrôles
- **Souris** : Glisser-déposer les véhicules
- **F12** : Afficher/masquer les statistiques (FPS/RAM)
- **M** : Activer/désactiver le son
- **Échap** : Menu pause

---

## Points Saillants du Développement

### 1. Algorithme BFS (Breadth-First Search) - Solveur et Système d'Indices

**Emplacement dans le projet** : `scripts/Solver.gd` (lignes 1-270)

**Application** : Fonction `solve()` pour résoudre les puzzles et `get_hint()` pour le système d'indices en jeu

#### Explication de l'algorithme

Le BFS (recherche en largeur) est un algorithme de parcours de graphe qui explore tous les nœuds d'un niveau avant de passer au niveau suivant. Dans le contexte de Rush Hour, chaque **état du plateau** représente un nœud, et chaque **mouvement possible** représente une arête vers un nouvel état.

```
État initial → [Tous les mouvements possibles] → États niveau 1
                                                      ↓
                                              [Tous les mouvements]
                                                      ↓
                                              États niveau 2...
```

**Fonctionnement détaillé :**

1. **Représentation de l'état** : Chaque configuration du plateau est encodée via la classe `BoardState` qui contient un tableau de `CarState` (position x, y, longueur, direction de chaque véhicule).

2. **Génération des états suivants** : La méthode `get_next_states()` génère tous les mouvements valides pour chaque véhicule en vérifiant les collisions avec la grille d'occupation.

3. **Détection des doublons** : Un dictionnaire `visited` stocke un hash unique de chaque état visité pour éviter les cycles et la redondance.

4. **Reconstruction du chemin** : Une fois l'état gagnant trouvé (voiture R à la position x=4), on remonte la chaîne des parents pour reconstruire la solution optimale.

**Avantage du BFS** : Garantit de trouver la solution la plus courte (optimale) car il explore les états par ordre de profondeur croissante.

Le système d'indices (`get_hint()`) utilise ce même algorithme mais à partir de l'état actuel du jeu, permettant au joueur de recevoir le prochain mouvement optimal à tout moment.

---

### 2. Algorithme de Génération Procédurale de Niveaux

**Emplacement dans le projet** : `scripts/Solver.gd` (lignes 275-476)

**Application** : Fonction `generate_level()` appelée depuis `scripts/LevelSelect.gd` lors du clic sur "Niveau Aléatoire"

#### Explication de l'algorithme

La génération procédurale crée des puzzles Rush Hour valides et solvables de manière aléatoire. L'algorithme suit une approche de **placement contraint avec validation**.

**Étapes de l'algorithme :**

1. **Placement de la voiture rouge** : La voiture R est placée sur la ligne de sortie (y=2) à une position aléatoire qui n'est pas déjà à la sortie (x entre 0 et 3).

2. **Placement des véhicules bloquants** :
   - Sélection aléatoire de la longueur (2 ou 3 cases, avec biais vers 2)
   - Sélection aléatoire de l'orientation (horizontale ou verticale)
   - Recherche d'une position valide via `_find_valid_position()` qui :
     - Parcourt toutes les positions possibles de la grille
     - Vérifie qu'aucune cellule n'est déjà occupée
     - Retourne une position aléatoire parmi les valides
   - Utilisation d'IDs de véhicules correspondant aux sprites disponibles (A-G pour longueur 2, A-D pour longueur 3)

3. **Validation de solvabilité** :
   - Le niveau généré est soumis à l'algorithme BFS
   - Si aucune solution n'existe ou si la solution est trop courte (< `min_moves`), le niveau est rejeté
   - Le processus recommence jusqu'à obtenir un niveau valide

4. **Gestion des échecs** : Après 100 tentatives infructueuses, un puzzle de secours prédéfini est retourné.

```
Boucle principale:
    ├── Placer voiture R
    ├── Pour chaque véhicule à placer:
    │   ├── Choisir longueur aléatoire
    │   ├── Choisir orientation aléatoire  
    │   ├── Trouver position valide
    │   └── Marquer cellules occupées
    ├── Vérifier solvabilité (BFS)
    └── Si solution.taille >= min_moves → SUCCÈS
        Sinon → Recommencer
```

**Paramètres configurables** :
- `min_moves` : Difficulté minimale (nombre de coups optimal)
- `max_cars` : Nombre maximum de véhicules bloquants

---

## Sources et Références

- **Concept original** : Rush Hour par ThinkFun (Nob Yoshigahara, 1996)
- **Moteur de jeu** : [Godot Engine 4.5](https://godotengine.org/)
- **Algorithme BFS** : [Breadth First Search for Rush Hour](https://github.com/takoshiobi/rush-hour-bfs)
- **Génération procédurale** : [Procedural Generation of Rush Hour Levels](https://www.lamsade.dauphine.fr/~cazenave/papers/RushHour.pdf)

---

## Structure du Projet

```
RushHour/
├── scripts/
│   ├── Solver.gd        # Algorithmes BFS et génération procédurale
│   ├── Main.gd          # Logique principale du jeu
│   ├── Levels.gd        # Gestion des niveaux et médailles
│   ├── LevelSelect.gd   # Sélection de niveau et mode aléatoire
│   └── ...
├── scenes/              # Scènes Godot (.tscn)
├── assets/              # Ressources graphiques et audio
└── README.md            # Ce document
```

---

*Projet réalisé dans le cadre d'un cours de programmation de jeux vidéos - Décembre 2025*
