# ProduitSimple : page de saisie et page de liste

Ce guide reprend l’exemple `ProduitSimple` et ajoute une page de liste des produits simples.

Le parcours complet est :

```text
page de liste
  -> page de saisie
  -> liste déroulante des catégories
  -> soumission du formulaire
  -> apresTarif.jsp
  -> ProduitSimple
  -> validation
  -> génération de l’identifiant
  -> insertion Oracle + historique
  -> fiche de consultation
```

## 1. Structure attendue

```text
arbiochem-ejb/src/java/produit/ProduitSimple.java
arbiochem-war/web/pages/produit/produit-simple-liste.jsp
arbiochem-war/web/pages/produit/produit-simple-saisie.jsp
arbiochem-war/web/pages/produit/produit-simple-fiche.jsp
```

Les trois JSP ont des responsabilités différentes :

| Page | Responsabilité |
|---|---|
| `produit-simple-liste.jsp` | rechercher et afficher les produits |
| `produit-simple-saisie.jsp` | créer un produit |
| `produit-simple-fiche.jsp` | consulter un produit enregistré |

## 2. Table Oracle

```sql
CREATE TABLE PRODUIT_SIMPLE (
    ID VARCHAR2(20) PRIMARY KEY,
    NOM VARCHAR2(255),
    IDCATEGORIE VARCHAR2(20)
);
```

La table doit être connue par le métamodèle APJ `LISTECOLONNETABLE`.

La fonction utilisée par `construirePK` doit également exister :

```sql
CREATE OR REPLACE FUNCTION getSeqProduitSimple RETURN NUMBER IS
    v_next NUMBER;
BEGIN
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(ID, 4))), 0) + 1
    INTO v_next
    FROM PRODUIT_SIMPLE;

    RETURN v_next;
END;
/
```

Dans un environnement de développement, vérifier :

```sql
SELECT COUNT(*)
FROM LISTECOLONNETABLE
WHERE TABLE_NAME = 'PRODUIT_SIMPLE';

SELECT getSeqProduitSimple FROM dual;
```

Le premier résultat doit être supérieur à zéro et le second doit retourner le prochain numéro d’identifiant.

## 3. Classe Java `ProduitSimple`

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

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getIdCategorie() {
        return idCategorie;
    }

    public void setIdCategorie(String idCategorie) {
        this.idCategorie = idCategorie;
    }
}
```

Les conventions APJ importantes sont :

- le nom Java `idCategorie` correspond à `IDCATEGORIE` ;
- `getTuppleID()` retourne l’identifiant ;
- `getAttributIDName()` retourne le nom du champ identifiant ;
- `construirePK` utilise le préfixe `PRS` et la fonction Oracle ;
- `controler` est appelé avant l’insertion.

## 4. Page de saisie

Fichier :

```text
arbiochem-war/web/pages/produit/produit-simple-saisie.jsp
```

### Imports

```jsp
<%@page import="produit.ProduitSimple"%>
<%@page import="annexe.Categorie"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Champ"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>
```

### Création du contexte APJ

```jsp
<%
    UserEJB u = (user.UserEJB) session.getValue("u");

    String mapping = "produit.ProduitSimple";
    String nomtable = "PRODUIT_SIMPLE";
    String apres = "produit/produit-simple-fiche.jsp";

    ProduitSimple produit = new ProduitSimple();
    produit.setNomTable(nomtable);

    PageInsert pi = new PageInsert(produit, request, u);
%>
```

`PageInsert` construit automatiquement les champs correspondant aux colonnes reconnues par APJ.

### Remplacement du champ par une liste déroulante

```jsp
<%
    Champ[] champsListe = new Champ[1];
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

Signification des arguments :

```text
idCategorie
  -> champ de ProduitSimple

categorie
  -> classe APJ qui fournit les options

val
  -> colonne affichée à l’utilisateur

id
  -> valeur réellement stockée dans IDCATEGORIE
```

Exemple :

```text
Libellé affiché : Boissons
Valeur envoyée : CAT001
```

La base recevra :

```text
IDCATEGORIE = CAT001
```

### Préparation et rendu

