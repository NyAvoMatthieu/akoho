# Guide de navigation : tester le flux creation -> controle -> repartition

Ce guide accompagne `GUIDE_GESTION_POULES_PONDEUSES.md`. Il decrit un parcours
de test complet, de la creation des referentiels jusqu'a la repartition dans
les compartiments, avec les valeurs a saisir et le resultat attendu a chaque
etape.

## Perimetre couvert

```text
referentiels (poulet, batiment, lieu, compartiment)
  -> bon de commande fournisseur
  -> controle a l'aeroport
  -> controle au poulailler
  -> repartition dans les compartiments
```

La nourriture, les traitements, la ponte et la production restent hors
perimetre.

## 0. Prerequis

### 0.1 Base de donnees

Trois scripts sont a utiliser, dans cet ordre :

```text
arbiochem-war/web/pages/maintenance/ressources/2026-10-05-acheminement-poules-pondeuses-diagnostic.sql
arbiochem-war/web/pages/maintenance/ressources/2026-10-05-acheminement-poules-pondeuses.sql
```

**1. Le diagnostic d'abord.** Il ne modifie rien et repond a la question
prealable a tout le reste : sous quel nom, et dans quel schema, la table de
metadonnees du noyau APJ est-elle accessible ? Executez-le avant toute
installation, en particulier si le noyau APJ semble ne pas fonctionner :

```text
@2026-10-05-acheminement-poules-pondeuses-diagnostic.sql
```

Les cinq questions sont : version d'Oracle, accessibilite de la table de
metadonnees, synonymes et proprietaire possible, structure de la table de
metadonnees, et etat des tables preexistantes dont depend le module.

**2. Le script d'installation ensuite**, une seule fois, sur un schema vide :

```text
@2026-10-05-acheminement-poules-pondeuses.sql
```

Il cree les tables, les fonctions de compteur et leurs sequences, les
contraintes, les index et les vues de
disponibilite. Rien d'autre : les metadonnees `LISTECOLONNETABLE` ne sont pas
chargees, voir l'encadre ci-dessous.

**En cas d'echec pendant l'execution, ne rejouez pas le script tel quel** : les
objets deja crees provoqueraient `ORA-00955` (nom deja utilise). Passez par le
script de reinitialisation, qui detruit les donnees du module dans l'ordre des
dependances :

```text
@2026-10-05-acheminement-poules-pondeuses-reset.sql
```

### Encadre : pourquoi aucune metadata `LISTECOLONNETABLE` n'est inseree

`LISTECOLONNETABLE` porte un nom de table, mais n'en est pas une : c'est une
**vue du socle applicatif, projetee sur le dictionnaire de donnees d'Oracle**.
Deux observations l'etablissent, sur la base cible :

- interrogee via `ALL_OBJECTS`, elle ressort avec `OBJECT_TYPE = 'VIEW'`, ce qui
  explique qu'une recherche dans `USER_TABLES` ne la trouve pas ;
- interrogee via `USER_TAB_COLUMNS`, elle expose 31 colonnes dans l'ordre exact
  de `ALL_TAB_COLUMNS` : position 3 = `COLUMN_NAME`, position 4 = `DATA_TYPE`,
  position 8 = `DATA_PRECISION`, position 9 = `DATA_SCALE`.

Or le noyau APJ lit ces positions sans nommer de colonne
(`decompiled/apj-core/bean/ListeColonneTable`, ligne 289). Les metadonnees des
six tables du module apparaissent donc **d'elles-memes a la creation des
tables**. Toute insertion serait d'ailleurs impossible : une vue n'est pas
modifiable ici.

La section 6 du script se limite a ce constat, et la section 6 bis donne les
requetes de verification.

### Deux points a verifier apres installation

> **Version d'Oracle.** La base cible est en Oracle Database 11g Enterprise
> Edition Release 11.2.0.1.0, ou la limite d'identifiant est de 30 caracteres
> (128 a partir de 12.2). Les 42 identifiants du script tiennent dans cette
> limite, le plus long faisant 29 caracteres.
>
> **Une seule erreur a la fois.** Une erreur de creation entraine des
> `ORA-00942` sur tout ce qui depend de l'objet manquant. Traitez la premiere
> erreur du journal, pas les suivantes. La section 10 du script d'installation
> detaille chaque message et sa cause probable.

