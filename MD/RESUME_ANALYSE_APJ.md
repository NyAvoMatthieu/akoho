# Résumé — Analyse du framework APJ

> Synthèse de [ANALYSE_FRAMEWORK_APJ.md](ANALYSE_FRAMEWORK_APJ.md).
> Le détail complet, les sources et les justifications se trouvent dans le document d’origine.

## 1. Identification du framework

Le projet n’est pas une application Spring, Laravel, Django ou Symfony. Il repose sur un
framework interne propriétaire appelé **APJ**.

- Packages caractéristiques : `bean.*`, `affichage.*`, `historique.*`, `utilitaire.*` ;
- Bibliothèques : `apj-core.jar` et `apj-core2.jar` (livrées compilées, sans source maître) ;
- Classes pivot : `ClassMAPTable`, `ClassEtat`, `ClassMere`, `TypeObjet` ;
- Composants de présentation : `PageRecherche`, `PageInsert`, `PageConsulte` ;
- EJB transversal : `user.UserEJB`.

Modèle mental global :

```text
JSP impératives
    |
    v
objets APJ Java
    |
    v
UserEJB / ClassMAPTable
    |
    v
SQL JDBC / Oracle
```

## 2. Architecture générale

### Modules

| Module | Rôle |
|---|---|
| `arbiochem-ejb` | Module Java principal : classes métier, objets persistants, `UserEJB`/`UserEJBBean`, utilitaires, connexion. Beaucoup de code est du Java ordinaire manipulant JDBC directement malgré le nom EJB. |
| `arbiochem-war` | Module web : JSP (cœur du fonctionnement), ressources statiques, servlets spécialisées, `web.xml`, `web-fragment.xml`. |
| `build-file` | Espace de compilation généré par Ant (`arbiochem_jar`, `arbiochem_war`, `lib`, `ear`). |
| `codebar-generator` | Projet auxiliaire de génération de codes-barres. |
| `google-adk` | Projet auxiliaire Python, hors cycle Java EE. |

## 3. Assemblage et déploiement

Build principal dans `build.xml`. Cycle Ant observable :

```text
clean -> init -> compile -> buildEjbJar -> compileWar -> copieProperties -> deploy
```

- **init** : création des dossiers de sortie, copie des JSP, des libs dans `WEB-INF/lib`, de `project.properties` et `apj.properties`.
- **compile** : compilation de `arbiochem-ejb/src/java` vers `build-file/arbiochem_jar`.
- **buildEjbJar** : production de `build-file/ear/arbiochem-ejb.jar` puis copie dans le `WEB-INF/lib` du WAR.
- **compileWar** : compilation de `arbiochem-war/src/java` vers `build-file/arbiochem_war/WEB-INF/classes`.
- **deploy** : déploiement d’un **WAR éclaté** vers `${deploy.dir}/async-standard.war`, déclenché par `.dodeploy` (WildFly/JBoss). Une variante Tomcat existe (`build-tomcat.xml`).

## 4. Structure typique d’un projet APJ

```text
projet/
├── build.xml
├── arbiochem-ejb/
│   └── src/
│       ├── java/  (apj.properties, project.properties, user/, bean métier/, affichage/, utilitaire/)
│       └── ressources/prompts/
├── arbiochem-war/
│   ├── src/java/  (servlets spécialisées)
│   └── web/       (index.jsp, pages/, assets/, WEB-INF/{web.xml, META-INF/apj/web-fragment.xml})
└── build-file/    (lib/, arbiochem_jar/, arbiochem_war/)
```

- **Obligatoires (compilation)** : `build.xml`, sources EJB, libs APJ, `apj.properties`, `project.properties`.
- **Obligatoires (web)** : `index.jsp`, JSP de navigation, `WEB-INF/web.xml`, libs dans `WEB-INF/lib`.
- **Optionnels** : servlets spécialisées, fragments web, rapports Jasper, générateurs de fichiers, classes métier particulières, prompts IA.
- **Générés** : `build-file/*`, `.class`, `dateBuild.txt`, archives JAR.

## 5. Modèle objet APJ

- **`ClassMAPTable`** : abstraction centrale de persistance. Connaît le nom de table, génère une clé primaire, lit par identifiant, construit des requêtes SQL, insère/modifie/supprime, gère l’historisation, recherche avec pagination, charge les champs par réflexion, convertit en JSON.
  - Contrat typique : `setNomTable`, `getTuppleID` (orthographe APJ), `getAttributIDName`, `construirePK`, `controler`.
