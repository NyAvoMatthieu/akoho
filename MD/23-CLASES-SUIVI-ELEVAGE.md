# Suivi et actes d'elevage

Sept modules independants qui s'appliquent au parc deja range. Ils portent tous
le meme squelette `ClassMere` + `ClassFille`, et tous designent le lieu par
`idbatiment` + `idparquet`. Aucun n'est chaine au triage par un bouton.

## 1. `suiviJournalier` — le suivi d'effectif quotidien

`arbiochem-ejb/src/java/ferme/suiviJournalier/`

| | Mere | Fille |
| --- | --- | --- |
| Classe | `SuiviJournalier` (l.7) | `SuiviJournalierDetail` (l.6) |
| Heritage | `ClassMere` | `ClassFille` |
| Table | `SUIVIJOURNALIER` (l.48) | `SUIVIJOURNALIERDETAIL` (l.137) |
| Cle | `SJ` / `getseq_suivijournalier` (l.55) | `SJD` / `getseq_suivijournalierdetail` (l.144) |
| Vue | `SUIVIJOURNALIER_LIB` | `SUIVIJOURNALIERDETAIL_LIB` |
| Liaison | `setLiaisonFille("idmere")` | `setLiaisonMere("idmere")` |

Mere (lignes 8-11) : `id`, `daty`, `idferme`, `idlot`.

Fille (lignes 7-19) — le vrai etat du parc d'un parquet, jour donne :

| Champ | Role |
| --- | --- |
| `idmere`, `idbatiment`, `idparquet` | le parquet suivi |
| `agejour` | age en jours |
| `entree` | **entrees du jour** |
| `tri` | **sorties vers un autre parquet** |
| `mortalite`, `culls` | **pertes**, les deux termes etant distincts |
| `consignesuraliment`, `eau` | consommation |
| `temperaturemin`, `temperaturemax` | ambiance |

C'est **le seul module du projet qui suive l'effectif en mouvement**. Le
`BatimentDetail.effectif` existe mais n'est jamais alimente (voir
`20-CLASES-LOT-ET-REFERENTIELS.md`) : le suivi reel passe donc par ici, sous
forme de flux journaliers et non d'etat instantane.

Aucune classe de controle dans ce module : `createObject` n'est pas surcharge.
La coherence `entree - tri - mortalite - culls` avec l'effectif theorique
n'est pas verifiee.

## 2. `vaccination`

| | Mere | Fille |
| --- | --- | --- |
| Classe | `VaccinationPoussin` (l.11) | `VaccinationPoussinDetail` (l.11) |
| Table | `VACCINATIONPOUSSIN` (l.18) | `VACCINATIONPOUSSINDETAIL` (l.20) |
| Cle | `VACP` / `GETSEQVACCINATIONPOUSSIN` (l.25) | `VACPF` / `GETSEQVACCINATIONPOUSSINDETAIL` (l.27) |
| Liaison | `setLiaisonFille("idMere")` | `setLiaisonMere("idMere")` |

Mere : `id`, `remarque`, `idLot`, `daty`.

Fille (lignes 13-17) : `idMere`, `idBatiment`, `idParquet`, `idTypeVaccination`,
`idMaladiePoussin`, `idVaccin`, `idModeAdministration`, `qteDose`, `heureDebut`,
`heureFin`, `dateExpiration`.

## 3. `transfertpoulet` — le seul module avec depart ET arrivee

| | Mere | Fille |
| --- | --- | --- |
| Classe | `TransfertPoulet` (l.11) | `TransfertPouletDetail` (l.10) |
| Table | `TRANSFERTPOULET` (l.17) | `TransfertPouletDetail` (l.16) |
| Cle | `TRSP` / `GETSEQTRANSFERTPOULET` (l.24) | `TRSPF` / `GETSEQTRANSFERTPOULETDETAIL` (l.23) |

Fille (lignes 11-13) — la seule table du domaine qui modelise un deplacement :

```java
private String idMere, idSexe,
              idFermeDepart,  idBatimentDepart,  idParquetDepart,
              idFermeArrive,  idBatimentArrive,  idParquetArrive,
              idControleur, idChauffeur, idVehicule;
private double qte;
```

Trois paires de triplets depart/arrivee (ferme, batiment, parquet), plus le
conducteur, le chauffeur et le vehicule. C'est la table la plus proche d'un
« mouvement de stock » du domaine elevage.

La casse de la table fille est en minuscules, comme `receptionaeroport`.

## 4. `pesee`

| | Mere | Fille |
| --- | --- | --- |
| Classe | `PeseePoussin` (l.9) | `PeseePoussinDetail` (l.6) |
| Table | `PESEEPOUSSIN` (l.104) | `PESEEPOUSSINDETAIL` (l.56) |
| Cle | `PP` / `getseq_peseepoussin` (l.111) | `PPD` / `getseq_peseepoussindetail` (l.63) |

Cas particulier : la mere porte **deja** `idferme`, `idbatiment`, `idlot`,
`idparquet`, `idsexe` (lignes 10-19). Le lieu est donc porte par la mere, et la
fille ne contient que la mesure :

```java
private String id, idmere;
private double poids, nombreoiseaux;
```

Une pesee porte donc un seul lieu. Aucun controle de plausibilite du poids, et
la classe `ConfigPoids` de `ferme/utils` (fourchettes `poidsmin` / `poidsmax` /
`pas`) n'est branchee nulle part dans le module.

