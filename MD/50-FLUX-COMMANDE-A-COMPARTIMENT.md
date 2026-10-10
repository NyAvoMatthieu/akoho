# Le flux reel, de l'achat a la mise en parquet

## 1. Reponse directe a la question posee

> « bon de commande a la mise en compartiment, gerez vous tous ces flux la ? »

**Le projet gere tout le domaine elevage, du lot au suivi en batiment/parquet.**
En revanche :

- **Non**, il n'existe pas de flux « bon de commande → mise en compartiment ».
  Les deux chaines sont orthogonales. La commande d'achat ne cree pas de lot,
  et le lot ne reference aucune commande.
- **Non**, il n'existe pas de concept « compartiment » ni de « poulailler »
  dans le code original. Le rangement physique existe, mais il s'appelle
  `idbatiment` + `idparquet` + `idsexe` + `idqualite`, et il est realise par
  `TriageBatimentParquetDetail`.
- **Non**, il n'existe qu'**un seul** point de comptage : l'arrivee a
  l'aeroport. Le poulailler n'est pas un deuxieme point de comptage, c'est
  lArduino du comptage d'arrivee.

Ce qui existe reellement, c'est une chaine zootechique de bout en bout avec une
**ligne de rupture entre l'achat et l'elevage**. Cette ligne est le lot, qui se
saisit a la main.

## 2. Le flux, etape par etape

### Etape 0 — Creation du lot (manuelle, hors chaine d'achat)

`ferme/lot/lot-fiche.jsp:94` propose « Reception a l'aeroport » ; il faut donc
d'abord un lot. Il se cree a la main dans `lot/lot-saisie.jsp`.

`Lot` (`arbiochem-ejb/src/java/ferme/lot/Lot.java`) porte :

| Cle | Table | Sequence |
| --- | --- | --- |
| `LOT` | `LOT` | `getseq_lot` (l.130) |

Controles a la creation (`Lot.java:101-107`) :

- `checkDates()` (l.176) — eclosion et arrivee obligatoires, `eclosion <= arrivee`.
- `checkNomLotEtReference()` (l.164) — nom et reference obligatoires, uniques.

### Etape 1 — Reception a l'aeroport (comptage d'arrivee)

`receptionaeroport-liste.jsp` → `-saisie.jsp` (`PageInsertMultiple`, 10 lignes).

Une reception = 1 mere + N filles. Chaque fille est un croisement
**sexe × qualite**, avec une quantite. La mere porte le total `qteRecus` et le
nombre de cartons par sexe.

Le seul controle metier du module (`ReceptionPoussinAeroport.checkQteFille()`,
l.133-141) :

```java
if (this.getQteRecus() != qteFille)
    throw new Exception("La quantite totale en details : (" + qteFille
        + ") est differente de la quantite recue : (" + this.getQteRecus() + ")");
```

### Etape 2 — Validation de la reception

Le bouton « Viser » (`receptionaeroport-fiche.jsp:89`) fait passer l'etat a 11
via `ConstanteEtat.getEtatValider()`.

### Etape 3 — Triage par batiment et par parquet (le rangement)

C'est le point de departure du triage, conditionne par l'etat
(`receptionaeroport-fiche.jsp:74-75`) :

```jsp
<% } else if(base.getEtat() >= ConstanteEtat.getEtatValider()) { %>
    <a class="btn btn-secondary pull-right"
       href="<%= lien%>?but=ferme/triagebatiment/triagebatimentparquet-saisie.jsp&idLot=<%=base.getIdLot()%>">
       Trier par batiment et par parquet</a>
```

Le triage recoit `idLot` et **recalcule** les disponibilites depuis la base,
sans rien reprendre de la reception.

`triagebatimentparquet-saisie.jsp:44-53` pre-remplit en lecture seule :

```java
double femelleDispo = mere.getDisponnibleLib(idLot, ConstanteFerme.IDSEXEFEMELLE, ConstanteFerme.qualiteConforme, null);
double maleDispo    = mere.getDisponnibleLib(idLot, ConstanteFerme.IDSEXEMALE,    ConstanteFerme.qualiteConforme, null);
pi.getFormu().getChamp("dispomale").setAutre("readonly");
```

Ces valeurs viennent de la vue **`v_qte_dispo_lot_sexe_qualite`**, lue par
`TriageLotSexeQualite` (`TriageBatimentParquet.java:150-173`). C'est le seul
point du systeme ou un calcul serveur alimente un formulaire.

La grille comporte 10 lignes, chacune un triplet :
`(idbatiment, idparquet, idsexe, idqualite, qte)`.

### Etape 4 — Validation du triage

**Le controle d'equilibre est commente** dans
`TriageBatimentParquet.java:93-121` : le code verifiait que la somme des `qte`
filles egale les quantites disponibles, et leve `throw` si non. Il ne s'execute
pas. `createObject` retombe directement sur `super.createObject(u, c)`.

Consequence : on peut ranger plus que disponible, ou moins, sans erreur.

### Etape 5 — Suivi

Aucun bouton ne relie le triage au suivi. Les sept modules d'elevage
(`SuiviJournalier`, `Vaccination`, `TransfertPoulet`, `Pesee`,
`DistributionAliment`, `BatimentVideSanitaire`, `Fumigation`) sont des
triplets independants, atteignables par le menu dynamique ou par URL directe.

Le seul point de convergence est la fiche du lot, dont les trois onglets sont
(`lot-fiche.jsp:106-108`) :

| Onglet | Page | Contenu |
| --- | --- | --- |
| Programme zootechnique | `programme/inc/programmezoodet` | attendu theorique par age et sexe |
| Effectifs | `receptionaeroport/inc/receptionaeroport-details` | ce qui est arrive |
| Repartitions | `triagebatiment/inc/triagebatimentparquet-det` | ce qui est range, par parquet |