- **`TypeObjet`** : abstraction intermédiaire utilisée par plusieurs classes (ex. `Pompe` en hérite, pas directement de `ClassMAPTable`).
- **`ClassEtat`** : objets à état de workflow (viser, valider, rejeter, clôturer, modifier l’état).
  - Hiérarchie : `ClassEtat extends ClassUser`, `ClassMere extends ClassEtat`.
- **`ClassMere` / `ClassFille`** : modélisation native maître/détail (`ajouterFille`, `setFille`, `createObjectFille`, `validerObjectFille`, `createObjectMultiple`, `deleteFille`).

Exemple de contrat :

```java
public class Exemple extends ClassMAPTable {
    public Exemple() { setNomTable("EXEMPLE"); }
    @Override public String getTuppleID() { return id; }
    @Override public String getAttributIDName() { return "id"; }
    @Override public void construirePK(Connection c) throws Exception {
        preparePk("EXP", "getSeqExemple");
        setId(makePK(c));
    }
}
```

## 6. Présentation et génération HTML

La présentation repose sur des objets Java APJ utilisés directement dans les JSP :

- `PageRecherche` (recherche/liste), `PageRechercheChoix`, `PageInsert` (saisie),
  `PageConsulte` (consultation), `PageUpdate` (modification) ;
- `Formulaire` (champs), `Liste` (champ lié à un autre objet), `Tableau` (rendu tabulaire).

Le HTML est généré par des objets Java, et non par une séparation contrôleur/template moderne :

```java
pr.getFormu().getHtmlEnsemble()
pr.getTableau().getHtml()
pr.getBasPage()
```

## 7. Routage

Deux routages coexistent :

1. **Routage HTTP standard** — servlets déclarées dans `web-fragment.xml` (ex. `/Deroulante`, `/download`, `/ImportUtilServlet`).
2. **Routage applicatif APJ** — JSP atteintes par le paramètre `?but=...` :

```text
?but=pompe/pompe-liste.jsp
?but=pompe/pompe-fiche.jsp
?but=apresTarif.jsp
```

Le lien courant est stocké en session : `(String) session.getValue("lien")`.
Le mécanisme exact de résolution de `but` n’apparaît pas dans les sources du projet (**déduit**, non prouvé).

## 8. Contrôleurs et services

Pas de contrôleur MVC central visible. La logique est répartie dans les JSP qui instancient les objets APJ, lisent `request`/`session` et délèguent. Les traitements transversaux sont regroupés dans **`user/UserEJB.java`** :

```text
createObject, updateObject, deleteObject, validerObject,
getDataPage, getDataPageMax, testRestriction, finaliser,
createObjectMultiple, updateObjectMultiple, mapperMereFille
```

`UserEJBBean` implémente ce service, mais les annotations EJB principales sont **commentées** (`//@Stateful`, `//@TransactionAttribute(...)`).

## 9. Injection de dépendances

Aucune injection moderne visible (`@Inject`, `@EJB`, `@Named`, `@RequestScoped`). La dépendance est fournie manuellement :

```java
UserEJB u = (user.UserEJB) session.getValue("u");
new PageInsert(pompe, request, u);
new PageConsulte(objet, request, u);
```

Modèle basé sur : injection manuelle par constructeur, session HTTP, interfaces Java, conventions de nommage.

## 10. Accès aux données

Combine JDBC, Oracle, réflexion sur les champs Java, génération de SQL par `ClassMAPTable`, procédures/séquences Oracle, connexions explicitement passées. Configuration dans `apj.properties` :

```properties
apj.connection.url=...
apj.connection.user=...
apj.connection.password=...
apj.debug=true
```

## 11. Conventions imposées

- **Objet persistant** : hériter d’une base APJ, définir `setNomTable`, exposer un identifiant, redéfinir `getTuppleID` et `getAttributIDName`, définir `construirePK`, respecter la correspondance champs Java/colonnes SQL.
- **Clé primaire** : convention APJ/Oracle via `preparePk("PMP", "getSeqPompe"); setId(makePK(c));`.
- **Contrôle** : validation dans `controler`, `controlerUpdate`, `controlerDelete` (hooks de validation).
- **Page de saisie** : protocole standard avec champs cachés `acte`, `bute`, `classe`, `nomtable` (opération, classe à charger, table ciblée, page suivante).

## 12. Gestion des états et autorisations

