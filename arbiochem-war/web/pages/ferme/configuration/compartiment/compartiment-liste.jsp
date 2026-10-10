<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageRecherche"%>
<%@ page import="ferme.configuration.Compartiment" %>

<% try{
    Compartiment o = new Compartiment();
    o.setNomTable("COMPARTIMENT");
    String[] listeCrt = {"id", "nom"};
    String[] listeInt = {};
    String[] libEntete = {"id", "nom", "capacite", "idPoulailler"};
    PageRecherche pr = new PageRecherche(o, request, listeCrt, listeInt, 4, libEntete, libEntete.length);
    pr.setTitre("Liste des compartiments");
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));
    pr.setApres("ferme/configuration/compartiment/compartiment-liste.jsp");
    pr.getFormu().getChamp("id").setLibelle("Id");
    pr.getFormu().getChamp("nom").setLibelle("Nom");

    String[] colSomme = {"capacite"};
    pr.creerObjetPage(libEntete, colSomme);

    String[] lienTableau = {pr.getLien() + "?but=ferme/configuration/compartiment/compartiment-fiche.jsp"};
    String[] colonneLien = {"id"};
    String[] attributLien = {"id"};
    pr.getTableau().setLien(lienTableau);
    pr.getTableau().setColonneLien(colonneLien);
    pr.getTableau().setAttLien(attributLien);

    pr.getFormu().setAnotherButton("" +
        "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=ferme/configuration/compartiment/compartiment-saisie.jsp\">\n" +
        "                    <i class=\"material-symbols-rounded\">add</i> Saisir un compartiment</a>"
    );

    String[] libEnteteAffiche = {"Id", "Nom", "Capacit&eacute;", "Poulailler"};
    pr.getTableau().setLibelleAffiche(libEnteteAffiche);
    pr.getTableau().setLibelleAfficheRecap(new String[]{"", "", "Somme des capacit&eacute;s"});
%>

<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
    </section>
    <section class="content">
        <form action="<%=pr.getLien()%>?but=<%= pr.getApres() %>" method="post">
            <%
                out.println(pr.getFormu().getHtmlEnsemble());
            %>
        </form>
        <%
            out.println(pr.getTableauRecap().getHtml());
        %>
        <br>
        <%
            out.println(pr.getTableau().getHtml());
            out.println(pr.getBasPage());
        %>
    </section>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>