## 5. `aliment`

| | Mere | Fille |
| --- | --- | --- |
| Classe | `DistributionAliment` (l.11) | `DistributionAlimentDetail` (l.10) |
| Table | `distributionAliment` (l.17) | `distributionAlimentDetail` (l.16) |
| Cle | `DSTA` / `GETSEQDISTRIBUTIONALIMENT` (l.24) | `DSTAF` / `GETSEQDISTADETAIL` (l.23) |

Fille (lignes 12-13) : `idMere`, `idBatiment`, `idParquet`, `idAliment`,
`idLotStock`, `qte`, `rationParTete`.

`idLotStock` fait le lien vers le stock d'aliment. `rationParTete` permet de
deriver un effectif theorique par division — mais **aucun code ne fait cette
division**, ni ne compare a `effectif`.

## 6. `batiment` — la desinfection entre deux bandes

| | Mere | Fille |
| --- | --- | --- |
| Classe | `BatimentVideSanitaire` (l.7) | `BatimentVideSanitaireDetail` (l.6) |
| Table | `BATIMENTVIDESANITAIRE` (l.81) | `BATIMENTVIDESANITAIREDETAIL` (l.78) |
| Cle | `BVS` / `GETSEQBATIMENTVIDESANITAIRE` (l.88) | `BVSF` / `GETSEQBATVIDSANITDET` (l.85) |

Mere (ligne 8) : `id`, `idbatiment`, `idresponsable`, `daty`, `heuredebut`,
`heurefin`.

Fille (lignes 7-11) : `idmere`, `idproduit`, `qte`, `remarque` — le produit
chimique et la quantite employee.

C'est le seul module du domaine qui porte le nom du lieu sur la **mere** et qui
n'ait qu'une fille de nature technique (pas d'animaux).

## 7. `programme` — le referentiel theorique du lot

| | Mere | Fille |
| --- | --- | --- |
| Classe | `ProgrammeZootechnique` (l.81) | `ProgrammeZootechniqueDetails` (l.219) |
| Table | `PROGRAMMEZOOTECHNIQUE` (l.~200) | `PROGRAMMEZOOTECHNIQUEDETAILS` |
| Cle | `PZT` / `getseq_programmezootechnique` (l.82) | `PZTD` / `getseq_pzootechniquedetails` (l.219) |
| Vue | `PROGRAMMEZOOTECHNIQUE_LIB` | `PROGRAMMEZOOTECHNIQUEDT_LIB` |

La fille est le **tableau de bord zootechnique**, le plus riche du projet (27
champs, lignes 9-35) : `age`, `idsexe`, `aliment`, `poids`, `mortalite`,
`pontehebdomadaire`, `pontecumulee`, `oeufcumule`, `oacpourcentage`, `oachh`,
`poidsoeuf`, `tauxeclosion`, `poussins`, `consoalimentfemelle`,
`consoalimentmale`, `femellebw`, `malebw`, `ratioproduction`, `fertilite`,
`consommationEau`, `temperatureMin`, `temperatureMax`, `humiditeMin`,
`humiditeMax`, `dureeEclairage`, `uniformiteCible`, `cvMax`.

C'est la seule table du domaine qui soit une **grille par age et par sexe**.
Elle est censee dire l'attendu, que le suivi journalier compare au reel.

**Mais aucun code ne fait cette comparaison.** `age` est une chaine, `poids`
un double : il n'existe pas de champ « poids reel » dans le suivi journalier.
Le programme est donc un referentiel declarative, non opposable.

## 8. `production.Fumigation` — le depeuplement de fin de bande

`Fumigation.java` — heritage `ClassEtat` (l.7), table `FUMIGATION`,
cle `FMG` / `getseq_fumigation` (l.160). **Pas de classe fille** : c'est le
seul module `ferme` en objet simple.

Champs (lignes 8-22) : `id`, `daty`, `idnumerovague`, `idoperateur`, `idlot`,
`nombreoac`, `heuredebutfumigation`, `heurefinfumigation`,
`heuredebutextraction`, `heurefinextraction`, `idproduit`, `qte`,
`temperaturemin`, `temperaturemax`, `idBatiment`, `idParquet`.

Le nom est trompeur : ce n'est pas une fumigation sanitaire, c'est le **depeuplement
d'un parquet** a la fin d'une bande. `nombreoac` est l'effectif de la vague,
`qte` la quantite de produit utilise, et les quatre heures decrivent le
cycle fumigation / extraction.

C'est le seul point de sortie du domaine. Mais il n'y a **aucune sortie
commerciale** : le grep `sortie` sur tout `ferme/` ne renvoie rien, et le
bouton « Cloturer » du lot est commente (`lot-fiche.jsp:93`).

## 9. Constat commun aux sept modules

Tous appliquer une comparaison automatique entre le programme zootechnique
(attendu par age et sexe) et le suivi journalier (reel par parquet et par jour)
reviendrait a iterer sur une grille. Aucun code ne le fait.

Tous les sept modules ont des controleurs de coherence minimalistes ou absents :
seuls `receptionaeroport` (somme des details = total) et `Batiment`
(somme des parquets <= capacite) en ont un.

Tous les sept sont des **triplets independants**. Aucun bouton ne les chaine, ni
au triage, ni entre eux. Le seul point de convergence est le lien de colonne
`idLot` vers `lot-fiche.jsp`.