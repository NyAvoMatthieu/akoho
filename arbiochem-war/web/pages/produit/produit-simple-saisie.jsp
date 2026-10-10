<%@ page import="produit.ProduitSimple" %>
<%@ page import="annexe.Categorie" %>
<%@ page import="affichage.PageInsert" %>
<%@ page import="affichage.Champ" %>
<%@ page import="affichage.Liste" %>
<%@ page import="user.UserEJB" %>

<% 

    // 
    UserEJB u = (user.UserEJB) session.getValue("u");

    ProduitSimple produit = new ProduitSimple();
    produit.setNomTable("PRODUIT_SIMPLE");

    PageInsert pi = new PageInsert(produit, request, u);

    // Ajout liste deroulante
    Champ[] champsListe = new Champ[2];
    Categorie categorie = new Categorie();

    champsListe[0] = new Liste (
        "idCategorie",
        categorie,
        "val",
        "id"
    );

    String[] affichage = { "Actif", "Inactif" };
    String[] valeurs = { "1", "0" };

    champsListe[1] =  new Liste("etat", affichage, valeurs);
    // Liste listeEtat = new Liste("etat", affichage, valeurs);
    pi.getFormu().changerEnChamp(champsListe);
    
    // pi.getFormu().changerEnChamp(
    //     new affichage.Champ[] { listeEtat }
    // );

    // Preparation formulaire
    pi.setLien((String)session.getValue("lien"));
    pi.getFormu().getChamp("nom").setLibelle("Nom du produit");
    pi.getFormu().getChamp("idCategorie").setLibelle("Categorie");
    pi.getFormu().getChamp("etat").setLibelle("Etat");
    pi.preparerDataFormu();

%>

<div class="content-wrapper">
    <h1>Nouveau produit</h1>

    <form action="<%=pi.getLien()%>?but=apresTarif.jsp"
        method="post"
        name="PRODUIT_SIMPLE"
        id="PRODUIT_SIMPLE"
    >

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