```jsp
<%
    pi.setLien((String) session.getValue("lien"));

    pi.getFormu().getChamp("nom")
      .setLibelle("Nom du produit");

    pi.getFormu().getChamp("idCategorie")
      .setLibelle("Catégorie");

    pi.preparerDataFormu();
%>

<div class="content-wrapper">
    <h1>Nouveau produit simple</h1>

    <form action="<%= pi.getLien() %>?but=apresTarif.jsp"
          method="post"
          name="PRODUIT_SIMPLE"
          id="PRODUIT_SIMPLE">

        <%
            pi.getFormu().makeHtmlInsertTabIndex();
            out.println(pi.getFormu().getHtmlInsert());
        %>

        <input type="hidden" name="acte" value="insert">
        <input type="hidden" name="bute" value="<%= apres %>">
        <input type="hidden" name="classe" value="<%= mapping %>">
        <input type="hidden" name="nomtable" value="<%= nomtable %>">
    </form>
</div>
```

## 5. Flux de la saisie

La requête envoyée par le formulaire ressemble à :

```text
POST /async-standard/pages/apresTarif.jsp

acte=insert
classe=produit.ProduitSimple
nomtable=PRODUIT_SIMPLE
bute=produit/produit-simple-fiche.jsp
nom=Produit test
idCategorie=CAT001
```

Le traitement APJ est :

```text
apresTarif.jsp
  -> lecture de acte=insert
  -> instanciation de produit.ProduitSimple
  -> lecture des paramètres HTTP
  -> affectation de nom et idCategorie
  -> ProduitSimple.controler(connection)
  -> ProduitSimple.construirePK(connection)
  -> ClassMAPTable.insertToTableWithHisto
  -> redirection vers bute
```

L’identifiant généré est de la forme :

```text
PRS000001
```

## 6. Page de liste

Fichier :

```text
arbiochem-war/web/pages/produit/produit-simple-liste.jsp
```

### Imports

```jsp
<%@page import="produit.ProduitSimple"%>
<%@page import="affichage.PageRecherche"%>
```

### Création de la recherche

```jsp
<%
    try {
        ProduitSimple critere = new ProduitSimple();
        critere.setNomTable("PRODUIT_SIMPLE");

        String[] listeCrt = {"id", "nom", "idCategorie"};
        String[] listeInt = {};
        String[] libEntete = {"id", "nom", "idCategorie"};

        PageRecherche pr = new PageRecherche(
            critere,
            request,
            listeCrt,
            listeInt,
            3,
            libEntete,
            libEntete.length
        );

        pr.setTitre("Liste des produits simples");
        pr.setUtilisateur((user.UserEJB) session.getValue("u"));
        pr.setLien((String) session.getValue("lien"));
        pr.setApres("produit/produit-simple-liste.jsp");
%>
```

Les tableaux ont les rôles suivants :

| Tableau | Rôle |
|---|---|
| `listeCrt` | champs proposés comme critères de recherche |
| `listeInt` | champs traités comme intervalles |
| `libEntete` | colonnes utilisées dans le résultat |

### Libellés des critères

```jsp
<%
        pr.getFormu().getChamp("id")
          .setLibelle("Identifiant");

        pr.getFormu().getChamp("nom")
          .setLibelle("Nom");

        pr.getFormu().getChamp("idCategorie")
          .setLibelle("Catégorie");
%>
```

### Préparation des données et liens

```jsp
<%
        String[] colSomme = null;
        pr.creerObjetPage(libEntete, colSomme);

        String[] lienTableau = {
            pr.getLien() + "?but=produit/produit-simple-fiche.jsp"
        };

        String[] colonneLien = {"id"};

        pr.getTableau().setLien(lienTableau);
        pr.getTableau().setColonneLien(colonneLien);

        String[] libEnteteAffiche = {
            "Identifiant",
            "Nom",
            "Catégorie"
        };

        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>
```

La ligne devient alors un lien vers :

```text
module.jsp?but=produit/produit-simple-fiche.jsp&id=PRS000001
```

### Rendu HTML de la liste

```jsp
<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
    </section>

    <section class="content">
        <form action="<%= pr.getLien() %>?but=<%= pr.getApres() %>"
              method="post">
            <%= pr.getFormu().getHtmlEnsemble() %>
        </form>

        <%= pr.getTableauRecap().getHtml() %>
        <br>
        <%= pr.getTableau().getHtml() %>
        <%= pr.getBasPage() %>
    </section>
</div>

<%
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
```