Le schema est aussi suppose conforme aux contraintes suivantes : `BATIMENT`
et `SEXE` doivent deja exister. Le script verifie leur presence en section 0 et
s'arrete avec la liste de ce qui manque bloquant.

`LISTECOLONNETABLE` est traitee a part : son absence n'interdit pas
l'installation, elle est signalee sans interrompre le script. Si aucun
formulaire APJ ne fonctionne apres installation, la cause est ailleurs, voir la
section 10.7 du script.

Verifier ensuite en SQL :

```sql
SELECT table_name FROM user_tables
WHERE table_name IN ('POULET', 'MAGASIN_ELEVAGE', 'COMPARTIMENT',
                     'CONTROLE_POULET', 'REPARTITION', 'REPARTITION_FILLE');
```

Les six tables doivent etre listees.

### 0.2 Compilation et deploiement

Depuis la racine du projet :

```bash
ant -f build.xml compile
```

Puis, selon votre configuration locale WildFly :

```bash
ant -f build.xml
```

Le second cible depend de WildFly et de `deploy.dir` dans `build.xml`.
Verifiez ces valeurs avant de l'executer.

### 0.3 Connexion et nom de contexte

Se connecter a l'application. Toutes les URL de ce guide sont relatives au
contexte de l'application, et passent par le dispatcher :

```text
module.jsp?but=<chemin de la page>
```

Le parametre `but` est obligatoire. Une URL appelee directement sans session
valide est rejetee par `module.jsp` et renvoie vers la page de connexion.

## 1. Referentiels

### 1.1 Poulet

Ouvrir la liste :

```text
module.jsp?but=ferme/poulet/poulet-liste.jsp
```

Cliquer sur **Saisir un poulet**, puis saisir :

| Champ     | Valeur test      |
| --------- | ---------------- |
| Nom       | `Poulet test 1`  |
| Race      | `Race test A`    |

Valider. Vous arrivez sur `poulet-fiche.jsp`. Noter l'identifiant affiche.
Il commence par `POU`, prefixe defini dans `Poulet.construirePK`.

Verification :

```sql
SELECT id, nom, race FROM poulet;
```

### 1.2 Batiment (poulailler)

Le poulailler est modelise par `BATIMENT`. Il doit deja exister, mais
verifiez :

```text
module.jsp?but=ferme/configuration/batiment-liste.jsp
```

S'il n'existe pas, creer un batiment via
`module.jsp?but=ferme/configuration/batiment-saisie.jsp`. Le champ **Ferme**
est obligatoire (il pointe sur `magasin.Magasin`).

Noter l'identifiant du batiment, il commence par `BAT`.

### 1.3 Lieu (aeroport et poulailler)

Les lieux sont dans le nouveau referentiel `MAGASIN_ELEVAGE`.

> Ce referentiel n'a pas encore de page JSP. Les lieux doivent donc etre
> charges en SQL, via la section 1.5.
>
> La creation des pages `magasin-elevage-liste/saisie/fiche.jsp` reste a
> faire si vous voulez gerer les lieux depuis l'interface.

Une fois charges, verifier :

```sql
SELECT id, nom, typelieu, idbatiment, actif FROM magasin_elevage;
```

### 1.4 Compartiments

Ouvrir :

```text
module.jsp?but=ferme/configuration/compartiment/compartiment-liste.jsp
```

Creer deux compartiments rattaches au meme batiment :

| Champ         | Compartiment A     | Compartiment B     |
| ------------- | ------------------ | ------------------ |
| Nom           | `Compartiment A`   | `Compartiment B`   |
| Capacite      | `100`              | `100`              |
| Poulailler    | le batiment de 1.2 | le batiment de 1.2 |

Les capacites sont expresses en nombre de poulets, pas en surface.

### 1.5 Jeu de donnees de test minimal

Si les lieux doivent etre charges en SQL :

