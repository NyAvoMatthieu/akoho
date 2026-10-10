# `receptionaeroport` — le comptage d'arrivee

C'est le module qui remplace le couple bon de commande / bon de livraison dans
le domaine ferme. Il constate ce qui est **physiquement arrive**, en cartons,
par sexe et par qualite.

`arbiochem-ejb/src/java/ferme/receptionaeroport/`

## 1. Les 4 classes

| Classe | Heritage | Table | Cle | Vue |
| --- | --- | --- | --- | --- |
| `ReceptionPoussinAeroport` | `ClassMere` (l.11) | `receptionPoussinAeroport` (l.17) | `RPA` / `GETSEQRECEPTIONPOUSSINAEROPORT` (l.24) | `receptionPoussinAeroport_lib` |
| `ReceptionPoussinAeroportDetail` | `ClassFille` (l.10) | `receptionPoussinAeroportDetail` (l.15) | `RPAF` / `GETSEQRECEPTIONPOUSSINAEDETAIL` (l.22) | `receptionPoussinAEDetail_lib` |
| `ReceptionPoussinAeroportLib` | mere | vue | — | — |
| `ReceptionPoussinAeroportDetailLib` | fille | vue | — | — |

Casse notable : table et vues sont **en minuscules**, a la difference du reste
du domaine ferme. Toute requete doit reprendre la valeur exacte du
`setNomTable`.

Configuration de la mere (lignes 17-19) :

```java
super.setNomTable("receptionPoussinAeroport");
this.setNomClasseFille("ferme.receptionaeroport.ReceptionPoussinAeroportDetail");
this.setLiaisonFille("idMere");
```

## 2. Champs

### Mere (lignes 12-15)

| Champ | Type | Role |
| --- | --- | --- |
| `id` | `String` | cle `RPA` |
| `idLot` | `String` | **le lot** — seule liaison vers le reste du domaine |
| `remarque` | `String` | |
| `daty` | `Date` | date de reception |
| `heureDepart`, `heureArrive` | `String` | heures, en chaine |
| `qteRecus` | `double` | **quantite totale recue**, saisie a la main |
| `nbrCartonMale`, `nbrCartonFemelle` | `int` | nombre de cartons par sexe |
| `etat` | `int` | herite de `ClassEtat` |

### Fille (lignes 11-12)

| Champ | Type | Role |
| --- | --- | --- |
| `id`, `idMere` | `String` | cle et liaison |
| `idQualitePoussin` | `String` | `QUALITEPOUSSIN` |
| `idSexe` | `String` | `SEXE`, via `ConstanteFerme` |
| `qte` | `double` | **quantite par (sexe × qualite)** |

La decomposition est donc : `qteRecus` = somme des `qte` filles, chaque ligne
etant un croisement sexe × qualite.

## 3. Le seul controle metier : la coherence des quantites

`ReceptionPoussinAeroport.checkQteFille()` (lignes 133-141), appele par
`createObject` (lignes 128-131) avant toute ecriture :

```java
public void checkQteFille() throws Exception {
    ReceptionPoussinAeroportDetail[] fille = (ReceptionPoussinAeroportDetail[]) this.getFille();
    double qteFille = 0;
    for (ReceptionPoussinAeroportDetail f : fille) {
        qteFille += f.getQte();
    }
    if (this.getQteRecus() != qteFille)
        throw new Exception("La quantite totale en details : (" + qteFille
            + ") est differente de la quantite recue : (" + this.getQteRecus() + ")");
}
```

C'est le **seul** controle du module. Il est rejoue a l'insertion grace a la
surcharge de `createObject` ; `controlerUpdate` n'est pas surcharge, donc une
modification ulterieure peut rompre l'egalite.

Aucune verification que `idLot` existe, ni que le lot est valide, ni que les
cartons correspondent a un volume unitaire.

## 4. Les pages

| Page | Role |
| --- | --- |
| `receptionaeroport-liste.jsp` | colonnes `id, idLotLib, daty, heureDepart, heureArrive, qteRecus, nbrcartonmale, nbrcartonfemelle, nbrcartontotal, etatlib` (l.11) |
| `receptionaeroport-saisie.jsp` | `PageInsertMultiple`, grille fille `idQualitePoussin` / `idsexe` / `qte` (l.59) |
| `receptionaeroport-fiche.jsp` | consultation + onglet + 2 boutons |
| `inc/receptionaeroport-details.jsp` | detail, colonnes `idQualitePoussinLib, idSexelib, qte` (l.9) |

Les listes deroulantes de la grille fille (lignes 47-49) :

```java
listef[0] = new Liste("idSexe", sexe, "val", "id");
listef[1] = new Liste("idQualitePoussin", qp, "val", "id");
```

Champs de la grille renvoyes au dispatch (lignes 57, 90-95) :

```java
String colonneMere = "idMere";
<input name="classefille" type="hidden" value="<%= classeFille %>">
<input name="nombreLigne" type="hidden" id="nombreLigne" value="10">
```

## 5. Le chainage

C'est l'un des **deux seuls** chainages automatiques du domaine ferme. Il est
porte par un bouton, conditionne par l'etat :

`receptionaeroport-fiche.jsp:74-75`

```jsp
<% } else if(base.getEtat() >= ConstanteEtat.getEtatValider()) { %>
    <a class="btn btn-secondary pull-right"
       href="<%= lien%>?but=ferme/triagebatiment/triagebatimentparquet-saisie.jsp&idLot=<%=base.getIdLot()%>">
       Trier par batiment et par parquet</a>
```

Autrement dit : **tant que la reception n'est pas validee, le triage n'est pas
propose**. Et le triage ne recoit que `idLot` — il recalcule les disponibilites
depuis la base plutot que de reprendre la reception.

Le retour vers le lot se fait par un lien de colonne, pas par un bouton
(`receptionaeroport-fiche.jsp:32`) :

```java
pc.getChampByName("idLot").setLien(lien+"?but=ferme/lot/lot-fiche.jsp", "id=");
```

Tant que la reception est **modifiable** (ligne 70), les trois boutons sont
Valider / Modifier / Supprimer. Apres validation, le seul bouton restant est
le passage au triage.

## 6. Ce que ce module ne fait pas

- Il ne cree pas de lot.
- Il n'est relie a aucun bon de commande ni bon de livraison.
- Il ne distingue pas un lot d'import d'un lot issu du couvoir.
- Il ne verifie pas la coherence avec le programme zootechnique, qui existe
  pourtant comme onglet du lot.