Workflow concentré dans `UserEJB` : `viserObject`, `validerObject`, `retournerObject`, `recuObject`, `cloturerObject`.
Autorisations via `testRestriction(user, permission, table, con)`. Modèle : `utilisateur -> rôle -> action -> restriction -> table/fonctionnalité`. La logique exacte dépend du jar APJ (non reconstructible sans source).

## 13. Gestion des événements et middleware

Pas de chaîne de middleware visible, pas de contrôleur frontal, pas d’événements découplés. Les « événements » sont des **étapes de cycle de vie des objets** : `controler`, `validerObject`, `changeState`, hooks `createObject`/`payerObject`/`finaliser`, historisation, notifications.

## 14. Exemple complet : fonctionnalité `Pompe`

- **Liste** : `?but=pompe/pompe-liste.jsp` → `Pompe` → `PageRecherche` → `ClassMAPTable`/`UserEJB` → Oracle → `Tableau` → HTML.
- **Saisie** : `?but=pompe/pompe-saisie.jsp` → `UserEJB` (session) → `PageInsert` → formulaire → HTML + champs cachés.
  Soumission : `POST ?but=apresTarif.jsp`, `acte=insert`, `classe=pompe.Pompe`, `nomtable=POMPE`, `bute=pompe/pompe-fiche.jsp`.
  Enchaînement déduit : `construirePK` → `controler` → `insertToTable`.
- **Clé/validation** : `preparePk("PMP","getSeqPompe")` → `makePK(connection)` → `setId(...)` ; `controler` → `ClassMAPTable.controler` → `controllerValMax` → exception si max <= 0.
- **Consultation** : `?but=pompe/pompe-fiche.jsp&id=...` → `PageConsulte` → `pc.getBase()` → objet par identifiant → `pc.getHtml()`.

## 15. Distinction framework / projet / bibliothèques

| Élément | Nature |
|---|---|
| `ClassMAPTable`, `ClassEtat`, `ClassMere`/`ClassFille`, `PageRecherche`, `PageInsert`, `Formulaire`/`Tableau`/`Liste` | Framework APJ compilé |
| `UserEJB` | Contrat projet construit autour d’APJ |
| `UserEJBBean`, `Pompe`, `pompe-liste.jsp` | Code spécifique du projet |
| `?but=...` | Convention APJ/projet |
| `acte`, `classe`, `bute`, `nomtable` | Convention APJ |
| `apj.properties` | Configuration APJ |
| JDBC/Oracle, Servlet API, JasperReports, WildFly/JBoss, Ant, `web.xml`, `web-fragment.xml` | Externe / standard |

## 16. Ce qui est certain, déduit ou inconnu

- **Directement observable** : compilation avec `apj-core.jar` ; héritage des classes APJ ; usage de `PageRecherche`/`PageInsert`/`PageConsulte` ; `setNomTable` ; `preparePk`/`makePK` ; session `u` et `lien` ; CRUD/pagination/états/restrictions dans `UserEJB` ; WAR éclaté ; paramètre `but`.
- **Déduit avec forte confiance** : mapping réflexif champs Java/colonnes SQL ; dispatcher lisant `acte`/`classe`/`nomtable`/`bute` ; `PageRecherche` délègue les recherches ; `controler` = hook de validation ; gestion native de l’historique et des workflows.
- **Inconnu** : implémentation du dispatcher `but` ; ordre exact des appels à l’insertion ; obtention de `UserEJB` au démarrage ; configuration réelle des transactions ; rôle des annotations EJB commentées ; algorithme détaillé des restrictions ; source du noyau APJ.

## 17. Modèle mental du framework

APJ pense l’application comme un ensemble d’objets persistants pilotés par des métadonnées :

```text
Objet Java = représentation d’une table, d’une vue ou d’un processus
```

Construction d’une fonctionnalité :

```text
1. Créer une classe Java APJ.
2. La rattacher à une table ou une vue.
3. Implémenter les méthodes d’identification.
4. Implémenter la génération de clé.
5. Ajouter les contrôles.
6. Créer une JSP (liste, saisie ou fiche).
7. Utiliser les classes Page* APJ.
8. Déclarer les paramètres de navigation attendus.
9. Laisser APJ charger, valider, persister et afficher.
```

Synthèse : APJ est un framework propriétaire de type **ORM procédural + générateur de formulaires JSP + gestionnaire de workflow**, sur Java EE/JDBC, avec forte dépendance aux conventions.

## 18. Complément après décompilation du noyau APJ