```sql
INSERT INTO MAGASIN_ELEVAGE (ID, NOM, TYPELIEU, IDBATIMENT, ACTIF)
VALUES ('MLE001', 'Aeroport test', 'AEROPORT', NULL, 1);

INSERT INTO MAGASIN_ELEVAGE (ID, NOM, TYPELIEU, IDBATIMENT, ACTIF)
VALUES ('MLE002', 'Poulailler test', 'POULAILLER', '<ID_DU_BATIMENT>', 1);

COMMIT;
```

Un lieu `POULAILLER` doit obligatoirement avoir un `IDBATIMENT` : la
contrainte `CK_MAGASIN_ELEVAGE_POULAILLER` l'impose, et le code la verifie
aussi dans `MagasinElevage.controlerTypeLieu`.

## 2. Bon de commande (antecedent du controle aéroport)

### 2.1 Modele de ligne accepte

Le controle accepte deux modeles de ligne de commande. Il cherche d'abord une
ligne `BON_COMMANDE_SIMPLE_LIGNE`, puis une ligne `AS_BONDECOMMANDE_FILLE`.
Dans les deux cas il verifie que la ligne appartient bien au bon de commande
designe, et prend `quantite` comme quantite theorique.

| Modele | Table | Saisie depuis |
| ------ | ----- | ------------- |
| Achats | `AS_BONDECOMMANDE_FILLE` | `bondecommande/bondecommande-arbiochem-saisie.jsp` |
| Bon de commande simple | `BON_COMMANDE_SIMPLE_LIGNE` | aucune page : passer par SQL |

Utilisez le modele **Achats**, seul accessible depuis l'interface.

### 2.2 Creation du BC

Le bon de commande fournisseur se saisit depuis :

```text
module.jsp?but=bondecommande/bondecommande-arbiochem-saisie.jsp
```

Deux identifiants sont a relever :

- l'ID du bon de commande, pour le champ **Antecedent** ;
- l'ID de sa **ligne**, pour le champ **Ligne de l'antecedent**.

La ligne porte `id`, `idbc` (vers le bon de commande) et `quantite`, dans la
table `AS_BONDECOMMANDE_FILLE`. C'est cette ligne qui fournit la quantite
theorique du controle.

Pour le scenario de reference, commandez **100 poulets** sur une seule ligne :
c'est ce qui produit 90 vivants, 5 morts et 5 perdus au controle aéroport.

Si le meme BC porte deux races ou deux sexes, commandez deux lignes. Chaque
controle ne portera alors que sur la ligne que vous designerez, ce qui est le
comportement attendu du modele.

Verification :

```sql
SELECT id, idbc, produit, quantite FROM as_boncommande_fille
ORDER BY id;
```

Si la ligne n'apparait pas ici, le controle refusera l'antecedent : verifiez
que vous avez bien releve l'ID de la **ligne**, et non celui du bon de
commande.

### 2.3 Alternative : partir d'un BL

Si le flux de votre organisation passe par un bon de livraison, remplacez
l'etape 2 par une saisie de BL fournisseur. Le controle accepte alors
`typeAntecedent = 'BL'` et la ligne `AS_BONDELIVRAISON_FILLE`.

## 3. Controle a l'aeroport

### 3.1 Saisie

Ouvrir :

```text
module.jsp?but=ferme/acheminement/controle-poulet-saisie.jsp
```

Saisir le scenario nominal du guide :

| Champ                    | Valeur                |
| ------------------------ | --------------------- |
| Date du controle         | date du jour          |
| Type d'antecedent        | `BC`                  |
| Antecedent               | l'ID du BC (2.2)      |
| Ligne de l'antecedent    | l'ID de la ligne BC   |
| Poulet                   | choisir `Poulet test 1` |
| Lieu                     | choisir `Aeroport test` |
| Nombre de vivants        | `90`                  |
| Nombre de morts          | `5`                   |

Trois points sur ce formulaire :

- **Poulet** et **Lieu** sont des listes deroulantes alimentes par `POULET`
  et `MAGASIN_ELEVAGE`, affichant le nom. Elles stockent l'identifiant.
- **Antecedent** et **Ligne de l'antecedent** sont des champs libres : ce sont
  les seuls identifiants a recopier depuis l'etape 2.2.