## 7. Fonctionnement interne de `PageRecherche`

La page de liste suit ce flux :

```text
PageRecherche
  -> lecture de numPag et des filtres
  -> construction d’un objet critère
  -> lecture des métadonnées de PRODUIT_SIMPLE
  -> UserEJB.getData ou UserEJB.getDataPage
  -> CGenUtil.rechercher
  -> ResultatEtSomme
  -> TableauRecherche
  -> HTML
```

Si la pagination est active :

```text
PageRecherche
  -> UserEJB.getDataPage
  -> numPag
  -> npp
  -> ResultatEtSomme
```

Les liens de pagination conservent notamment :

```text
but
numPag
npp
recap
filtres
```

## 8. Lien entre la liste et la saisie

Ajouter un lien de création au-dessus de la liste :

```jsp
<a href="<%= pr.getLien() %>?but=produit/produit-simple-saisie.jsp"
   class="btn btn-primary">
    Nouveau produit
</a>
```

Le parcours utilisateur devient :

```text
produit-simple-liste.jsp
  -> clic sur Nouveau produit
  -> produit-simple-saisie.jsp
  -> sélection de la catégorie
  -> enregistrement
  -> produit-simple-fiche.jsp
```

## 9. Accès direct aux pages

Page de liste :

```text
http://localhost:8089/async-standard/pages/module.jsp?but=produit/produit-simple-liste.jsp
```

Page de saisie :

```text
http://localhost:8089/async-standard/pages/module.jsp?but=produit/produit-simple-saisie.jsp
```

Page de fiche :

```text
http://localhost:8089/async-standard/pages/module.jsp?but=produit/produit-simple-fiche.jsp&id=PRS000001
```

La session utilisateur doit être ouverte. `module.jsp` vérifie la présence de `u` dans la session avant d’inclure la JSP demandée par `but`.

## 10. Ajouter la page au menu

La barre de navigation utilise `MenuDynamique` et les tables `MENUDYNAMIQUE` et `USERMENU`.

Le `href` de l’entrée de menu doit pointer vers la liste :

```text
module.jsp?but=produit/produit-simple-liste.jsp
```

Le menu doit ensuite être autorisé dans `USERMENU` pour le rôle concerné.

Après une modification des menus, il peut être nécessaire de :

- se déconnecter et se reconnecter ;
- supprimer la session ;
- redémarrer ou redéployer l’application.

## 11. Vérifications avant test

### Java

```text
getTuppleID()                 -> id
getAttributIDName()           -> id
getIdCategorie()              -> idCategorie
setIdCategorie(...)           -> idCategorie
construirePK(...)             -> getSeqProduitSimple
```

### Oracle

```text
PRODUIT_SIMPLE existe
LISTECOLONNETABLE décrit ID, NOM, IDCATEGORIE
GETSEQPRODUITSIMPLE est valide
```

### JSP

```text
PageInsert importé avec la bonne casse
PageRecherche importé
changerEnChamp appelé pour idCategorie
preparerDataFormu appelé
makeHtmlInsertTabIndex appelé
```

### Navigation

```text
la liste pointe vers la saisie
la liste pointe vers la fiche
la saisie utilise apresTarif.jsp
bute pointe vers la fiche existante
```

## 12. Résumé du flux complet

```text
GET module.jsp?but=produit/produit-simple-liste.jsp
  -> module.jsp inclut la JSP de liste
  -> PageRecherche prépare le critère
  -> UserEJB récupère les produits
  -> TableauRecherche génère les lignes

clic sur Nouveau produit
  -> module.jsp?but=produit/produit-simple-saisie.jsp
  -> PageInsert construit le formulaire
  -> Liste charge les catégories

POST apresTarif.jsp
  -> ProduitSimple est instancié
  -> les paramètres sont convertis
  -> controler est exécuté
  -> getSeqProduitSimple génère l’id
  -> ClassMAPTable insère et historise
  -> redirection vers la fiche

GET produit-simple-fiche.jsp?id=...
  -> PageConsulte recharge le produit
  -> HTML de consultation généré
```

La distinction fondamentale reste :

```text
PageInsert     = créer ou modifier un objet
PageRecherche  = rechercher et afficher plusieurs objets
PageConsulte   = afficher un objet identifié
Liste          = transformer un champ en sélection APJ
```