Le dossier `decompiled` contient une version décompilée des deux JAR — les conclusions ci-dessous sont plus précises
(noms de variables/commentaires approchés, mais appels, conditions et SQL directement observables).

### 18.1 Répartition des responsabilités

- **`apj-core.jar`** : noyau historique — `bean.*` (mapping, persistance, états, maître/détail), `affichage.*` (pages, formulaires, champs, tableaux, dashboards), `historique.*`, `utilitaire.*`, `chatbot.*`, `constante.*`.
- **`apj-core2.jar`** : extensions applicatives — `web.servlet.*`, `web.importController.*`, `service.*`, `notification.*`, `evenement.*`, `utilisateur.*`, `configuration.*`, `reporting.*`, `menu.*`, `mg.*`, `lc.*`.

Ce n’est **pas** une séparation MVC, mais un noyau générique + extensions de plateforme.

### 18.2 Mapping hybride (réflexion + métadonnées Oracle)

`bean.ListeColonneTable` croise les champs Java (par réflexion) avec les colonnes Oracle :

```sql
SELECT * FROM listeColonneTable
WHERE table_Name = upper(?)
ORDER BY column_id ASC
```

Le framework ne mappe que les champs présents à la fois dans la classe Java et dans `listeColonneTable`.
Mise en cache statique : `listeColPTable`, `listeFieldHeritage`, `listeFieldHeritageClassMAPTable`, `listeMethodHeritage`, `classeEtPackage`.
**Conséquence** : modifier une classe Java ou une table Oracle ne suffit pas, les métadonnées doivent aussi être cohérentes.

### 18.3 Parcours de la hiérarchie

`getFieldListeHeritage` parcourt les champs par réflexion et remonte les superclasses jusqu’à `ClassMAPTable`.
Le mapping dépend du nom de champ, du type, de la classe d’héritage, du nom de colonne et du mode (`select`, `modif`, `groupe`...).

### 18.4 Cycle d’insertion observé

```text
createObject(user, connection)
  -> controler(connection)
  -> notification si messageNotif défini
  -> construire la clé si identifiant vide
  -> insertToTableWithHisto(user, connection)
  -> traiter éventuellement le fichier uploadé
  -> retourner l’objet
```

`controler` est donc un vrai hook d’insertion. Valeurs par défaut : `INDICE_PK = EX`, `nomProcedureSequence = GetSeqExecutions`, `longuerClePrimaire = 6`, `mode = modif`.

### 18.5 Historisation intégrée

L’insertion standard appelle `insertToTableWithHisto` : `MapHistorique` → insertion objet → insertion historique → `HistoInsert` éventuel (si `estIndexable`). L’historique n’est pas un observateur externe, il fait partie de la persistance.

### 18.6 SQL généré et sécurité

Deux stratégies coexistent :

```text
API principale   -> PreparedStatement (paramètres JDBC, typés)
API historique   -> chaînes SQL concaténées (getComandeInsert, getCommandeDelete, updateToTable)
```

Toutes les opérations APJ ne bénéficient donc pas du même niveau de paramétrage JDBC.

### 18.7 Connexions et transactions

`UtilDB` choisit la source :

```text
si apj.datasource défini -> lookup JNDI java:/<datasource> -> DataSource.getConnection()
sinon                    -> driver + DriverManager.getConnection()
                         -> ALTER SESSION SET NLS_DATE_FORMAT = 'dd/mm/yyyy'
```

Transactions gérées manuellement dans `ClassEtat`/`ClassMere` (ouverture, `setAutoCommit(false)`, commit/rollback, fermeture). Le comportement transactionnel n’est pas entièrement délégué aux EJB.

### 18.8 Lecture depuis Oracle

`getById` positionne l’identifiant dans un objet critère, appelle `CGenUtil.rechercher` et retourne le premier résultat. `getInfoFromCursor` mappe par réflexion via `getBoolean`, `getByte`, `getShort`, `getInt`, `getLong`, `getFloat`, `getDouble`, `getString`, `getDate`, `getTimestamp`.

### 18.9 Cycle d’une liste `PageRecherche`

`preparerData` : connexion → lire `numPag` → appliquer `npp` → construire critère et clauses → `UserEJB.getData`/`getDataPage` → charger les données → stocker le critère en session (`"critere"`) → fermer la connexion. Choix full vs paginé selon `colSomme`/`npp`. Les liens de pagination reprennent `but`, `recap`, `premier`, `numPag`, `npp`, `filtres` — confirmant `but` comme protocole transversal.

### 18.10 Cycle d’une page `PageInsert`