- Le champ **Id**, en tete du formulaire, peut rester vide : il est genere
  par la fonction `GETSEQCONTROLEPOULET`. Le champ n'apparait d'ailleurs pas
  en saisie, le noyau APJ l'excluant volontairement du formulaire d'insertion.

Les champs **Quantite theorique** et **Nombre de perdus** sont masques : ils
sont calcules par le serveur, jamais saisis.

Apres validation, vous arrivez sur `controle-poulet-fiche.jsp`. La fiche doit
afficher :

| Champ                 | Valeur attendue |
| --------------------- | --------------- |
| Quantite theorique    | `100`           |
| Nombre de vivants     | `90`            |
| Nombre de morts       | `5`             |
| Nombre de perdus      | `5`             |

Verifier en base :

```sql
SELECT id, typeantecedent, idantecedent, idligneantecedent,
       idpoulet, idmagasin, quantitetheorique, nbvivant, nbmort, nbperdu, etat
FROM controle_poulet;
```

`NBPERDU` doit valoir 5, et `NBVIVANT + NBMORT + NBPERDU = QUANTITETHEORIQUE`.

### 3.2 Valider le controle

Sur la fiche, cliquer **Valider**. L'etat passe a `11`.

Ce n'est pas obligatoire pour enchainer la suite du scenario, mais c'est
necessaire pour que les vues `DISPONIBILITE_LIEU` et
`DISPONIBILITE_COMPARTIMENT` (sections 7.2 et 7.3) comptabilisent les
effectifs : elles ne retiennent que les lignes `ETAT >= 11`. Le bouton
**Modifier** disparait aussi : le framework interdit modifier un objet valide
(`ClassEtat.updateObject`).

## 4. Controle au poulailler

### 4.1 Saisie

Ouvrir :

```text
module.jsp?but=ferme/acheminement/controle-poulet-saisie.jsp
```

Saisir :

| Champ                 | Valeur                          |
| --------------------- | ------------------------------- |
| Date du controle      | date du jour                    |
| Type d'antecedent     | `CONTROLE`                      |
| Antecedent            | l'ID du controle aéroport (3.1) |
| Ligne de l'antecedent | vide                            |
| Poulet                | choisir `Poulet test 1`         |
| Lieu                  | choisir `Poulailler test`       |
| Nombre de vivants     | `90`                            |
| Nombre de morts       | `0`                             |

**Antecedent** est ici un champ libre, a recopier depuis la ligne SQL de la
section 3.1. **Poulet** doit rester identique a celui du controle aéroport :
un poulet different est refuse par `ControlePoulet.controlerAntecedent`.
**Ligne de l'antecedent** reste vide : un controle n'a pas de ligne fille.

La quantite theorique est reprise automatiquement depuis `nbVivant` du
controle aéroport, soit `90`. C'est le cas 3 du guide.

Le type d'antecedent est partiellement lie au lieu : un lieu `POULAILLER`
exige `CONTROLE`, donc saisir `BC` ici est refuse.

> La regole inverse n'est pas appliquee : un controle de type `CONTROLE` dans
> un lieu `AEROPORT` est accepte, et un controle `BC` ou `BL` dans un lieu
> `AEROPORT` aussi. Seule l'absence de type reconnu est refusee. Si vous
> voulez que le type soit entierement determine par le lieu, il faut ajouter
> cette verification dans `ControlePoulet.controlerLieu`.

### 4.2 Fiche

La fiche doit afficher `Quantite theorique = 90`, `Vivants = 90`,
`Morts = 0`, `Perdus = 0`.

## 5. Repartition

### 5.1 Saisie

Ouvrir :

```text
module.jsp?but=ferme/acheminement/repartition-saisie.jsp
```

Le formulaire est un maitre/detail. Saisir l'en-tete :

| Champ                     | Valeur                            |
| ------------------------- | --------------------------------- |
| Date de la repartition    | date du jour                      |
| Controle de poulailler    | choisir le controle de 4.1       |
| Bon de livraison          | vide                              |

**Controle de poulailler** est une liste deroulante construite sur
`CONTROLE_POULET`, qui affiche l'identifiant du controle. Le tableau supporte
10 lignes (`nombreLigne` dans la page).

