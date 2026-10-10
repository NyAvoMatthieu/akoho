# Procédure de saisie — jeu d'essai du 30/09–01/10/2026

Document d'**exécution pas à pas** : quelles pages ouvrir, quels champs
remplir, quelles valeurs. Basé sur le code original uniquement.

Conventions de lecture : `maty` = **mort**, `very` = **perdu** (selon votre
précision).

---

## 0. Avertissement préalable : 4 points bloquants

À lire avant de commencer. Trois sont des défauts du code original, un est une
limite du modèle de données.

### 0.1 `parquet-saisie.jsp:19` est cassé — à corriger d'abord

```jsp
Parquet s = new Parquet();
s.setNomTable("PARQUEt");        // <-- faute de frappe
```

Le bean est instancié sur la table `PARQUEt` au lieu de `PARQUET`. Le
formulaire est construit à partir du nom de table du bean : **le formulaire
sera vide**, et l'insertion partira sur une table inexistante.

Sans correction, vous ne pouvez pas créer les parquets `c1` à `c4` par l'interface.

```diff
- s.setNomTable("PARQUEt");
+ s.setNomTable("PARQUET");
```

### 0.2 Les cases `max` et `qtt` de vos compartiments n'ont pas de champ

Votre tableau porte `max` (capacité) et `qtt` (effectif). Or
`batiment-saisie.jsp` **masque ces deux champs** :

```jsp
:40  affichage.Champ.setVisible(pi.getFormufle().getChampFille("capacite"), false);
:41  affichage.Champ.setVisible(pi.getFormufle().getChampFille("effectif"), false);
```

`max` et `qtt` ne sont donc **pas saisissables**. La procédure §4.2 donne les
deux contournements possibles. La quantité, elle, reste saisissable ailleurs
(§5, triage).

### 0.3 Le module de réception n'a aucun champ « mort » ni « perdu »

`ReceptionPoussinAeroport` ne connaît que `qteRecus` et des lignes
`(sexe, qualité, qte)`. Vos 500/500 et 700/300 n'y ont pas de case.

Ils sont reportés dans le suivi journalier (§6), via les seuls champs de perte
disponibles : `mortalite` et `culls`.

