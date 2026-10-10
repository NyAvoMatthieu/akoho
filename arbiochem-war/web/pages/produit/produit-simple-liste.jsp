<%@ page import="produit.ProduitSimple" %>
<%@ page import="affichage.PageRecherche" %>

<%
    // Creaton de la recherche
    try{
        ProduitSimple critere = new ProduitSimple();
        critere.setNomTable("PRODUIT_SIMPLE");

        String[] listeCrt = {"id","nom","idCategorie"};
        String[] listeInt = {};
        String[] libEntete = {"id","nom","idCategorie"};

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
<%
// Libelles criteres
        pr.getFormu().getChamp("id")
        .setLibelle("Identifiant");

        pr.getFormu().getChamp("nom")
        .setLibelle("Nom");

        pr.getFormu().getChamp("idCategorie")
        .setLibelle("Categorie");

%>
<%
    // Prepa donnees et liens
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
            "Categorie"
        };

        pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>
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
    }catch (Exception e) {
        e.printStackTrace();
    }
%>