Saisir deux lignes dans le tableau :

| Compartiment     | Sexe     | Sante | Quantite |
| ---------------- | -------- | ----- | -------- |
| `Compartiment A` | Male     | `10`  | `40`     |
| `Compartiment B` | Femelle  | `10`  | `50`     |

La liste deroulante **Sexe** est alimentee par la table `SEXE`. Les libelles
viennent de cette table, mais les valeurs stockees sont `1` pour le male et
`0` pour la femelle (`ferme.utils.ConstanteFerme`). Ce sont ces valeurs la
que `RepartitionFille.controlerChamps` verifie.

La somme doit egaler les `90` vivants du controle de poulailler. C'est le
cas 5 du guide (`40 + 50 = 90`).

Le tableau permet d'ajouter des lignes avec le bouton de la page, comme sur
les autres maitres/details du projet.

### 5.2 Fiche et details

Apres validation, vous arrivez sur `repartition-fiche.jsp`, avec un onglet
**Details**. L'onglet affiche les lignes via
`inc/repartition-details.jsp`.

Verification en base :

```sql
SELECT id, daty, idcontrolepoulailler, idbl, etat FROM repartition;

SELECT id, idrepartitionmere, idcompartiment, qtt, sexe, sante
FROM repartition_fille
ORDER BY idrepartitionmere;
```

Le total doit valoir `90`.

### 5.3 Vue de disponibilite

```sql
SELECT * FROM capacite_restante_compartiment;
```

Les deux compartiments doivent afficher `effectif = 40` et `effectif = 50`,
donc `capaciterestante = 60` et `50`.

## 6. Points de controle

Voici les refus a verifier en cours de route. Chacun doit produire une alerte
JS avec le message, et ne rien ecrire en base.

| Test | Saisie | Resultat attendu |
| --- | --- | --- |
| Vivants + morts > theorique | `90` + `11` sur `100` | refuse (cas 2) |
| Antcedent inexistant | `BC` avec un ID bidon | refuse (cas 4) |
| Ligne d'un autre BC | ID de BC incoherent avec `idbc` | refuse |
| Type d'antecedent inconnu | `typeAntecedent = 'XYZ'` | refuse |
| Lieu incompatible | type `BC` avec lieu `Poulailler test` | refuse |
| Mauvais poulailler | compartiment rattache a un autre batiment | refuse (cas 9) |
| Capacite depassee | voir 6.1 | refuse (cas 10) |
| Quantite nulle | `qtt = 0` sur une ligne | refuse (cas 7) |
| Sante hors bornes | `sante = 11` ou `-1` | refuse (cas 8) |
| Sexe inconnu | `sexe` hors `0`/`1` | refuse |
| Somme de repartition fausse | `40` + `49` | refuse (cas 6) |

Le message apparait dans une alerte JavaScript, et l'URL precedente est
restauree (`history.back()`).

### 6.1 Preparer le test de capacite

Le scenario de la section 5 utilise deux compartiments de `100` pour `90`
poulets : la depassement de capacite ne peut donc pas se produire. Pour tester
le cas 10, reduisez la capacite d'un compartiment.

```sql
UPDATE COMPARTIMENT SET CAPACITE = 30 WHERE ID = '<ID_COMPARTIMENT_A>';
COMMIT;
```

Redistribuez ensuite `40 + 50` : le compartiment A va recoevoir plus que ses
`30`, et la repartition doit etre refusee. Remettez la capacite a `100` apres
le test.

```sql
UPDATE COMPARTIMENT SET CAPACITE = 100 WHERE ID = '<ID_COMPARTIMENT_A>';
COMMIT;
```

Le controle de capacite additionne aussi l'occupation deja enregistree par
les autres repartitions du meme compartiment : `Repartition` appelle
`getOccupationExistante` avant de comparer.

## 7. Verification en base de donnees

### 7.1 Chaine de traceability

```sql
SELECT * FROM suivi_acheminement ORDER BY datecontrole, idrepartition;
```

Cette vue materialize la chaine :

```text
BC -> controle (aeroport) -> controle (poulailler) -> repartition
```