> `culls` ne veut pas dire « perdu » en zootechnie (c'est l'élimination
> d'animaux). C'est le champ le plus proche, mais la correspondance est
> approximative — à valider avec le métier.

### 0.4 La commande « poussin » n'entre pas dans la chaîne d'achat

`DmdAchatFille.idproduit` pointe sur `AS_INGREDIENTS_LIB` — des **ingrédients**
(aliment, produits de traitement), pas des animaux vivants. Le mot « poussin »
n'y a pas sa place.

Voir §2 pour les deux contournements.

---

## 1. Le résultat attendu

### 1.1 Calcul des pertes

| Étape | Effectif | maty (mort) | very (perdu) |
| --- | --- | --- | --- |
| Commande 30/09/2026 | 10 000 | — | — |
| Réception Ivato 01/10/2026 | 10 000 | −500 | −500 |
| → survivants Ivato | **9 000** | | |
| Réception M1 01/10/2026 | 9 000 | −700 | −300 |
| → **effectif présent** | **8 000** | | |

Pertes totales : **1 200 morts + 800 perdus = 2 000**. Contrôle :
10 000 − 2 000 = 8 000. ✓

### 1.2 Contrôle des compartiments

| Compartiment | `max` | Sexe | `qtt` | `etat` | Taux d'occupation | Marge |
| --- | --- | --- | --- | --- | --- | --- |
| c1 | 2 000 | m | 500 | sain | 25 % | 1 500 |
| c2 | 2 000 | f | 1 200 | marary | 60 % | 800 |
| c3 | 3 000 | f | 3 000 | sain | **100 %** | **0** |
| c4 | 4 000 | f | 3 300 | sain | 82,5 % | 700 |
| **Total** | **11 000** | | **8 000** | | 72,7 % | 3 000 |

Deux vérifications :

- Somme des `qtt` = 500 + 1 200 + 3 000 + 3 300 = **8 000** → égal à l'effectif
  présent. ✓ **Le jeu de données est cohérent.**
- Somme mâle + femelle = 500 + 7 500 = 8 000. ✓

⚠ **`c3` est plein à 100 %.** Toute entrée supplémentaire dans `c3` est à
refuser. Notez que rien dans le code ne l'empêche (§0.2).

### 1.3 Répartition mâle / femelle à la réception

Vos données ne précisent pas le sexage des 9 000 puis des 8 000. Or le module
de réception **impose** un croisement sexe × qualité.

La seule répartition compatible avec vos compartiments est :

| Lot | Total | Mâles | Femelles |
| --- | --- | --- | --- |
| Ivato | 9 000 | 500 | 8 500 |
| M1 | 8 000 | 500 | 7 500 |

Check : 8 500 − 7 500 = **1 000 femelles** perdues entre Ivato et M1. Or vos
pertes sur ce trajet sont 700 + 300 = 1 000. ✓ Cohérent **à condition que les
1 000 pertes du trajet soient toutes femelles**.

→ **À confirmer.** Si les pertes touchent aussi les mâles, dites-le : les
chiffres de §4 et §5 changent.

---

## 2. Étape A — La commande du 30/09/2026 (facultatif)

Cette étape **ne conditionne rien** : aucun code du domaine `ferme` ne lit un
bon de commande. Elle est purement documentaire.

### 2.1 Contournement recommandé — dans la référence du lot

Reporter l'information dans `Lot.reference` (champs §3, texte libre) :

```
reference = CMD-30-09-2026-POUS-10000
```

### 2.2 Si vous voulez une vraie trace d'achat

Page `facturefournisseur/dmdachat/dmdachat-saisie.jsp`

| Champ | Valeur |
| --- | --- |
| `fournisseur` | *(sélectionner le fournisseur des poussins)* |
| `daty` | `30/09/2026` |
| `dateLimite` | `01/10/2026` |
| `idMagasin` | `M1` |
| `idProvenance` | *(à définir)* |
| `idCategorie` | *(à définir)* |
| `service` | *(à définir)* |
| `remarque` | `Commande poussins 10000 PU 200 — lot fermé` |

Ligne fille :

| Champ | Valeur |
| --- | --- |
| `idproduit` | *(il faut un produit nommé « Poussin » dans `AS_INGREDIENTS`)* |
| `designation` | `Poussin` |
| `quantite` | `10000` |
| `pu` | `200` *(champ masqué — cf. ligne 73 du JSP)* |
| `tva` | `0` *(champ masqué — cf. ligne 74)* |

Montant attendu : 10 000 × 200 = **2 000 000** dans la devise du fournisseur.

**Prérequis bloquant :** le produit « Poussin » doit exister dans
`AS_INGREDIENTS`. Vérifiez avant. Sinon cette étape est à sauter.

---

## 3. Étape B — Le lot

Page : **`ferme/lot/lot-liste.jsp`** → bouton *Saisie d'un lot*
(`?but=ferme/lot/lot-saisie.jsp`)

Formulaire de type `PageInsert`.

| Champ | Valeur | Remarque |
| --- | --- | --- |
| `nomlot` | `POUS-2026-10-01` | obligatoire |
| `reference` | `CMD-30-09-2026-POUS-10000` | obligatoire, unique |
| `dateeclosion` | `01/10/2026` | obligatoire |
| `datearrivee` | `01/10/2026` | obligatoire, ≥ `dateeclosion` |
| `idferme` | `M1` | autocomplete sur `MAGASIN2` |
| `idarticle` | *(à définir)* | autocomplete `AS_INGREDIENTS` |
| `idorigine` | *(à définir)* | autocomplete `ORIGINELOT` |
| `idprogramme` | *(à définir)* | autocomplete `PROGRAMMEZOOTECHNIQUE` |
| `idCategorieLot` | *(à définir)* | |
| `source` | *(non saisissable)* | `readonly` ligne 31 |
| `idSouche` | *(non saisissable)* | `readonly` ligne 32 |
| `etat` | *(non saisissable)* | masqué ligne 33 |
| `dateCloture` | *(non saisissable)* | masqué ligne 34 |

### 3.1 Contrôles appliqués par le code

`Lot.createObject` (`Lot.java:101-107`) appelle deux contrôles :

- **`checkDates()`** (l.176) — `dateeclosion` et `datearrivee` obligatoires,
  et `dateeclosion <= datearrivee`.
- **`checkNomLotEtReference()`** (l.164) — `nomlot` et `reference`
  obligatoires, couple unique.

Si `dateeclosion` > `datearrivee`, message d'erreur à la création. Avec deux
dates identiques au 01/10/2026, pas de risque.

### 3.2 Rappel

**Un seul lot**, pas deux. La raison est expliquée au §4.1 — elle est
contre-intuitive mais nécessaire.

---

## 4. Étape C — Les référentiels

À faire **avant** la réception, sinon le formulaire n'offrira pas les listes
déroulantes.

### 4.0.a Nomenclatures à vérifier (aucune page n'est nécessaire)

Ces deux tables doivent déjà être peuplées. Vérifiez en base :

| Table | Condition | Origine |
| --- | --- | --- |
| `SEXE` | `id = 1` = Mâle, `id = 0` = Femelle | `ConstanteFerme.java:4-5` |
| `QUALITEPOUSSIN` | `QP000001` = conforme / sain | `ConstanteFerme.java:7` |
| `QUALITEPOUSSIN` | `QP000022` = mort | `ConstanteFerme.java:6` |

⚠ Ces identifiants sont **codés en dur** dans `ConstanteFerme`. S'ils ne
correspondent pas en base, les disponibilités du triage (§5) renverront 0.

### 4.0.b Créer la qualité « malade » (votre `etat` = marary)

Votre tableau utilise deux états : `sain` et `marary` (sic). Dans le modèle,
l'état d'un compartiment n'existe pas — c'est la **qualité** de la ligne de
triage (§5.4) qui porte cette information.

Il faut donc créer une qualité supplémentaire.

Page : **`ferme/configuration/qualitepoussin-liste.jsp`** → *Saisie*
(`?but=ferme/configuration/qualitepoussin-saisie.jsp`)

| Champ | Valeur |
| --- | --- |
| `val` | `malade` |
| `desce` | `Etat sanitaire malade (equivalent "marary")` |

**Notez l'identifiant généré** (format `QP......`) — il vous faut au §5.4.

> Si la qualité `malade` existe déjà, réutilisez-la. Ne créez pas de doublon.

### 4.0.c Créer le magasin M1

Page : **`magasin/magasin-liste.jsp`** → *Saisie*
(`?but=magasin/magasin-saisie.jsp`)

Classe `magasin.MagasinNormal`, table `magasin2`, clé `MAG` /
`GETSEQMAGASIN`.

| Champ | Valeur | Remarque |
| --- | --- | --- |
| `val` | `M1` | libellé |
| `desce` | `Magasin / site M1` | |
| `idTypeMagasin` | `TYPMG000002` | **obligatoire** — voir ci-dessous |
| `idPoint` | *(à définir)* | |
| `capacite` | `11000` | capacité totale des 4 compartiments |
| `idMagasinMere` | *(vide)* | |
| `idProduit` | *(vide)* | autocomplete `ST_INGREDIENTSAUTO` |

⚠ **`idTypeMagasin` est obligatoire malgré l'affichage.** `Magasin.controler`
appelle `controlerMagasin`, qui fait
`this.getIdTypeMagasin().compareToIgnoreCase(...)` — un champ vide provoque un
`NullPointerException`. Valeurs de `ConstanteStation.java` :

| Valeur | Libellé | Usage |
| --- | --- | --- |
| `TYPMG000002` | normal | valeur sûre |
| `TYPMG000023` | îlot | sémantiquement plus proche d'un bloc de compartiments |

Le champ n'est masqué que dans la branche « réservoir » (ligne 26). Dans la
branche normale il est visible.

### 4.1 Créer les 4 parquets — après le correctif §0.1

Page : **`ferme/configuration/parquet-liste.jsp`** → *Saisie*
(`?but=ferme/configuration/parquet-saisie.jsp`)

Classe `ferme.configuration.Parquet`, table `PARQUET`, clé `PRQ` /
`GETSEQPARQUET`. Le bean ne déclare **aucun champ** : tout vient des
métadonnées `listeColonneTable`. Les colonnes exposées par le JSP sont :

| Champ | Libellé dans le JSP |
| --- | --- |
| `val` | Nom du parquet |
| `desce` | Remarque |

Quatre créations, une par compartiment :

| # | `val` | `desce` |
| --- | --- | --- |
| 1 | `c1` | `Compartiment 1 — male — max 2000` |
| 2 | `c2` | `Compartiment 2 — female — max 2000` |
| 3 | `c3` | `Compartiment 3 — female — max 3000` |
| 4 | `c4` | `Compartiment 4 — female — max 4000` |

**Notez les 4 identifiants `PRQ......` générés** — nécessaires au §4.2 et §5.

> La classe `Parquet` n'expose que `val` et `desce`. Il n'existe **aucun**
> champ « capacité » ni « sexe » sur le parquet dans le code original : ces
> informations appartiennent à `BatimentDetail`, objet §4.2.

### 4.2 Créer le bâtiment et ses 4 lignes de compartiment

Page : **`ferme/configuration/batiment-liste.jsp`** → *Saisie d'un batiment*
(`?but=ferme/configuration/batiment-saisie.jsp`)

C'est le seul objet du projet qui porte à la fois **un lieu, un lot, un sexe et
un effectif** (`BatimentDetail.java:11-19`). C'est donc le seul endroit où vos
colonnes `c1..c4`, `max` et `qtt` trouvent une maison.

#### Champs de la mère (`BATIMENT`)

| Champ | Valeur | Remarque |
| --- | --- | --- |
| `idFerme` | `M1` | autocomplete sur `magasin.Magasin` / `MAGASIN2` (ligne 29) |
| `nomBatiment` | `M1` | |
| `Capacite` | `11000` | doit être ≥ somme des lignes |
| `densite` | `0` | ou la densité réelle |
| `longueur` | *(à définir)* | |
| `largeur` | *(à définir)* | |

#### Champs des 4 lignes filles (`BATIMENTDETAIL`)

Ligne 1 → compartiment `c1`, etc.

| Ligne | `idParquet` | `idSexe` | `surface` | `densite` | `capacite` | `effectif` | `idLot` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `PRQ(c1)` | **Mâle** | *(défin.)* | 0 | `2000` | `500` | `LOT(...)` |
| 2 | `PRQ(c2)` | **Femelle** | *(défin.)* | 0 | `2000` | `1200` | `LOT(...)` |
| 3 | `PRQ(c3)` | **Femelle** | *(défin.)* | 0 | `3000` | `3000` | `LOT(...)` |
| 4 | `PRQ(c4)` | **Femelle** | *(défin.)* | 0 | `4000` | `3300` | `LOT(...)` |

Les 6 lignes restantes de la grille (nombreLigne = 10) restent vides.

Votre `etat` (`sain` / `marary`) **n'a pas de champ ici** — il est porté par la
qualité au §5.4.

#### Les deux obstacles

**(a) `capacite` et `effectif` sont invisibles** (lignes 40-41 du JSP).

Contournement — l'un des deux :

| Option | Action | Inconvénient |
| --- | --- | --- |
| A | Commenter les lignes 40 et 41 | modifie le code original |
| B | Laisser les champs vides, et saisir `capacite`/`effectif` par SQL après création | la vérification de cohérence est contournée |

⚠ Si vous choisissez l'option B, **relisez `2000`, `2000`, `3000`, `4000` et
`500`, `1200`, `3000`, `3300` une seconde fois** : c'est de la saisie manuelle
en base, sans garde-fou.

**(b) `idLot` est invisible** (ligne 44).

Le champ est prévu mais masqué. Même tableau : soit vous décommentez la ligne
44, soit `idLot` reste nul et le lien compartiment ↔ lot n'est pas écrit dans
`BATIMENTDETAIL`. Le §5 écrit de toute façon ce lien dans
`TRIAGEBATIMENTPARQUETDETAIL`.

#### Contrôle appliqué

`Batiment.checkValeurEntierFille()` (`Batiment.java:133-146`, appelé ligne 129)
vérifie trois inégalités, aux lignes 143-145 :

```
Capacite (11000) ≥ Σ capacite filles (11000)   → OK, égalité
Densite        ≥ Σ densite filles               → OK si toutes à 0
Surface        ≥ Σ surface filles               → dépend de vos valeurs
```

⚠ **Avec `Capacite = 11000`, le contrôle passe exactement à l'égalité.** Si une
seule ligne fille dépasse sa capacité, la création est refusée — c'est le seul
garde-fou du projet sur ce point.

---

## 5. Étape D — Les deux réceptions

### 5.0 Pourquoi un seul lot pour deux réceptions

Point contre-intuitif, à comprendre avant de saisir.

Le champ `dispomale` / `dispofemelle` du triage est alimenté par la vue
`v_qte_dispo_lot_sexe_qualite`, qui est **cumulée par lot**. Avec un seul lot et
deux réceptions (9 000 + 8 000), la vue afficherait **17 000 disponibles** — un
montant faux.

Avec **deux lots**, chaque réception a sa propre disponibilité, et le total reste
juste.

Or le modèle **impose** deux chose que le second lot dérange :

1. `TriageBatimentParquetDetail` porte un seul `idlot` par ligne → chaque ligne
   de triage appartient à un seul lot.
2. `BatimentDetail` porte un seul `idSexe` par compartiment.

Les quatre lignes du triage ne peuvent donc pas provenir de deux lots distincts
**si** un même lot doit alimenter les quatre. Il faut donc **un seul lot**, et
une seule réception qui représente l'effectif réellement présent.

→ C'est ce que fait la procédure ci-dessous. Le lot A de 9 000 existe dans la
réalité, mais il est **absorbé** dans le lot : c'est le seul choix qui laisse
`dispomale` et `dispofemelle` exacts, et c'est la seule exigence que le module
impose.

### 5.1 Réception Ivato — 01/10/2026

Page d'entrée : **`ferme/lot/lot-fiche.jsp`** sur le lot du §3 → bouton
**« Réception à l'aéroport »** (ligne 94).

Ce bouton transmet `idLot`, qui arrive pré-rempli et `readonly` dans le
formulaire (`receptionaeroport-saisie.jsp:64-65`). **Passez toujours par la
fiche du lot**, jamais par l'URL directe — sinon `idLot` est vide.

Champs de la mère (`receptionPoussinAeroport`)

| Champ | Valeur | Remarque |
| --- | --- | --- |
| `idLot` | *(pré-rempli)* | readonly |
| `daty` | `01/10/2026` | |
| `heureDepart` | *(à définir)* | type `time` (ligne 28) |
| `heureArrive` | *(à définir)* | type `time` (ligne 30) |
| `nbrCartonMale` | *(à définir)* | ← **ce que vous n'avez pas** |
| `nbrCartonFemelle` | *(à définir)* | ← **ce que vous n'avez pas** |
| `qteRecus` | `9000` | ← **morts et perdus exclus** |
| `remarque` | `Ivato 01/10 - recus 10000 - maty 500 - very 500 - survivants 9000` | report des pertes |
| `etat` | *(non saisissable)* | masqué (ligne 31) |

Les 4 lignes filles (`idQualitePoussin`, `idSexe`, `qte`)

| Ligne | `idQualitePoussin` | `idSexe` | `qte` |
| --- | --- | --- | --- |
| 1 | `QP000001` (conforme) | Mâle | `500` |
| 2 | `QP000001` (conforme) | Femelle | `8500` |
| 3–10 | *(vides)* | | |

Puis **Viser** la réception.

#### Le contrôle qui va vous arrêter

`ReceptionPoussinAeroport.checkQteFille()` (`ReceptionPoussinAeroport.java:133-141`)
est appelé à chaque création :

```
si qteRecus ≠ Σ(qte des lignes filles)
    → "La quantite totale en details : (X) est differente de la quantite recue : (Y)"
```

**`qteRecus` doit valoir exactement 9 000.** Ni 10 000, ni 8 000.

### 5.2 Réception M1 — 01/10/2026

Même page, **nouvelle création** depuis `lot-fiche.jsp`.

| Champ | Valeur |
| --- | --- |
| `idLot` | *(pré-rempli, même lot)* |
| `daty` | `01/10/2026` |
| `qteRecus` | `8000` |
| `remarque` | `M1 01/10 - recus 9000 - maty 700 - very 300 - presents 8000` |

Lignes filles

| Ligne | `idQualitePoussin` | `idSexe` | `qte` |
| --- | --- | --- | --- |
| 1 | `QP000001` | Mâle | `500` |
| 2 | `QP000001` | Femelle | `7500` |

Puis **Viser**.

### 5.3 Le problème de cumul — vérification obligatoire

⚠ **Si les deux réceptions partagent le même lot, `v_qte_dispo_lot_sexe_qualite`
retournera 9 000 + 8 000 = 17 000.** Le champ `dispofemelle` du triage
affichera donc 17 500, pas 7 500.

Vérifiez avant d'aller plus loin. Ouvrez la saisie du triage et lisez les
deux champs en lecture seule :

| Champ | Attendu | Si vous lisez autre chose |
| --- | --- | --- |
| `dispomale` | `500` | 1 000 → cumul actif |
| `dispofemelle` | `7 500` | 17 500 → cumul actif |

**Si le cumul est actif**, vous avez trois sorties, par ordre de préférence :

| Option | Action | Effet |
| --- | --- | --- |
| A | Ne créer **qu'une** réception, celle du §5.2 (`qteRecus = 8000`), et consigner l'étape Ivato dans `remarque` | disponibilités justes, mais le détail 9 000/1 000 n'est plus structuré |
| B | Vérifier la définition de la vue et voir si elle déduit le triage déjà saisi | à confirmer en base |
| C | Supprimer la réception Ivato après coup | non recommandé : perte de la trace |

**Option A recommandée** si le cumul se confirme.

### 5.4 Triage par bâtiment et par parquet

Depuis `receptionaeroport-fiche.jsp`, le bouton **« Trier par batiment et par
parquet »** n'apparaît que si la réception est **validée** (ligne 74-75).
Le lien transmet `idLot`.

Champs de la mère (`TRIAGEBATIMENTPARQUET`)

| Champ | Valeur | Remarque |
| --- | --- | --- |
| `idlot` | *(pré-rempli)* | readonly |
| `daty` | `01/10/2026` | |
| `dispomale` | *(calculé)* | **lecture seule** |
| `dispofemelle` | *(calculé)* | **lecture seule** |
| `etat` | *(non saisissable)* | masqué (ligne 37) |

Les 4 lignes filles — **c'est votre tableau `compartiment`**

| Ligne | `idbatiment` | `idparquet` | `idsexe` | `idqualite` | `qte` |
| --- | --- | --- | --- | --- | --- |
| 1 | `M1` | `PRQ(c1)` | Mâle | `QP000001` *(sain)* | `500` |
| 2 | `M1` | `PRQ(c2)` | Femelle | **`QP(malade)`** | `1200` |
| 3 | `M1` | `PRQ(c3)` | Femelle | `QP000001` *(sain)* | `3000` |
| 4 | `M1` | `PRQ(c4)` | Femelle | `QP000001` *(sain)* | `3300` |

Total = **8 000**. ✓

Le `idqualite` de la ligne 2 porte votre `etat = marary`. **Les trois autres
lignes portent `sain`, matérialisé par `QP000001`.**

#### `idparquet` : la liste dépend de `idbatiment`

```jsp
:59  liste[1] = new Liste("idbatiment", new Batiment(), "nomBatiment", "id");
:60  liste[1].setDeroulanteDependante(liste[2], "idbatiment", "onchange");
:58  liste[2] = new Liste("idparquet", new ParquetBatiment(), "val", "id");
```

Choisir d'abord le bâtiment, puis le parquet. `ParquetBatiment` lit
`PARQUET_BATIMENT_LIB` — si vos parquets n'apparaissent pas, c'est que le
lien bâtiment ↔ parquet n'est pas établi : il l'est par le `idParquet` des
lignes filles `BatimentDetail` du §4.2.

#### Le contrôle qui **ne** vous arrêtera **pas**

`TriageBatimentParquet.createObject` (`TriageBatimentParquet.java:92-123`) a
son corps **entièrement commenté** (lignes 93-121). Le code qui vérifiait
`Σ(qte) = dispomale` et `Σ(qte) = dispofemelle` ne s'exécute pas.

Conséquence : **rien ne vous empêche de saisir 9 000 au lieu de 8 000**, ni de
dépasser la capacité de `c3` (qui est déjà à 100 %). Le seul contrôle exercé
ici est « le parquet existe et le lot existe » — rien d'autre.

Relevez les totaux à la main : `500 + 1200 + 3000 + 3300 = 8000`.

---

## 6. Étape E — Enregistrer les pertes

C'est ici que `maty` et `very` trouvent enfin un champ (§0.3).

Page : **`ferme/suiviJournalier/suivijournalier-liste.jsp`** → *Saisie*
(`?but=ferme/suiviJournalier/suivijournalier-saisie.jsp`)

Champs de la mère (`SUIVIJOURNALIER`)

| Champ | Valeur |
| --- | --- |
| `daty` | `01/10/2026` |
| `idferme` | `M1` — liste `Magasin` / `magasin2` (ligne 33) |
| `idlot` | *(le lot du §3)* |
| `etat` | *(non saisissable)* |

**Comportement de `idferme`** : il porte
`onchange="updateFille(event,'formId')"` (ligne 37). Choisir M1 **recharge la
grille** avec `AND idferme='<M1>'` sur la liste des bâtiments (lignes 45-51,
57). Choisissez-le en premier.

Champs des lignes filles

| Ligne | `idbatiment` | `idparquet` | `agejour` | `entree` | `tri` | `mortalite` | `culls` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 → c1 | `M1` | `PRQ(c1)` | `0` | `500` | `0` | `75` | `50` |
| 2 → c2 | `M1` | `PRQ(c2)` | `0` | `1200` | `0` | `180` | `120` |
| 3 → c3 | `M1` | `PRQ(c3)` | `0` | `3000` | `0` | `450` | `300` |
| 4 → c4 | `M1` | `PRQ(c4)` | `0` | `3300` | `0` | `495` | `330` |
| **Total** | | | | **8 000** | **0** | **1 200** | **800** |

`mortalite` ← `maty` : 500 (Ivato) + 700 (M1) = **1 200**
`culls` ← `very` : 500 (Ivato) + 300 (M1) = **800**

### 6.1 D'où viennent les 75 / 180 / 450 / 495

Vous n'avez pas donné la répartition des pertes par compartiment. Le tableau
ci-dessus applique un **prorata sur l'effectif** :

```
part d'un compartiment = effectif / 8000

mortalite : 500 × 0,15 = 75    culls : 500 × 0,10 = 50
            1200 × 0,15 = 180              1200 × 0,10 = 120
            3000 × 0,15 = 450              3000 × 0,10 = 300
            3300 × 0,15 = 495              3300 × 0,10 = 330
```

Totaux : 1 200 et 800. ✓

⚠ **C'est une convention, pas une donnée.** Les pertes de transport ont eu
lieu avant l'entrée en compartiment : les attribuer au prorata est un
compromis. Si vous savez la répartition réelle, remplacez ces 8 valeurs — les
totaux des lignes 1 à 4 sont vos seules contraintes.

### 6.2 La reserve sur le sens de `culls`

`maty` = mort → `mortalite` : **juste**.

`very` = perdu → `culls` : **approximatif**. `culls` désigne l'élimination
d'animaux (reforme, abattage), pas la disparition en cours de transport. Le
projet n'a pas de champ « pertes en transit ». Si cette distinction compte,
elle doit être portée dans `remarque`, ou le modèle doit évoluer.

Aucun contrôle de cohérence n'est exercé sur ce module : `SuiviJournalier`
n'a pas de méthode `controler`. Rien ne vérifie que `entree − mortalite −
culls` reste positif.

---

## 7. Récapitulatif — l'ordre exact

| # | Page | Action | Conditionne |
| --- | --- | --- | --- |
| 0 | `configuration/parquet-saisie.jsp:19` | **corriger** `PARQUEt` → `PARQUET` | §4.1 |
| 1 | *base* | vérifier `SEXE` et `QUALITEPOUSSIN` | §4.0.a |
| 2 | `configuration/qualitepoussin-saisie.jsp` | créer qualité `malade` → noter l'id | §5.4 |
| 3 | `magasin/magasin-saisie.jsp` | créer `M1`, `idTypeMagasin = TYPMG000002` | §4.0.c |
| 4 | `configuration/parquet-saisie.jsp` ×4 | créer `c1`, `c2`, `c3`, `c4` → noter les `PRQ` | §4.2, §5.4 |
| 5 | `lot/lot-saisie.jsp` | créer le lot `POUS-2026-10-01` | tout |
| 6 | `configuration/batiment-saisie.jsp` | bâtiment `M1` + 4 lignes `BatimentDetail` | §5.4 |
| 7 | `lot/lot-fiche.jsp` → *Réception à l'aéroport* | réception Ivato, `qteRecus = 9000` | §5.1 |
| 8 | idem | **Viser** | §5.4 |
| 9 | idem | réception M1, `qteRecus = 8000` | §5.2 |
| 10 | idem | **Viser**, puis vérifier `dispomale` / `dispofemelle` | §5.3 |
| 11 | *bouton* *Trier par batiment et par parquet* | 4 lignes de triage (§5.4) | §6 |
| 12 | `suiviJournalier/suivijournalier-saisie.jsp` | pertes `mortalite` + `culls` | fin |

---

## 8. Vérifications finales

### 8.1 Les contrôles que le code exert

| Contrôle | Où | Votre saisie doit satisfy |
| --- | --- | --- |
| Somme lignes filles = total réception | `ReceptionPoussinAeroport.java:133-141` | 9000 puis 8000 |
| `dateeclosion ≤ datearrivee` | `Lot.java:176` | 01/10 = 01/10 |
| `nomlot` + `reference` uniques | `Lot.java:164` | — |
| Σ `capacite` filles ≤ `Capacite` mère | `Batiment.java:143` | 11 000 = 11 000 |
| Devise unique sur la commande | `As_BonDeCommande.java:223` | §2.2 |

### 8.2 Les contrôles qui n'existent pas

| Ce qui n'est pas vérifié | Conséquence |
| --- | --- |
| Équilibre du triage (`Σqte = dispo`) | code commenté, `TriageBatimentParquet.java:93-121` |
| Capacité d'un parquet | `c3` peut être dépassé sans erreur |
| Cohérence des sexes dans une réception | 500 mâles + 8 500 femelles, ou l'inverse, passe |
| Duplication de reception pour un lot | 17 000 disponibles, sans alerte |
| `Σ(qte) ≤ qteRecus` en modification | `controlerUpdate` n'est jamais surchargé |
| Effectif d'un compartiment | `effectif` est masqué, jamais alimenté |

### 8.3 Contrôles arithmétiques à faire à la main

| Contrôle | Attendu |
| --- | --- |
| Commande | 10 000 |
| − pertes Ivato (500 + 500) | 9 000 |
| − pertes M1 (700 + 300) | **8 000** |
| Σ `qtt` des 4 compartiments | **8 000** |
| Σ mâles | 500 |
| Σ femelles | 7 500 |
| Σ `max` | 11 000 (capacité totale) |
| Σ `mortalite` | 1 200 |
| Σ `culls` | 800 |
| 1 200 + 800 | 2 000 = 10 000 − 8 000 |

---

## 9. Ce que cette procédure ne fait pas

| Élément de votre demande | Où il est réellement |
| --- | --- |
| La commande comme source du lot | aucun lien — `reference` du lot seulement (§2.1) |
| La mort et le perte à la réception | pas de champ — reportés au suivi journalier (§6) |
| La réception Ivato comme étape distincte | absorbée dans la réception M1 (§5.3) |
| `max` par compartiment | `BatimentDetail.capacite`, masqué à l'écran (§4.2) |
| `qtt` par compartiment | `BatimentDetail.effectif`, masqué — et `TriageBatimentParquetDetail.qte`, visible (§5.4) |
| `etat` par compartiment | `TriageBatimentParquetDetail.idqualite` — une qualité, pas un statut (§5.4) |
| Le « compartiment » comme objet | n'existe pas : c'est un `Parquet` + une ligne `BatimentDetail` |

---

## 10. Les quatre décisions qui vous reviennent

1. **Corriger `parquet-saisie.jsp:19`** — ou saisir les 4 parquets en SQL.
2. **Rendre `capacite` et `effectif` visibles** dans `batiment-saisie.jsp`
   (lignes 40-41) — ou les saisir en SQL.
3. **Trancher le sort de la réception Ivato** si le cumul se confirme (§5.3).
4. **Confirmer que les 1 000 pertes du trajet sont toutes femelles** (§1.3) —
   sinon la répartition mâle/femelle des réceptions change.

Et deux validations métier :

5. **`very` → `culls`** est un rapprochement, pas une équivalence.
6. **Le prorata des pertes du §6.1** est une convention à remplacer par vos
   chiffres réels si vous les avez.