Le constructeur lit `acte` : `update` (formulaire de modif, identifiant readonly), `dupliquer` (objet chargé, identifiant vidé), autre → formulaire d’insertion. `makeFormulaire` interroge `ListeColonneTable`, ignore la colonne identifiante en insertion, crée `ChampCalcul`/`ChampDate`/`Champ`. `getObjectAvecValeur` remplit l’objet par réflexion depuis les paramètres HTTP.

### 18.11 Maître/détail

`ClassMere.createObject` insère le parent puis crée les enfants en propageant l’identifiant parent sur le champ de liaison. La validation valide le parent, chaque fille, puis le parent. La relation commande l’ordre de persistance et la clé étrangère.

### 18.12 Workflow `ClassEtat`

Par défaut `etat = 1`, `isHierarchique = false`, `roleValidation = null`. `validerObject` : `controlerUpdate` → notification éventuelle → passage à l’état validé → `actionValidation = "Validation"` → `updateToTableWithHisto`. `viser` consulte `RoleValidation` par le nom complet de la classe et vérifie rôle + valeur d’état + historique des validations précédentes. Workflow séquentiel fondé sur classe Java, rôle, valeur d’état, historique.

### 18.13 Filtre d’encodage (middleware réel)

`EncodingFilter` sur `/*` :

```java
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");
chain.doFilter(request, response);
```

Il s’agit d’une chaîne de filtres Servlet technique, **pas** d’un pipeline MVC métier.

### 18.14 Endpoints natifs APJ

`/Deroulante`, `/autocomplete`, `/download`, `/ImportUtilServlet`, `/upload_excel`, `/kanban/update`, `/kanban/duplique`, `/kanban/remove`, `/ai-evaluation`, `/calendrier-data`, `/calendrier`, `/DeletePj`. Le framework fournit nativement listes déroulantes, autocomplétion, exports, imports, uploads, Kanban, IA, calendriers, suppression de pièces jointes.

### 18.15 Endpoint JSON : calendrier

`CalendrierDataServlet` : `GET /calendrier-data` → vérifier `periode` → `UserEJB` en session (401 sinon) → bornes de dates → `CGenUtil.rechercher(new Evenement(), ...)` → JSON. `POST` → retrouver par identifiant → modifier → `UserEJB.updateObject`. Illustre la coexistence des styles « JSP + Page* + HTML » et « Servlet + CGenUtil/UserEJB + JSON ».

### 18.16 Export

`PageRecherche.preparerData` stocke le critère en session (`session.setAttribute("critere", ...)`) ; `ServletDownload` le réutilise pour produire PDF, CSV, XML ou Excel via `CGenUtil.rechercher` → `TableauRecherche`. La session sert aussi de contexte technique inter-page.

### 18.17 Corrections à l’analyse initiale

- **Middleware** : il existe bien un `EncodingFilter` (technique, non métier).
- **Servlets natives** : plus d’une dizaine (imports, uploads, exports, calendriers, Kanban, IA), pas seulement trois.
- **Transactions** : APJ gère lui-même ouverture, autocommit off, commit, rollback, fermeture.
- **Persistance** : dépend aussi de la table Oracle `listeColonneTable` (colonnes et ordre), pas seulement d’une convention nom/champ.
- **Historique** : appelé directement par `ClassMAPTable` et `ClassEtat`, pas une capacité supposée de `UserEJB`.
- **Injection** : toujours absente du chemin principal, mais `ClassMAPTable` référence `UserEJB`/`UserEJBBean` (lien de service manuel, pas de CDI démontré).

### 18.18 Modèle mental révisé

```text
table Oracle
  + description listeColonneTable
  + classe Java réflexive
  + objet ClassMAPTable
  + Page/Formulaire/Tableau
  + UserEJB
  + historique et état
  + session HTTP
```

Contrats à aligner :

```text
nom des champs Java      = noms des colonnes Oracle
nom de table Java        = entrée de listeColonneTable
getTuppleID              = attribut identifiant réel
construirePK             = préfixe + séquence Oracle
acte/classe/nomtable/bute = protocole HTTP des JSP APJ
ClassEtat                = cycle de validation et historique
ClassMere/ClassFille     = ordre de persistance et liaison des identifiants
```

La philosophie du créateur : centraliser les opérations génériques dans des classes réflexives, décrire les tables dans Oracle, laisser les objets porter leurs propres règles de cycle de vie, et utiliser les JSP comme façades configurables au-dessus de cette mécanique.