### 7.2 Effectifs par lieu

```sql
SELECT * FROM disponibilite_lieu;
```

Seuls les controles valides (`etat >= 11`) apparaissent. Si un controle reste
invisible dans cette vue alors que la fiche existe, c'est qu'il n'est pas
valide.

### 7.3 Repartition par compartiment et par sexe

```sql
SELECT * FROM disponibilite_compartiment;
```

## 8. Tests de securite

### 8.1 Acces direct sans droit

Ouvrir directement une URL de saisie sans y etre autorise :

```text
module.jsp?but=ferme/acheminement/repartition-saisie.jsp
```

Le controle d'acces joue sur l'objet insere, pas sur la page. Le refus
survient au moment de la validation, via `ActionRole.estAutorise` dans
`UserEJBBean.createObjectMultiple`.

### 8.2 Double soumission

Sur `repartition-saisie.jsp`, double-cliquer sur le bouton de validation, ou
revenir en arriere puis rejouer l'enregistrement.

Le dispatcher est `apresMultiple.jsp`, qui appelle
`UserEJBBean.createObjectMultiple`. Chaque envoi cree un nouvel identifiant :
le risque n'est pas la ligne en double, mais **deux repartitions** pour le
meme controle de poulailler.

Verifier :

```sql
SELECT idcontrolepoulailler, COUNT(*)
FROM repartition
GROUP BY idcontrolepoulailler
HAVING COUNT(*) > 1;
```

Si cette requete retourne une ligne, le flux n'empeche pas de repartir deux
fois les memes vivants. Ce controle n'est pas implemente cote serveur : il
repose sur le masquage du bouton une fois la repartition validee. A traiter
si ce cas doit etre bloque.

### 8.3 Transaction

`UserEJBBean.createObjectMultiple` ouvre une connexion, positionne
`setAutoCommit(false)`, cree le maitre puis les filles, et valide en
`commit`. Si une ligne echoue, le `rollback` annule le maitre et toutes les
lignes. C'est le cas 11 du guide.

Pour le verifier : saisir une repartition dont la derniere ligne viole une
regle (par exemple une quantite nulle), puis confirmer :

```sql
SELECT COUNT(*) FROM repartition WHERE daty = TRUNC(SYSDATE);
```

Aucune nouvelle repartition ne doit apparaitre.

## 9. Tests automatises

Les regles de calcul pures sont couvertes par :

```text
arbiochem-ejb/test/ferme/acheminement/CalculAcheminementTest.java
```

Compilation et execution :

```bash
CP="build-file/arbiochem_jar:$(ls build-file/lib/*.jar | tr '\n' ':')"
mkdir -p /tmp/acheminement-test

javac -source 1.8 -target 1.8 -encoding iso-8859-1 \
    -cp "$CP" -d /tmp/acheminement-test \
    arbiochem-ejb/test/ferme/acheminement/CalculAcheminementTest.java

java -cp "$CP:/tmp/acheminement-test" ferme.acheminement.CalculAcheminementTest
```

Sortie attendue : `Reussis : 13 / Echecs : 0`.

Le projet n'a pas de cible de test Ant ni JUnit dans `build-file/lib` : cette
classe s'execute manuellement.

## 10. Points non couverts

| Sujet | Statut |
| ----- | ------ |
| Rollback du maitre et des lignes (cas 11) | le mecanisme transactionnel est en place (`UserEJBBean.createObjectMultiple`), mais non verifie en base |
| Modification apres validation (cas 12) | le blocage vient de `ClassEtat.updateObject` ; a confirmer sur le flux de validation APJ |
| Double repartition d'un meme controle | **non bloque** cote serveur, voir 8.2 |
| Type d'antecedent non deduit du lieu | seule la contrainte `POULAILLER -> CONTROLE` existe, voir 4.1 |
| Coherence chronologique d'un BC ou BL | l'ordre des dates n'est verifie que pour un antecedent `CONTROLE`, pas contre le BC ou le BL |
| Referentiel des lieux sans interface | a creer si vous voulez saisir les lieux depuis l'IHM |

Les cas 4 et 9 sont testes dans l'interface (section 6), mais pas par la
classe de tests automatises, qui ne touche pas la base.

