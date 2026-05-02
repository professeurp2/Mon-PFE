# Documentation : Cinématique 5-axes (RTCP G43.4)

Cette documentation détaille l'implémentation de la cinématique inverse pour la machine CNC 5-axes Trunnion (Table-Table) du projet.

## 1. Topologie de la Machine

La machine est de type "Table-Table". Cela signifie que les deux axes rotatifs (A et C) sont situés sur la table, et non sur la broche.
- **Axe A** : Berceau de basculement (Rotation autour de X).
- **Axe C** : Plateau tournant (Rotation autour de Z').

## 2. Remote Tool Center Point (RTCP)

Le RTCP permet de commander la position de la pointe de l'outil ($X, Y, Z$) par rapport à la pièce, sans avoir à recalculer manuellement la trajectoire en fonction de la rotation des axes A et C. Le firmware effectue cette compensation en temps réel.

### Compensation de Longueur d'Outil ($L_z$) :
Lorsqu'on bascule l'axe A, la pointe de l'outil se déplace par rapport à la table. La compensation inclut la distance entre le centre de rotation A et le point outil.

## 3. Transformation Mathématique

Les coordonnées machine ($X_m, Y_m, Z_m$) sont calculées à partir des coordonnées pièce ($X_w, Y_w, Z_w$) par la transformation suivante :

$$
\begin{pmatrix} X_m \\ Y_m \\ Z_m \end{pmatrix} = [R_a] \cdot [R_c] \cdot \begin{pmatrix} X_w \\ Y_w \\ Z_w \end{pmatrix} + \begin{pmatrix} 0 \\ 0 \\ L_z \end{pmatrix}
$$

**Où :**
- $[R_c]$ est la matrice de rotation autour de Z (Plateau C).
- $[R_a]$ est la matrice de rotation autour de X (Berceau A).
- $L_z$ est la longueur de l'outil (Tool Length Offset).

## 4. Implémentation Logicielle

Le calcul est centralisé dans le `KinematicsService.h` du domaine :

```cpp
MachineCoords target;
target.x = x * cos(c) + y * sin(c);
target.y = -x * sin(c) * cos(a) + y * cos(c) * cos(a) + z * sin(a);
target.z = x * sin(c) * sin(a) - y * cos(c) * sin(a) + z * cos(a) + toolLen;
```

---
**Note :** Cette implémentation suppose que l'origine machine (X0, Y0, Z0) est alignée avec le point d'intersection des axes A et C.
