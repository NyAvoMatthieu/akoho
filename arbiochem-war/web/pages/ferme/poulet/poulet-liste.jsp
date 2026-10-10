<%-- <%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %> --%>
<%@ page import="affichage.PageRecherche"%>
<%@ page import="ferme.poulet.Poulet" %>

<% try{
    Poulet o = new Poulet();
    o.setNomTable("POULET");
    String[] listeCrt = {"id", "nom", "race"};
    String[] listeInt = {};
    String[] libEntete = {"id", "nom", "race"};
    PageRecherche pr = new PageRecherche(o, request, listeCrt, listeInt, 4, libEntete, libEntete.length);
    pr.setTitre("Liste des poulets");
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));
    pr.setApres("ferme/poulet/poulet-liste.jsp");
    pr.getFormu().getChamp("id").setLibelle("Id");
    pr.getFormu().getChamp("nom").setLibelle("Nom");
    pr.getFormu().getChamp("race").setLibelle("Race");

    String[] colSomme = null;
    pr.creerObjetPage(libEntete, colSomme);

    String[] lienTableau = {pr.getLien() + "?but=ferme/poulet/poulet-fiche.jsp"};
    String[] colonneLien = {"id"};
    String[] attributLien = {"id"};
    pr.getTableau().setLien(lienTableau);
    pr.getTableau().setColonneLien(colonneLien);
    pr.getTableau().setAttLien(attributLien);

    pr.getFormu().setAnotherButton("" +
        "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=ferme/poulet/poulet-saisie.jsp\">\n" +
        "                    <i class=\"material-symbols-rounded\">add</i> Saisir un poulet</a>"
    );

    String[] libEnteteAffiche = {"Id", "Nom", "Race"};
    pr.getTableau().setLibelleAffiche(libEnteteAffiche);
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