## 11. En cas de probleme

### La page affiche une erreur de compilation JSP

Verifier que le war a ete reconstruit apres la compilation :

```bash
ant -f build.xml compile
```

Si le deploiement n'a pas eu lieu, les nouvelles pages ne sont pas servies.

### Un champ n'apparait pas dans le formulaire

Le framework APJ ne mappe que les champs presents **a la fois** dans la classe
Java et parmi les colonnes vues par `LISTECOLONNETABLE` (`RESUME_ANALYSE_APJ.md`,
section 18.2). Cette vue etant projetee sur le dictionnaire de donnees, une
colonne existe des la creation de sa table : la cause n'est donc **pas** une
ligne de metadata manquante dans le script SQL, mais le plus souvent l'absence
de champ Java correspondant. Verifiez dans ce sens :

```sql
SELECT * FROM listeColonneTable
WHERE table_Name = 'CONTROLE_POULET'
ORDER BY column_id;
```

Le noyau APJ interroge cette table ainsi :

```sql
SELECT * FROM listeColonneTable
WHERE table_Name = upper('CONTROLE_POULET')
ORDER BY column_id ASC;
```

et lit le nom du champ en colonne 3, le type en colonne 4. Si un champ manque
malgre tout, verifiez que la section 6 a bien insere une ligne pour chaque
colonne de `CONTROLE_POULET` :

```sql
SELECT COUNT(*) FROM user_tab_columns
WHERE table_name = 'CONTROLE_POULET';
```

La valeur renvoyee doit etre identique au nombre de lignes metadata du
meme nom de table. Rappel : la colonne `ETAT` doit figurer dans les
metadonnees, sinon `getChamp("etat")` renvoie null et la page echoue.

### ORA-00904 sur un nom en GETSEQ...

Les objets `GETSEQ*` doivent etre des **fonctions**, pas des sequences.

`construirePK` passe le nom a `makePK`, qui appelle `Utilitaire.getMaxSeq`.
Pour Oracle, ce dernier construit :

```java
cs = c.prepareCall("select " + nomProcedure + " from dual");
```

Il n'ajoute jamais `.nextval`. Une sequence portant ce nom n'est donc pas
appelable ainsi, et Oracle repond `ORA-00904: "GETSEQPOULET" : identifiant non
valide` des la premiere saisie.

Chaque fonction encapsule une sequence `SEQ_*` :

| Classe | Prefixe | Fonction | Sequence |
| ------ | ------- | -------- | -------- |
| `Poulet` | `POU` | `GETSEQPOULET` | `SEQ_POULET` |
| `MagasinElevage` | `MLE` | `GETSEQMAGASINELEVAGE` | `SEQ_MAGASIN_ELEVAGE` |
| `Compartiment` | `CMP` | `GETSEQCOMPARTIMENT` | `SEQ_COMPARTIMENT` |
| `ControlePoulet` | `CPL` | `GETSEQCONTROLEPOULET` | `SEQ_CONTROLE_POULET` |
| `Repartition` | `REP` | `GETSEQREPARTITION` | `SEQ_REPARTITION` |
| `RepartitionFille` | `RPF` | `GETSEQREPARTITIONFILLE` | `SEQ_REPART_FILLE` |

Verifiez le type reel :

```sql
SELECT object_name, object_type
  FROM user_objects
 WHERE object_name LIKE 'GETSEQ%';

SELECT GETSEQPOULET FROM dual;
```

Les six noms du module doivent apparaitre en `FUNCTION`. S'ils apparaissent en
`SEQUENCE`, c'est qu'une version anterieure du script d'installation a ete
jouee : executez le script de reinitialisation, puis celui d'installation.

### Un identifiant est trop long

`makePK` complete la valeur sur 6 positions, et prefixe avec l'indice
declare dans `construirePK`. Avec un prefixe de 3 lettres, l'identifiant
total fait 9 caracteres, ce qui tient dans `VARCHAR2(20)`. Si vous changez un
prefixe, verifiez la longueur de la colonne.

Le total tient dans `VARCHAR2(20)`. Si vous changez un prefixe, verifiez la
longueur de la colonne.