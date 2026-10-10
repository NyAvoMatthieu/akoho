# Couvoir et production — la branche « œufs »

Le paquet s'appelle `couvoir`, pas `couverture`. Cette branche produit des
poussins **sur place**, a partir d'oeufs, et n'est pas chainee au flux du lot
importe. Elle est decrite ici pour completer l'inventaire, pas parce qu'elle
participe a l'acheminement.

## 1. Les modules

Tous sur le meme squelette `ClassMere` + `ClassFille`, liaison `idmere`.

| Mere | Table | Cle | Fille | Table | Cle |
| --- | --- | --- | --- | --- | --- |
| `ReceptionOAC` (l.136) | `RECEPTIONOAC` | `RPO` / `getseq_receptionoac` (l.143) | `ReceptionOACDetail` (l.83) | `RECEPTIONOACDETAIL` (l.83) | `RPOD` (l.90) |
| `TriageOeuf` (l.93) | `TRIAGEOEUF` | `TRO` (l.100) | `TriageOeufDetail` (l.74) | `TRIAGEOEUFDETAIL` | `TROD` (l.81) |
| `Mirage` (l.48) | `MIRAGE` | `MRG` (l.55) | `MirageDetail` (l.83) | `MIRAGEDETAIL` | `MRGD` (l.90) |
| `MiseEnIncubateur` (l.93) | `MISEENINCUBATEUR` | `MEI` (l.100) | `MiseEnIncubateurDetail` (l.111) | `MISEENINCUBATEURDETAIL` | `MEID` (l.118) |
| `Eclosion` (l.84) | `ECLOSION` | `ECL` / `getseq_eclosion` (l.91) | `EclosionDetail` (l.65) | `ECLOSIONDETAIL` | `ECLD` (l.72) |
| `TriageQualitePoussin` (l.66) | `TRIAGEQUALITEPOUSSIN` | `TRP` (l.73) | `TriageQualitePoussinDetail` (l.74) | `TRIAGEQUALITEPOUSSINDETAIL` | `TRPD` (l.81) |
| `SuiviChambreFroide` (l.39) | `SUIVICHAMBREFROIDE` | `SCF` (l.46) | `SuiviChambreFroideDetail` (l.83) | `SUIVICHAMBREFROIDEDETAIL` | `SCFD` (l.90) |

Nomenclature associee : `QualiteTriageOeuf` (`QUALITETRIAGEOEUF`, `QTO` /
`GETSEQ_QUALITETRIAGEOEUF`), `Eclosoir` (`ECLOSOIR`), `Incubateur`
(`INCUBATEUR`).

## 2. Ce que chaque module range, et ou

### `ReceptionOAC` — reception d'oeufs

Fille (lignes 7-13) : `idmere`, `idlot`, `idbatiment`, `idparquet`,
`idqualitetriageoeuf`, `qterecus`.

Des les reception d'oeufs, un lieu physique (batiment + parquet) est deja
designe. C'est la premiere fois que le couple de rangement apparait dans la
branche couvoir.

### `TriageOeuf` — le seul usage de `iddestination`

Fille (lignes 8-12) : `idmere`, `idtypecollecte`, `idqualitetriageoeuf`, `qte`,
**`iddestination`**.

C'est le seul endroit de tout le module `ferme` ou un champ `iddestination`
existe. Ici la destination est un identifiant opaque, sans type de lieu
declaré — contrairement au triage batiment/parquet qui nomme explicitement
bâtiment et parquet.

### `Mirage` — tri des œufs après éclosion

Fille (lignes 7-13) : `idmere`, `idbatiment`, `idparquet`, `idqualitemirage`,
`qte`.

Meme schema que le triage elevage : un lieu + une qualite + une quantite.

### `MiseEnIncubateur` — entree en couvoir

Mere (lignes 8-17) : `id`, `idlot`, `idbatiment`, `idparquet`, `heuredemarrage`,
`heurefin`, `dateponte`, `poidsmoyen`.

### `Eclosion` — sortie de couvoir

Mere (lignes 8-15) : `id`, `idlot`, `dateeclosion`, `nombreoeufinitial`,
`ideclosoir`, `idincubateur`, `idbatiment`, `idparquet`.

Fille (lignes 7-11) : `idmere`, `idqualiteeclosion`, `qte`, `remarque`.

C'est le pont entre les deux branches : `dateeclosion` d'un cote (ici et dans
`Lot`), `idbatiment`/`idparquet` de l'autre. Un lot peut donc etre suivi a la
fois depuis le couvoir et depuis l'import.

### `TriageQualitePoussin` — une **seconde** mise en parquet

Fille (lignes 7-12) : `idmere`, `idbatiment`, `idparquet`, `idqualite`, `qte`.

Schema identique a `TriageBatimentParquetDetail`, dans un autre module. Il
existe donc **deux implementations de la mise en parquet** dans le projet, qui
n'ont ni table commune ni code partage. `TriageQualitePoussin` porte en plus
`ideclosoir` et `idincubateur`, absents du triage d'import.

### `SuiviChambreFroide` — ambiance, pas d'animaux

Fille (lignes 7-13) : `idmere`, `idresponsable`, `heure`, `temperature`,
`humidite`, `remarque`.

## 3. `ImportOAC` — une classe qui herite d'une autre module

```java
ImportOAC extends ReceptionOACLib   ->  table IMPORTOAC
```

Cas unique dans tout le domaine : une classe d'import qui herite d'une vue de
reception plutot que d'une mere. Elle n'a ni `construirePK` propre ni lien de
fille.

## 4. Pourquoi cette branche n'est pas dans le flux d'acheminement

Trois raisons factuelles :

1. **Aucun chainage.** Aucun des sept modules n'est appele par un bouton depuis
   le lot, la reception d'aeroport ou le triage batiment/parquet. Ils sont
   atteignables par le menu dynamique ou par lien de colonne `idlot`.
2. **Pas de comptage partage.** La reception d'aeroport compte les poussins
   arrives par cartons ; la reception d'oeufs compte les oeufs recus. Les
   deux quantites ne se rejoignent dans aucune table.
3. **La disponibilite ne les voit pas.** La vue `v_qte_dispo_lot_sexe_qualite`
   alimente le triage batiment/parquet. Rien ne montre qu'elle tienne compte
   des poussins issus du couvoir.

En l'etat, un lot produit sur place et un lot importe sont deux populations
paralleles sans pont. `TriageQualitePoussin` fournit ce pont sur le plan du
schema, mais il n'est cable a rien.