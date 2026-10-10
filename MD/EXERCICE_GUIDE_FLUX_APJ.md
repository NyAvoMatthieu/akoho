# Exercice guidé : comprendre le flux APJ

## Objectif

Créer mentalement puis techniquement une petite page de saisie APJ avec une liste déroulante liée à une autre classe.

L’exercice reprend le fonctionnement de `Pompe`, mais utilise une entité volontairement plus simple : `ProduitSimple`.

```text
page JSP
  -> PageInsert
  -> Formulaire
  -> Liste
  -> request HTTP
  -> objet Java
  -> controler
  -> construirePK
  -> ClassMAPTable
  -> Oracle
  -> historique
```

## Situation

On souhaite saisir un objet `ProduitSimple` avec :

- un identifiant `id` ;
- un nom `nom` ;
- une catégorie sélectionnée dans une liste déroulante.

La catégorie est fournie par la classe APJ existante `annexe.Categorie`.

## Étape 1 : identifier les acteurs

Avant d’écrire du code, compléter le tableau :

| Élément | Réponse attendue |
|---|---|
| Table principale | `PRODUIT_SIMPLE` |
| Classe principale | `produit.ProduitSimple` |
| Champ de liaison | `idCategorie` |
| Classe source de la liste | `annexe.Categorie` |
| Colonne affichée | `val` ou le nom réellement présent dans la classe |
| Colonne stockée | `id` |
| Composant de saisie | `affichage.PageInsert` |
| Composant de liste | `affichage.Liste` |
| Page après traitement | `produit/produit-simple-fiche.jsp` |

## Étape 2 : préparer le modèle Java

Créer une classe qui respecte le contrat APJ :

```java
package produit;

import bean.ClassMAPTable;
import java.sql.Connection;

public class ProduitSimple extends ClassMAPTable {
    private String id;
    private String nom;
    private String idCategorie;

    public ProduitSimple() {
        setNomTable("PRODUIT_SIMPLE");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        preparePk("PRS", "getSeqProduitSimple");
        setId(makePK(c));
    }

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);

        if (nom == null || nom.trim().isEmpty()) {
            throw new Exception("Le nom est obligatoire");
        }

        if (idCategorie == null || idCategorie.trim().isEmpty()) {
            throw new Exception("La catégorie est obligatoire");
        }
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getIdCategorie() { return idCategorie; }
    public void setIdCategorie(String idCategorie) { this.idCategorie = idCategorie; }
}
```

### Questions

1. Pourquoi `getAttributIDName()` retourne-t-il `id` ?
2. Pourquoi `construirePK` utilise-t-il une séquence Oracle ?
3. Que se passe-t-il si `idCategorie` est vide ?
4. Quelle méthode APJ sera appelée avant l’insertion ?

### Réponses attendues

1. APJ doit connaître le nom du champ identifiant pour charger, modifier et supprimer l’objet.
2. APJ utilise une convention de clé composée d’un préfixe et d’une séquence.
3. `controler` lève une exception et l’insertion est interrompue.
4. `controler(Connection)`.

## Étape 3 : construire la page JSP

Créer :

```text
arbiochem-war/web/pages/produit/produit-simple-saisie.jsp
```

Commencer par :

```jsp
<%@page import="produit.ProduitSimple"%>
<%@page import="annexe.Categorie"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>

<%
    UserEJB u = (user.UserEJB) session.getValue("u");

    ProduitSimple produit = new ProduitSimple();
    produit.setNomTable("PRODUIT_SIMPLE");

    PageInsert pi = new PageInsert(produit, request, u);
%>
```

### Questions

1. Pourquoi la page récupère-t-elle `u` dans la session ?
2. Pourquoi passer `request` à `PageInsert` ?
3. Que peut faire `PageInsert` avec le paramètre `acte` ?

### Réponses attendues

1. `UserEJB` fournit le contexte utilisateur et les opérations APJ.
2. `PageInsert` lit les paramètres HTTP pour savoir s’il s’agit d’une insertion, modification ou duplication.
3. Il peut construire un formulaire d’insertion ou charger un objet existant pour une modification/duplication.

## Étape 4 : ajouter la liste déroulante

Ajouter après la création de `PageInsert` :

```jsp
<%
    affichage.Champ[] champsListe = new affichage.Champ[1];

    Categorie categorie = new Categorie();

    champsListe[0] = new Liste(
        "idCategorie",
        categorie,
        "val",
        "id"
    );

    pi.getFormu().changerEnChamp(champsListe);
%>
```

Interprétation :

```text
idCategorie
  -> nom du champ de ProduitSimple

categorie
  -> objet utilisé pour rechercher les options

val
  -> texte visible dans la liste

id
  -> valeur envoyée dans la requête
```

### Question de compréhension

Si l’utilisateur sélectionne :

```text
val = "Boissons"
id  = "CAT001"
```

quelle valeur doit être stockée dans `PRODUIT_SIMPLE.IDCATEGORIE` ?

Réponse :

```text
CAT001
```

Le framework affiche `Boissons`, mais l’objet reçoit `CAT001`.

## Étape 5 : préparer le formulaire

Ajouter :

```jsp
<%
    pi.setLien((String) session.getValue("lien"));

    pi.getFormu().getChamp("nom")
      .setLibelle("Nom du produit");

    pi.getFormu().getChamp("idCategorie")
      .setLibelle("Catégorie");

    pi.preparerDataFormu();
%>
```

À ce moment, le framework va :

```text
PageInsert
  -> Formulaire.getAllData
  -> Liste.findData
  -> CGenUtil.rechercher
  -> recherche des catégories
  -> remplissage des options
```

La recherche de `Liste` est ordonnée par la colonne affichée.