Cet onglet « Repartitions » est **la vue de repartition du projet**, et elle
porte le nom « repartition » sans que la classe
`ferme.acheminement.Repartition` n'existe dans le code d'origine.

## 3. Ce qui manque pour un flux commande → compartiment

Trois manques identifies, tous factuels.

### 3.1 Aucune liaison commande ↔ lot

`As_BonDeCommande_Fille` ne porte que des **montants** (`quantite`, `pu`,
`montant`, `tva`, `tauxDeChange`, `montantHT/TTC`). Aucun champ `idLot`, aucune
race, aucun sexe, aucune qualite. Aucune vue ne joint `AS_BONDECOMMANDE` et
`LOT`.

Le lot se cree donc a la main, et rien ne garantit qu'il corresponde a une
commande.

### 3.2 Aucune sortie du bande

Le grep `sortie` sur `ferme/` ne renvoie aucun resultat. Le depeuplement de
fin de bande est modelise par `production.Fumigation` (`nombreoac`, cycle
fumigation/extraction), mais :

- le bouton « Cloturer » du lot est commente (`lot-fiche.jsp:93`) ;
- `Lot.dateCloture` n'est pas saisi (`lot-saisie.jsp:34`) ;
- aucune facture ni aucun bon de livraison n'est genere depuis le lot.

**Les animaux sortent du systeme sans trace commerciale.**

### 3.3 Aucune gestion de capacite

`Batiment` porte `surface`, `capacite`, `densite` (lignes 15-17) et controle
que la somme des filles ne les depasse pas (`Batiment.java:143-145`). Mais
`configuration/batiment-saisie.jsp:40-44` rend `capacite` et `effectif`
invisibles et masque `idLot`. Le controle ne peut pas s'exercer, et
`effectif` n'est **jamais** renseigne.

Il n'existe donc aucun mecanisme — ni avant, ni apres le triage — qui empeche
de surcharger un parquet. La seule barriere est l'existence des colonnes
`surface`/`densite`/`capacite` dans l'onglet de consultation
`inc/batiment-details.jsp`.

## 4. Schema de synthese

```
                     +------------------+
                     | COMMANDE ACHAT   |  AS_BONDECOMMANDE
                     | (finance)        |  BC / BCF
                     +--------+---------+
                              |
                     genererLivraison
                     genererFacture
                              |
                     +--------v---------+
                     | LIVRAISON        |  AS_BONDELIVRAISON
                     | FACTURE          |
                     +-----------------+
                              X
                     (aucun lien : ni table, ni vue,
                      ni champ, ni appel)
                     -----------------------------
                              :
                     +--------v-------------------+
                     | LOT                        |  creation manuelle
                     | pivot du domaine           |
                     +--------+-------------------+
                              |
              +---------------+----------------+
              |                                |
   +----------v-----------+        +-----------v-----------+
   | RECEPTION AEROPORT  |        | PROGRAMME            |
   | comptage d'arrivee  |        | ZOOTECHNIQUE         |
   | qteRecus = f(sexe,  |        | attendu par age/sexe |
   |        qualite)     |        +-----------------------+
   +----------+-----------+
              |
        (controle desactive)
              X
   +----------v-----------------------------------------+
   | TRIAGE BATIMENT / PARQUET      <-- LE RANGEMENT    |
   | +----------------------------------------------+  |
   | | idbatiment + idparquet + idsexe + idqualite  |  |
   | | + qte                                        |  |
   | | disponibilites lues dans                     |  |
   | | v_qte_dispo_lot_sexe_qualite                 |  |
   | +----------------------------------------------+  |
   +----------+----------------------------------------+
              |
     (aucun chainage automatique)
     +--------+-------+--------+--------+---------+
     v        v       v        v        v         v
 Suivi    Vaccina  Transfert  Pesée   Distrib.  Fumigation
 Journal  -tion    Poulet                        (depeuplement)
 ier
```

## 5. Les deux flowcharts a retenir

1. **Le flux automatique** ne comporte que **deux** bonds :
   `Reception validee → Triage` (`receptionaeroport-fiche.jsp:75`) et
   `Lot → Onglet Repartitions` (`lot-fiche.jsp:108`).

2. **Le seul calcul serveur** du domaine est `getDisponnibleLib`, qui lit une
   vue SQL. Le seul calcul client est `checkQteFille`, qui compare une somme a
   un total. Tous les autres modules ecrivent sans controler.

## 6. Points d'appui pour une evolution

Si le flux commande → compartiment doit exister, les points d'accroche
existants sont :

| Element existant | Localisation | Ce qu'il manque |
| --- | --- | --- |
| `v_qte_dispo_lot_sexe_qualite` | vue SQL, lue par `TriageLotSexeQualite` | un critere de commande |
| `TriageBatimentParquet` | `ferme/triageBatiment/` | le controle d'equilibre, commente lignes 93-121 |
| `getDisponnibleLib(u, c)` | `TriageBatimentParquet.java:150` | une variante par commande |
| `BatimentDetail.effectif` | `BatimentDetail.java:18` | l'alimentation par le triage |
| `genererLivraison(u, c)` | `As_BonDeCommande.java:466` | le pattern de generation, reutilisable tel quel |
| `Fumigation.nombreoac` | `Fumigation.java` | le pont vers une sortie commerciale |

Le pattern de generation de `genererLivraison` est la seule reference du projet
pour un flux transactionnel complet : connexion externe, ecriture mere + filles
puis commit par l'appelant.