## Étape 6 : générer le formulaire HTML

```jsp
<div class="content-wrapper">
    <h1>Nouveau produit</h1>

    <form action="<%= pi.getLien() %>?but=apresTarif.jsp"
          method="post"
          name="PRODUIT_SIMPLE"
          id="PRODUIT_SIMPLE">

        <%
            pi.getFormu().makeHtmlInsertTabIndex();
            out.println(pi.getFormu().getHtmlInsert());
        %>

        <input type="hidden" name="acte" value="insert">
        <input type="hidden" name="bute" value="produit/produit-simple-fiche.jsp">
        <input type="hidden" name="classe" value="produit.ProduitSimple">
        <input type="hidden" name="nomtable" value="PRODUIT_SIMPLE">
    </form>
</div>
```

## Étape 7 : reconstruire la requête HTTP

Lorsque l’utilisateur valide le formulaire, imaginer une requête de cette forme :

```text
POST /application/?but=apresTarif.jsp

acte=insert
classe=produit.ProduitSimple
nomtable=PRODUIT_SIMPLE
bute=produit/produit-simple-fiche.jsp
nom=Produit test
idCategorie=CAT001
```

### Questions

1. Quelle classe doit être instanciée ?
2. Quelle table doit être utilisée ?
3. Quel champ contient la valeur de la liste ?
4. Quelle page doit être affichée après l’insertion ?

### Réponses

1. `produit.ProduitSimple`.
2. `PRODUIT_SIMPLE`.
3. `idCategorie` contient `CAT001`.
4. `produit/produit-simple-fiche.jsp`.

## Étape 8 : suivre l’exécution interne

Le traitement attendu est :

```text
1. Le serveur reçoit la requête POST.
2. Le mécanisme APJ lit acte=insert.
3. Il lit classe=produit.ProduitSimple.
4. Il instancie la classe par réflexion.
5. Il lit les champs Java de l’objet.
6. Il convertit les paramètres HTTP vers les types Java.
7. Il affecte nom et idCategorie.
8. Il appelle controler(connection).
9. Il appelle construirePK(connection) si id est vide.
10. Il construit l’insertion SQL.
11. Il insère l’objet dans PRODUIT_SIMPLE.
12. Il crée l’entrée d’historique.
13. Il redirige vers bute.
```

Dans le noyau décompilé, le cœur de l’insertion est :

```text
ClassMAPTable.createObject
  -> controler
  -> notification éventuelle
  -> construirePK
  -> insertToTableWithHisto
  -> traitement upload éventuel
```

## Étape 9 : distinguer les responsabilités

| Étape | Responsable |
|---|---|
| Lire les champs Java | APJ, par réflexion |
| Décrire les colonnes SQL | Oracle et `listeColonneTable` |
| Construire le formulaire | `PageInsert` et `Formulaire` |
| Charger les options | `Liste` et `CGenUtil.rechercher` |
| Convertir les paramètres | `PageInsert.getObjectAvecValeur` |
| Valider les données | `ProduitSimple.controler` et APJ |
| Générer la clé | `ProduitSimple.construirePK` et APJ |
| Insérer | `ClassMAPTable` |
| Historiser | `ClassMAPTable` et `MapHistorique` |
| Naviguer après traitement | protocole `bute` / `but` |

## Étape 10 : variantes à tester

### Liste filtrée

```java
new Liste(
    "idCategorie",
    new Categorie(),
    "val",
    "id",
    " AND ACTIF = 1"
);
```

### Valeur par défaut

```java
pi.getFormu()
  .getChamp("idCategorie")
  .setDefaut("CAT001");
```

### Liste statique

```java
String[] textes = { "Actif", "Inactif" };
String[] valeurs = { "1", "0" };

Liste statut = new Liste("statut", textes, valeurs);
```

### Mode modification

Tester avec :

```text
acte=update
id=PRS000001
```

Dans ce mode, `PageInsert` :

```text
-> crée un critère
-> charge l’objet
-> construit un formulaire de modification
-> rend l’identifiant non modifiable
```

## Exercice final sans regarder la solution

Répondre aux questions suivantes :

1. Quelle classe faut-il importer pour une liste déroulante APJ ?
2. Quel argument de `Liste` correspond au nom du champ stocké ?
3. Quel argument correspond au texte affiché ?
4. Quelle méthode charge les options avant le rendu ?
5. Quel paramètre HTTP indique l’insertion ?
6. Quelle méthode valide l’objet ?
7. Quelle méthode génère sa clé ?
8. Quelle classe effectue la persistance générique ?
9. Où sont conservées les métadonnées de colonnes ?
10. Que devient la valeur sélectionnée par l’utilisateur ?

### Solution

1. `affichage.Liste`.
2. Le premier argument, par exemple `idCategorie`.
3. L’argument `colAffiche`, par exemple `val`.
4. `pi.preparerDataFormu()`.
5. `acte=insert`.
6. `controler(Connection)`.
7. `construirePK(Connection)`.
8. `ClassMAPTable`.
9. Dans la table Oracle `listeColonneTable`.
10. Elle est envoyée comme paramètre HTTP puis affectée au champ Java correspondant, par exemple `idCategorie=CAT001`.

## Résumé du flux

```text
JSP de saisie
  -> PageInsert
  -> Formulaire
  -> Liste
  -> recherche des options
  -> HTML

soumission
  -> acte/classe/nomtable/bute
  -> objet Java APJ
  -> conversion des champs
  -> controler
  -> construirePK
  -> insertToTableWithHisto
  -> page de destination
```

La règle à retenir :

```text
La liste affiche un libellé,
mais elle transmet l’identifiant.
```
